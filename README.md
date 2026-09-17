## Overview

This project is a personal Linux infrastructure project built around **Ansible**.

The goal is to automate the administration and maintenance of multiple Linux machines from a central server.

The project also includes an automated workflow to **wake a remote machine and unlock its encrypted LUKS volume before the system fully boots**.

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

## Architecture

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

## Wake-on-LAN & LUKS

The Wake-on-LAN and LUKS workflow is an extension of the main Ansible project.

Ansible Server
↓
Wake-on-LAN
↓
Linux Client
↓
System Boot
↓
Initramfs
↓
SSH / Dropbear
↓
Remote connection
↓
LUKS unlock
↓
Encrypted volume unlocked
↓
Full system boot

This combines:

`Ansible` `Wake-on-LAN` `SSH` `Dropbear` `LUKS` `Linux`

## Project Structure

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

Install Ansible:

`sudo apt update`
`sudo apt install ansible`

Install Wake-on-LAN:

`sudo apt install wakeonlan`

Test the Ansible connection:

`ansible Client -i inventory/hosts.example.ini -m ping`

Run a playbook:

`ansible-playbook -i inventory/hosts.example.ini playbooks/maintenance.yml`
