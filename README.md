# Home Automation

## Bootstrap Environment

Starting from a base install of Ubuntu Server, run:

```bash
# Get latest package manifests
sudo apt-get update

# Upgrade packages
sudo apt-get upgrade -y

# Install prerequisite packages
sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker ${USER}

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

```


## Usage

### Backup and restore

Use the `backup.sh` script to capture a signed, encrypted backup of non-declarative configuration files. These are
files that, while they do contain configuration values, are not declarative and are mutated by the system that uses
them.

```bash
./backup.sh --gpg-key 0000000000000000000000000000000000000000
```

Use the `restore.sh` script to restore a backup over the existing file structure. It is recommended that you first
backup the existing files using the instructions above.

```bash
./restore.sh path/to/backup.tar.gz.gpg
```
