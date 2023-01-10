cat <<EOF > /etc/consul.d/consul.hcl
data_dir = "/opt/consul"
ui_config {enabled = true}
connect {enabled = true}
ports {grpc = 8502}
server = true
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
bootstrap_expect=1
retry_join = ["10.0.0.5"]
enable_central_service_config = true
EOF

service consul restart
systemctl enable consul

#apt install docker.io
#docker run --network host prom/prometheus
ip link delete docker0