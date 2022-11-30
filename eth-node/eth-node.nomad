job "eth-node" {
  datacenters = ["dc1"]
  type        = "service"

  group "eth-node" {
    count = 1

    task "eth-node" {
      driver = "docker"

      env {
        chain   = "goerli"
        datadir = "/root/.local/share/erigon"
      }

      config {
        image      = "thorax/erigon:latest"
        force_pull = true
        volumes = [
          "local/erigon:/root/.local/share/erigon",
        ]
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}