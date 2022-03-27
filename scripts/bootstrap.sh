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
    gnupg \
    lsb-release
}

function install_docker() {
  # Install Docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io

  sudo usermod -aG docker "${USER}"
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
  sudo useradd -s /bin/bash -d /home/ha/ -m -g ha ha
}

function clone_repo() {
  local -r install_path="/opt/ha/"
  sudo mkdir -p "$install_path"
  sudo chown -R "$USER:$USER" "$install_path"
  git clone "git@github.com:lukiffer/ha.git" "$install_path"
  sudo chown -R "ha:ha" "$install_path"
}

function install_service() {
  sudo ln -s /opt/ha/scripts/home-automation.service /lib/systemd/system/home-automation.service
  sudo systemctl daemon-reload
  sudo systemctl enable home-automation.service
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
  set +x;

  echo ""
  echo "The server was bootstrapped successfully."
  echo "Before starting the service, you'll need to generate/add an SSH key that has access to the config submodule repository."
  echo "Then inside /opt/ha/ run:"
  echo "    git submodule update --init --recursive"
  echo "Then start the service by running:"
  echo "    sudo systemctl start home-automation.service"
  echo ""
}

main "$@"
