! grep swap /etc/fstab && dd if=/dev/zero of=/swap.bin bs=1M count=1024 && mkswap /swap.bin && echo "/swap.bin none swap defaults 0 0" >> /etc/fstab && swapon -a

apt update
apt -y install dnsmasq net-tools jq

cat <<EOF > /etc/dnsmasq.d/10-consul
server=/consul/127.0.0.1#8600
server=168.63.129.16
EOF

systemctl stop systemd-resolved
systemctl disable systemd-resolved
rm /etc/resolv.conf

service dnsmasq restart
systemctl enable dnsmasq

curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

apt update
apt -y install consul

cat <<EOF > /etc/consul.d/consul.hcl
data_dir = "/opt/consul"
server = false
bind_addr = "0.0.0.0"
client_addr = "0.0.0.0"
retry_join = ["10.0.0.5"]
ports {grpc = 8502}
EOF

service consul restart
systemctl enable consul