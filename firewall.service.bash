[Unit]
Description=Firewall Script
Requires=network.target
After=network.target

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=/bin/firewall start
ExecStop=/bin/firewall stop

[Install]
WantedBy=multi-user.target

# vi /etc/systemd/system/firewall.service
# chmod 755 /etc/systemd/system/firewall.service
# systemctl enable firewall.service
# service firewall start
# systemctl list-unit-files | grep portal
# systemctl is-active firewall.service