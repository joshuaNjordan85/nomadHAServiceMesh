[Unit]
Description="HashiCorp Nomad - An application and service scheduler"
Documentation=https://www.nomad.io/docs/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/home/${userName}/nomad.d/${hclPath}.hcl

[Service]
User=${userName}
ExecStart=/bin/nomad agent -config=/home/${userName}/nomad.d/
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
