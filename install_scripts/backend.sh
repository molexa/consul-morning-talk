apt -y install mariadb-server
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb
systemctl enable mariadb

cat <<EOF > /etc/consul.d/backend.json
{
"service": {
        "name": "backend",
        "port": 3306,
        "checks": [{"tcp": "localhost:3306", "interval": "5s"}],
        "tags": ["mysql","backend"]
}
}
EOF

systemctl restart consul
systemctl enable consul
