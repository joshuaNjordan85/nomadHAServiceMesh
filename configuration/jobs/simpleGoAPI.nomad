job "go-api" {
  datacenters = ["dc1"]
  type = "service"
  group "stats" {
    count = 30
    task "expose" {
      service {
        tags = ["api", "golang", "non-containerized"]
      }
      driver = "exec"
      template {
        data = "{ \"region\": \"{{ env \"NOMAD_REGION\" }}\", \"dc\": \"{{ env \"NOMAD_DC\" }}\", \"node\": \"{{ env \"node.unique.name\" }}\", \"addy\": \"{{ env \"attr.unique.network.ip-address\" }}\", \"port\": \"{{ env \"NOMAD_PORT_http\" }}\", \"cores\": \"{{ env \"attr.cpu.numcores\" }}\", \"compute\": \"{{ env \"attr.cpu.totalcompute\" }}\" }"
        destination = "goStats/stats.json"
      }
      resources {
        cpu = 20
        memory = 20
        network {
          port "http" {}
        }
      }

      service {
        tags = ["api", "golang", "simple-demo"]

        port = "http"

        check {
          type = "http"
          port = "http"
          path = "/"
          interval = "5s"
          timeout = "2s"
        }
      }

      env {
        PORT = "${NOMAD_PORT_http}"
      }

      config {
        command = "/bin/simpleApiForNomadDemo"
        args = [
          "PORT=$PORT"
        ]
      }
    }
  }
}
