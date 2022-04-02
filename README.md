# Home Automation

This repository is an artifact of my frustration with trying to keep my home automation stack current. It's a simple
Docker Compose stack with [Home Assistant](https://github.com/home-assistant/docker),
[Node-RED](https://github.com/node-red/node-red), and [MariaDB](https://github.com/MariaDB/server), but with some
automation workflows around config management and keeping everything updated. This is more a personal convenience, but
perhaps you might find it helpful.

## Bootstrapping the Docker Host

**This script assumes you're installing on Ubuntu Server 20.04.**

```bash
curl -sSL https://raw.githubusercontent.com/lukiffer/ha/main/scripts/bootstrap.sh | bash
```

This script will install all the necessary prerequisites and clone this repository to `/opt/ha/`. **Before starting the**
**service you must configure the submodule that contains your config.**

### Changing the `config` Submodule URL

The included submodule layout assumes a repository with the following file structure:

```
(root)
  ├─ homeassistant/
  ╰─ nodered/
```

Where each directory is the configuration root of the respective application.

You can update `.gitmodules` to point at your copy of such a repository and then run `git submodule sync --recursive` to
pull your configuration to the expected location.

If you've already done this in your fork of this repository, you can simply run `git submodule update --init --recursive`
when needed.

```bash
# As the ha user
sudo -iu ha -H

# Import the GPG key used to encrypt secrets.yaml in your config
gpg --batch --yes --no-tty --always-trust --import < /path/to/key.asc
```

### Configuring SOPS

The sensitive values typically stored in `secrets.yaml` for Home Assistant are assumed to be
[SOPS](https://github.com/mozilla/sops)-encrypted. You'll need to configure any credentials required for SOPS to be
available to the `ha` service account.

### Starting the Service

Once you've configured the `config` submodule and configured SOPS, you can start the Compose stack by running:

```bash
sudo systemctl start home-automation.service
```

## Utility Scripts

### Updating to Latest Containers

You can update to the latest version of each component's published containers by running:

```bash
sudo /opt/ha/scripts/update.sh
```

**Note that the stack will be temporarily offline during the update.**

### Backup and restore

All declarative configuration files are assumed to be stored in source control (in the `config` submodule). You can use
the `backup.sh` script to capture a signed, encrypted backup of non-declarative configuration files. These are files
that, while they do contain configuration values, are not declarative and are mutated by the system that uses them.

```bash
./backup.sh --gpg-key <GPG_KEY_ID>
```

Use the `restore.sh` script to restore a backup over the existing file structure. It is recommended that you first
backup the existing files using the instructions above.

```bash
./restore.sh path/to/backup.tar.gz.gpg
```
