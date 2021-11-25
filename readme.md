# Introduction

Docker changed its licensing for Docker Desktop and for this reason bigger companies need to pay to be able to legaly use docker desktop. Docker desktop didn't just provide a UI, but conveniently wired up docker on WSL2 with windows. Since the licensing didn't change for docker engine and docker compose, its legal to manually install and use those.

These scripts provide an easier way of installing docker and wiring everything up so that it just works. <b>Click'n'play</b> is the intention

# Execution

Clone this repo and execute 'setup-docker.ps1'

After the setup is finished and docker is started, you should be able to execute docker and docker-compose commands

Example:
- docker -v
- docker-compose version

The setup script installs portainer as the default UI tool if the user accepts the installation during setup. See url and user credentials further below

# Scripts explained

- setup-docker
    - Installs docker in WSL2 (setup-docker-bash.sh)
    - Configures proxy for port 2375 from windows to WSL2
    - Downloads docker.exe and docker compose (V2) into C:\bin
    - Adds new DOCKER_HOST system environment variable
    - Adds C:\bin to system path environment variable
- install-portainer.ps1
    - Runs portainer image inside docker
    - Creates default admin user. User: <b>admin</b> Password: <b>adminpassword</b>
    - Adds local docker desktop environment
    - Open https://localhost:9443 in your browser
- start-docker.ps1
    - Starts docker in WSL2

# Recommended UI tools

lazydocker: https://github.com/jesseduffield/lazydocker"

VSC: https://code.visualstudio.com/docs/containers/overview

dockly: https://github.com/lirantal/dockly

# Attention

This was only testet with Ubuntu 20.04 LTS
