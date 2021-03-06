#!/usr/bin/env bash

function get_latest_git_release() {
  local -r repository_url="$1"
  local -r tag=$(curl -sSL --head "$repository_url/releases/latest" | grep 'location:' | sed -e "s|location: $repository_url/releases/tag/||" | tr -d '\r')
  printf "%s" "$tag"
}

function update_system() {
  # Get latest package manifests
  sudo apt-get update

  # Upgrade packages
  sudo apt-get upgrade -y
}

function install_dependencies() {
  # Install prerequisite packages
  sudo apt-get update
  sudo apt-get install -y \
    ca-certificates \
    curl \
    git-crypt \
    gnupg \
    lsb-release
}

function install_yq() {
  # Install yq
  sudo curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
}

function install_docker() {
  # Install Docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  sudo usermod -aG docker "$USER"
}

function install_docker_compose() {
  # Install Docker Compose
  local -r docker_compose_repo="https://github.com/docker/compose"
  local -r docker_compose_version=$(get_latest_git_release "$docker_compose_repo")
  sudo curl -fsSL "$docker_compose_repo/releases/download/$docker_compose_version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
}

function install_sops() {
  # Install SOPS
  local -r sops_repo="https://github.com/mozilla/sops"
  local -r sops_version=$(get_latest_git_release "$sops_repo")

  sudo curl -fsSL "$sops_repo/releases/download/$sops_version/sops_${sops_version/v/}_$(dpkg --print-architecture).deb" -o sops.deb
  sudo dpkg -i sops.deb
  sudo rm sops.deb
}

function create_service_account() {
  sudo addgroup ha
  sudo usermod -aG ha "$USER"
  sudo useradd -s /bin/bash -d /home/ha/ -m -g ha ha

  # Add service account to the docker group
  sudo usermod -aG docker ha

  # Initialize GPG keyring for the new user
  sudo -u ha gpg --list-keys
}

function clone_repo() {
  local -r install_path="/opt/ha/"
  sudo mkdir -p "$install_path"
  sudo chown "ha:ha" "$install_path"
  sudo -u ha git clone "https://github.com/lukiffer/ha.git" "$install_path"
}

function install_service() {
  sudo ln -s /opt/ha/scripts/home-automation.service /lib/systemd/system/home-automation.service
  sudo systemctl daemon-reload
  sudo systemctl enable home-automation.service
}

function generate_ssh_key() {
  local -r key_path="/home/ha/.ssh/"
  sudo mkdir -p "$key_path"
  sudo chown -R "ha:ha" "$key_path"
  sudo chmod -R 700 "$key_path"
  sudo -u ha ssh-keygen -t rsa -f "$key_path/id_rsa" -N ''
}

function main() {
  set -x;
  update_system
  install_dependencies
  install_docker
  install_docker_compose
  install_sops
  create_service_account
  clone_repo
  install_service
  generate_ssh_key
  set +x;

  echo ""
  echo "The server was bootstrapped successfully."
  echo ""
  echo "Before starting the service, you'll need to add the following SSH key to a GitHub account that access to the config submodule repository:"
  echo ""
  sudo cat /home/ha/.ssh/id_rsa.pub
  echo ""
  echo "Then inside /opt/ha/ run, initialize the config submodule:"
  echo "    git submodule update --init --recursive"
  echo ""
  echo "Then, import the GPG private key used by SOPS to encrypt the secrets file:"
  echo "    gpg --batch --yes --no-tty --always-trust --import < /path/to/key.asc"
  echo ""
  echo "Then start the service by running:"
  echo "    sudo systemctl start home-automation.service"
  echo ""
}

main "$@"
