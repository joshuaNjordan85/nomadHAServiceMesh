[Unit]
Description=Consul server agent
Requires=network-online.target
After=network-online.target

[Service]
ExecStart=/bin/consul agent \
    -config-file=/home/${userName}/consul.d/server.json
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
