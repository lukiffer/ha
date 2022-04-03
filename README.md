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
**service you must configure the submodule that contains your config and import the GPG used to encrypt your secrets.**

### Changing the `config` Submodule URL

The included submodule layout assumes a repository with the following file structure:

```
(root)
  ├─ homeassistant/
  ├─ nginx/
  ╰─ nodered/
```

Where each directory is the configuration root of the respective application.

- You can update `.gitmodules` to point at your copy of such a repository and then run:
  ```bash
  git submodule sync --recursive
  ```
- If you've already done this in your fork of this repository, you can simply run:
  ```bash
  git submodule update --init --recursive
  ```

**Note that you may be required to logout and back in if you're running in the same shell session that was use to run**
**the bootstrap script – your group membership will not be current in that session.**

### Starting the Service

Once you've configured the `config` submodule, you can start the Compose stack by running:

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
the `backup.sh` script to capture a signed, encrypted backup of all configuration paths.

```bash
/opt/ha/scripts/backup.sh --gpg-key <GPG_KEY_ID>
```
