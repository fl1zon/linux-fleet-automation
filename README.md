# Linux Fleet Automation

> Centralized Linux administration and automation with Ansible.

## Overview

This project is a personal Linux infrastructure project built around **Ansible**.

The goal is to automate the administration and maintenance of multiple Linux machines from a central server.

The project also includes an automated workflow to **wake a remote machine and unlock its encrypted LUKS volume before the system fully boots**.

## Architecture

```text
                    ┌──────────────────┐
                    │   Ansible Server │
                    │                  │
                    │     Ansible      │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
           ┌──────┐       ┌──────┐       ┌──────┐
           │ PC 1 │       │ PC 2 │       │ PC 3 │
           │Linux │       │Linux │       │Linux │
           └──────┘       └──────┘       └──────┘
```

## Features

- Linux system administration
- Remote user management
- SSH key authentication
- System updates and maintenance
- Software installation
- Error handling
- Failure logging
- Remote configuration
- Wake-on-LAN
- Remote LUKS unlocking through Dropbear

## Wake-on-LAN & LUKS

The Wake-on-LAN and LUKS workflow is an extension of the main Ansible project.

```text
Ansible Server
      │
      │ Wake-on-LAN
      ▼
 Linux Client
      │
      │ Boot
      ▼
 Initramfs
      │
      │ SSH / Dropbear
      ▼
 Remote connection
      │
      │ LUKS unlock
      ▼
 Encrypted volume unlocked
      │
      ▼
 Full system boot
```

This combines:

`Ansible` `Wake-on-LAN` `SSH` `Dropbear` `LUKS` `Linux`

## Project Structure

```text
linux-fleet-automation/
│
├── README.md
│
├── inventory/
│   └── hosts.example.ini
│
├── playbooks/
│   ├── users.yml
│   ├── maintenance.yml
│   └── wake-unlock.yml
│
└── scripts/
    └── ...
```

## Technologies

| Technology    | Purpose                |
|---------------|------------------------|
| Linux         | Operating system       |
| Ansible       | Automation             |
| YAML          | Playbook configuration |
| SSH           | Remote administration  |
| Bash          | System scripting       |
| Wake-on-LAN   | Remote power-on        |
| Dropbear      | Early-boot SSH         |
| LUKS          | Disk encryption        |

## Example

### Install Ansible

```bash
sudo apt update
sudo apt install ansible
```

### Install Wake-on-LAN

```bash
sudo apt install wakeonlan
```

### Test the Ansible connection

```bash
ansible Client -i inventory/hosts.example.ini -m ping
```

### Run a playbook

```bash
ansible-playbook -i inventory/hosts.example.ini playbooks/maintenance.yml
```

## Error Handling

The playbooks include error handling and logging mechanisms.

Example log:

```text
2026-06-11T10:15:32 | pc2 | WoL fail
2026-06-11T10:16:14 | pc2 | Dropbear unlock fail
```

This makes it possible to identify which machine and which operation failed.

## What I Learned

This project allowed me to work on:

- Linux administration
- Ansible automation
- SSH
- YAML
- Bash
- Network configuration
- Error handling
- Logging
- Wake-on-LAN
- LUKS
- Dropbear
- Troubleshooting
