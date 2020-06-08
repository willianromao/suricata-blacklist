[Unit]
Description=Suricata IPS
Requires=network.target
After=network.target

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=/bin/suricata.sh start
ExecStop=/bin/suricata.sh stop

[Install]
WantedBy=multi-user.target

# mv /etc/init.d/suricata /bin/suricata.sh
# vi /etc/systemd/system/suricata.service
# chmod 755 /etc/systemd/system/suricata.service
# systemctl enable suricata.service
# service suricata start
# systemctl is-active suricata.service