apt -y install nginx php-fpm mariadb-client
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default

cat <<EOF > /etc/nginx/sites-enabled/test
server {
        listen 80 default_server;
        server_name _;
        root /var/www/html;
        index index.php index.html index.htm index.nginx-debian.html;

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        }
}
EOF

systemctl restart nginx php7.4-fpm
systemctl enable nginx php7.4-fpm

cat <<EOF > /etc/consul.d/frontend.json
{
"service": {
        "name": "frontend",
        "port": 80,
        "checks": [{"http": "http://localhost:80", "interval": "5s"}],
        "tags": ["http","frontend","fe_team"],
        "connect": {"sidecar_service": {
                "proxy": {
                        "upstreams": [{
                         "destination_name":"backend",
                         "local_bind_port":5000
                        }]
                }
        }
        }
}
}
EOF

service consul restart
systemctl enable consul

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

cat <<EOF > /etc/consul-template.d/frontend
template {
  source = "/var/www/index.php.template"
  destination = "/var/www/html/index.php"
}
EOF

cat <<EOF > /var/www/index.php.template
<?php
echo gethostname();
echo '<br>EXPERIMENTAL_API: {{ key "/frontend/experimental_api" }}<br>';
echo 'BONUS_SETS: {{ key "/frontend/bonus_sets" }}';
?>
EOF

systemctl restart consul-template
systemctl enable  consul-template 

cp /home/ubuntu/envoy-1.24 /usr/bin/envoy
consul connect envoy -sidecar-for frontend &

###TESTS
mysql --host 127.0.0.1 --user mysql --port 5000 -e "show variables where variable_name = 'wsrep_node_name'"