upstream webapp {
  {{range service "web-server-web-stack-runWebAppInstance"}}server {{.Address}}:{{.Port}} max_fails=3 fail_timeout=60 weight=1;
  {{else}}server 127.0.0.1:65535;{{end}}
}

upstream goapi {
  {{range service "go-api-stats-expose"}}{{ if (ne .Port 0) }}server {{.Address}}:{{.Port}} max_fails=3 fail_timeout=60 weight=1;
  {{end}}{{else}}server 127.0.0.1:65535;{{end}}
}

server {
  listen 80 default_server;
  server_name localhost;

  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://webapp;
  }

  location /api {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    rewrite ^/api/?(.*) /$1 break;
    proxy_pass http://goapi;
    proxy_redirect off;
  }
}
