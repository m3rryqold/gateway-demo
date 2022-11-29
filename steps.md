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
# fetch the logs from the node and check the ledger
```bash
nomad alloc logs -stderr -f <alloc-id>
```
- Check the ledger
```bash
nomad alloc fs <alloc-id> /root/.local/share/erigon/chaindata
```
# fetch block data from the node
```bash
curl -X POST --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", true],"id":1}' -H "Content-Type: application/json" http://localhost:8545
```


# Automate deployment of the ethereum node using Ansible
## Initial (Manual)
- Install Ansible
```bash
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible
```
- Create a directory for the Ansible playbook
```bash
mkdir -p ~/ansible/eth-node
cd ~/ansible/eth-node
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
      apt:
        name: docker.io
        state: present
    - name: Install Docker Compose
      apt:
        name: docker-compose
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
        sudo nomad agent -dev -bind
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
                    "--datadir","/root/.local/share/erigon",
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
        nomad run eth-node.nomad
    - name: Check the job status
      shell: |
        nomad status eth-node
    - name: Check the logs
      shell: |
        nomad logs -stderr -f eth-node
    - name: Check the node status
      shell: |
        nomad node status
    - name: Check the node allocation
      shell: |
        nomad alloc status
    - name: Check the node allocation logs
      shell: |
        nomad alloc logs -stderr -f <alloc-id>
    - name: Check the node allocation file system
      shell: |
        nomad alloc fs <alloc-id>
    - name: Check the ledger
      shell: |
        nomad alloc fs <alloc-id> /root/.local/share/erigon/chaindata
    - name: Confirm the ledger survives a restart
      shell: |
        nomad stop eth-node
        nomad run eth-node.nomad
    - name: Check the logs
      shell: |
        nomad logs -stderr -f eth-node
```
- Run the playbook
```bash
ansible-playbook eth-node.yml
```
Possible plus:
```bash
    - name: Create a directory for the erigon data
      file:
        path: /home/ubuntu/erigon
        state: directory
        owner: ubuntu
        group: ubuntu
    - name: Create a docker-compose.yml file
      copy:
        content: |
          version: "3.7"
          services:
            erigon:
              image: thorax/erigon:stable
              container_name: erigon
              restart: unless-stopped
              volumes:
                - /home/ubuntu/erigon:/root/.local/share/erigon
              ports:
                - 8545:8545
                - 8546:8546
                - 30303:30303
                - 30303:30303/udp
              command: --chain goerli --datadir /root/.local/share/erigon
        dest: /home/ubuntu/docker-compose.yml
    - name: Start the erigon node
      docker_compose:
        project_src: /home/ubuntu
        state: present
```

# Deploy Django REST API in Nomad to fetch data from the Ethereum node
### Django REST API Installation
- Create a job file `django-api.nomad`
```bash
job "django-api" {
  datacenters = ["dc1"]
  type = "service"

  group "django-api" {
    count = 1

    task "django-api" {
      driver = "docker"

      config {
        image = "django-api:latest"
        volumes = [
          "local/erigon:/root/.local/share/erigon",
        ]
        args = [
          "--chain","goerli",
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
- Build the docker image
Dockerfile
```bash
FROM python:3.8

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD [ "python", "./manage.py", "runserver", "localhost:8000" ]
```
requirements.txt
```bash
Django==3.2.4
djangorestframework==3.12.4
```
```bash
docker build -t django-api:latest .
```
- Run the job
```bash
nomad run django-api.nomad
```
- Check the job status
```bash
nomad status django-api
```
- Check the logs
```bash
nomad logs -stderr -f django-api
```

# Deploy a frontend to interact with the API
### Frontend Installation
- Create a job file `frontend.nomad`
```bash
job "frontend" {
  datacenters = ["dc1"]
  type = "service"

  group "frontend" {
    count = 1

    task "frontend" {
      driver = "docker"

      config {
        image = "frontend:latest"
        }

        resources {
            cpu    = 500
            memory = 512
            }
        }
    }
}
```
- Build the docker image
Dockerfile
```bash
FROM node:14.17.0-alpine3.13

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000
CMD [ "npm", "start" ]
```
package.json
```bash
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@testing-library/jest-dom": "^5.11.4",
    "@testing-library/react": "^11.1.0",
    "@testing-library/user-event": "^12.1.10",
    "axios": "^0.21.1",
    "react": "^17.0.2",
    "react-dom": "^17.0.2",
    "react-scripts": "4.0.3",
    "web-vitals": "^1.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
```
```bash
docker build -t frontend:latest .
```
- Run the job
```bash
nomad run frontend.nomad
```
- Check the job status
```bash
nomad status frontend
```
- Check the logs
```bash
nomad logs -stderr -f frontend
```

# Deploy a load balancer to distribute the load between the nodes
### Load Balancer Installation
- Create a job file `load-balancer.nomad`
```bash
job "load-balancer" {
  datacenters = ["dc1"]
  type = "service"

  group "load-balancer" {
    count = 1

    task "load-balancer" {
      driver = "docker"

      config {
        image = "load-balancer:latest"
        }

        resources {
            cpu    = 500
            memory = 512
            }
        }
    }
}
```
- Build the docker image
Dockerfile
```bash
FROM nginx:1.21.0-alpine

COPY nginx.conf /etc/nginx/nginx.conf
```
nginx.conf
```bash
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    upstream django-api {
        server django-api:8000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://django-api;
        }
    }
}
```
```bash
docker build -t load-balancer:latest .
```
- Run the job
```bash
nomad run load-balancer.nomad
```

