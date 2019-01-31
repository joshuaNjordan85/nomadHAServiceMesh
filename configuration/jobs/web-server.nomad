job "web-server" {
    datacenters = ["dc1"]
    type = "service"
    group "web-stack" {
      count = 81
      task "runWebAppInstance" {
        template {
          data = <<EOH
          <!DOCTYPE HTML>
          <html lang="en">
            <head>
              <title>Nomad Demo</title>
              <meta charset="utf-8">
              <meta http-equiv="X-UA-Compatible" content="IE=edge">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.7.2/css/bulma.min.css">
              <style>
              .logo {
                padding: 20px;
                border: solid 1px darkgray;
              }

              .buttons.are-medium {
                  margin-top: 12px;
              }

              .for-styling {
                margin-top: 12px;
              }

              pre {
                  white-space: pre-wrap;
                  margin-left: 4px;
              }

              body {
                  color: white;
                  background-color: black;
                  position: absolute;
                  top: 0;
                  bottom: 0;
                  left: 0;
                  right: 0;
              }
              </style>
            </head>
            <body>
              <section>
                <nav class="level">
                  <div class="level-left">
                    <div class="level-item">
                      <div class="logo">
                        {{ env "NOMAD_REGION" }}: {{ env "NOMAD_DC" }}
                      </div>
                    </div>
                    <div class="level-item">
                     <p class="subtitle">Node:<span>{{ env "node.unique.name" }}</span></p>
                    </div>
                    <div class="level-item">
                      <p class="subtitle">Footprint - <span>Cores: {{ env "attr.cpu.numcores" }}</span><span> Compute: {{ env "attr.cpu.totalcompute" }}</span></p>
                    </div>
                    <div class="level-item">
                     <p class="subtitle">Network IP:<span>{{ env "attr.unique.network.ip-address" }}:{{ env "NOMAD_PORT_http" }}</span></p>
                    </div>
                  </div>
                </nav>
                <div class="section" name="splash">
                  <div class="hero is-medium is-danger is-warning">
                    <div class="hero-body">
                      <div class="container">
                        <h1 class="title">Welcome to the Hybrid App DEMO</h1>
                        <h2 class="subtitle">HA, Placement, & Bin-Packing</h2>
                      </div>
                      <div class="container">
                        <div class="buttons are-medium">
                          <button onclick="getGoApiStuff()" class="button is-dark is-outlined">GET GO API STUFF</button>
                        </div>
                      </div>
                      <div class="container">
                          <div class="level">
                             <div id="go-metrics" class="level-left for-styling"></div>
                          </div>
                      </div>
                    </div>
                  </div>
                  <div class="section all"></div>
              </section>
              <script>
              function getGoApiStuff(event) {
                  fetch(window.location.href + "api")
                    .then(d => d.json())
                    .then(j => document.getElementById("go-metrics").innerHTML = `<div class="level-item">
                      <p class="title">Metrics</p>
                      <pre><code>${JSON.stringify(j)}</code></pre>
                    </div>`)
                    .catch(console.log);
              }
              </script>
            </body>
          </html>
          EOH

          destination = "html/index.html"
        }

        driver = "docker"

        config {
          image = "nginx:1.14.2-alpine"

          volumes = [
            "html:/usr/share/nginx/html"
          ]

          port_map = {
            http = 80
          }
        }

        resources {
          cpu = 20
          memory = 10
          network {
            port "http" {}
          }
        }

        service {
          tags = ["webapp", "nginx", "containerized"]

          port = "http"

          check {
            port = "http"
            type = "tcp"
            interval = "10s"
            timeout = "2s"
          }
        }
      }
    }
  }
