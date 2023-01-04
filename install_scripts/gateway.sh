apt -y install haproxy

apt -y install consul-template
mkdir /etc/consul-template.d/

cat <<EOF > /etc/systemd/system/consul-template.service
[Unit]
Description=consul-template
Requires=network-online.target
After=network-online.target

[Service]
User=root
Group=root
ExecStart=/usr/bin/consul-template -config=/etc/consul-template.d/
Restart=on-failure

KillSignal=SIGINT
ExecReload=/bin/kill -HUP $MAINPID

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

cat <<EOF > /etc/consul-template.d/haproxy
template {
  source = "/etc/haproxy/haproxy.cfg.template"
  destination = "/etc/haproxy/haproxy.cfg"
  command = "service haproxy reload"
  wait = "5s:10s"
}
EOF

cat <<EOF > /etc/haproxy/haproxy.cfg.template
{{\$groupedServices := services | byTag}}
{{\$pub := \$groupedServices.http}}
global

  user    root
  group   root
  daemon

defaults
  mode    http

frontend external_services
  bind *:80
  use_backend external_services_cluster

backend external_services_cluster
{{- range \$pub}}
{{- range service .Name}}
{{- if .Name|contains "frontend"}}
 server {{.Node}}-{{.Address}} {{.Address}}:{{.Port}}
{{- end}}
{{- end}}
{{- end}}
EOF


systemctl restart consul-template
systemctl enable  consul-template 
