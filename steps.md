# Setup
## Initial (Manual)
- Create VM on AWS (Ubuntu 20.04)
- Install Docker
- Change hostname to `eth-node-1`
```bash
sudo hostnamectl set-hostname eth-node-1
```
### Nomad Installation
- Install Nomad
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install nomad
```
- Start Nomad agent in dev mode
```bash
sudo nomad agent -dev -bind 0.0.0.0 -log-level INFO
```
- Check Nomad agent status, if Nomad is running, and runing jobs
```bash
nomad node status
nomad server members
nomad status
```

### Deploy an ethereum node as a container into a Nomad cluster and run it on a testnet (Goerli), using thorax/erigon and the ledger should survive a restart of the node and be placed on a mounted drive.
- Create a job file `eth-node.nomad`
```bash
job "eth-node" {
  datacenters = ["dc1"]
  type = "service"

  group "eth-node" {
    count = 1

    task "eth-node" {
      driver = "docker"

      config {
        image = "thorax/erigon:stable"
        volumes = [
          "local/erigon:/root/.local/share/erigon",
        ]
        args = [
          "--chain","goerli",
        #   "--private.api.addr=0.0.0.0:9090",
            # "--http.addr=0.0.0.0",
            # "--http.vhosts=*",
            # "--http.corsdomain=*",
            # "--http.api=eth,debug,net,web3,txpool,trace,erigon,admin,personal,debug",
            # "--ws",
            # "--ws.addr=",
            # "--ws.origins=*",
            # "--ws.api=eth,debug,net,web3,txpool,trace,erigon,admin,personal,debug",
            # "--metrics",
            # "--pprof",
            # "--pprof.addr=",
            # "--pprof.port=6060",
            # "--pprof.api=eth,debug,net,web3,txpool,trace,erigon,admin,personal,debug",
            "--datadir","/root/.local/share/erigon",
            # "--metrics.influxdb",
            # "--metrics.influxdb.endpoint=http://localhost:8086",
            # "--metrics.influxdb.database=erigon",
            # "--metrics.influxdb.username=erigon", 
        ]
        }

        resources {
            cpu    = 500
            memory = 512
            }
        }
    }
}
```
Tip: Depending on the size of the machine, you may need to adjust the memory and cpu resources.
You can check your machine's resources with the command `free -m` or `grep MemTotal /proc/meminfo`.

- Run the job
```bash
nomad run eth-node.nomad
```
- Check the job status
```bash
nomad status eth-node
```
- Check the logs
```bash
nomad logs -stderr -f eth-node
```
- Check the node status
```bash
nomad node status
```
- Check the node allocation
```bash
nomad alloc status
```
- Check the node allocation logs
```bash
nomad alloc logs -stderr -f <alloc-id>
```
- Check the node allocation file system
```bash
nomad alloc fs <alloc-id>
```
- Check the ledger
```bash
nomad alloc fs <alloc-id> /root/.local/share/erigon/chaindata
```
- Confirm the ledger survives a restart
```bash
nomad stop eth-node
nomad run eth-node.nomad
```
- Check the logs
```bash
nomad logs -stderr -f eth-node
```
