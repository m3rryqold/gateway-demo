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

### Deploy an ethereum node as a container into a Nomad cluster and run it on a testnet (Goerli), using thorax/erigon
- Create a job file `eth-node.nomad`
```bash
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
### Fetch the logs from the node and check the ledger
```bash
nomad alloc logs -stderr -f <alloc-id>
```
- Check the ledger
```bash
nomad alloc fs <alloc-id> /root/.local/share/erigon/chaindata
```
### Fetch block data from the node
```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", true],"id":1}' -H "Content-Type: application/json" http://localhost:8545
```


## Automate deployment of the ethereum node using Ansible

- Install Ansible
```bash
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```
- Create a directory for the Ansible playbook
```bash
mkdir ansible
cd ansible
```
- Create a file `hosts` with the following content
```bash
[eth-node]
eth-node-1 ansible_host=${eth-node-1-ip}
```
- Create a file `eth-node.yml` with the following content
```bash
---
- hosts: eth-node
  become: yes
  tasks:
    - name: Install Docker
      snap:
        name: docker
        state: present
    - name: Set hostname
      hostname:
        name: eth-node-1
    - name: Install Nomad
      shell: |
        wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install nomad
    - name: Start Nomad agent in dev mode
      shell: |
        nohup sudo nomad agent -dev -bind 0.0.0.0 &
    - name: Check Nomad agent status
      shell: |
        nomad node status
        nomad server members
        nomad status
    - name: Create a job file
      copy:
        content: |
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
        dest: /home/ubuntu/eth-node.nomad
    - name: Run the job
      shell: |
        nomad run /home/ubuntu/eth-node.nomad
    - name: Check the job status
      shell: |
        nomad status eth-node
```
- Run the playbook
```bash
ansible-playbook eth-node.yml
```

