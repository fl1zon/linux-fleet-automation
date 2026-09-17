#!/bin/bash

# Pour chaque user 
ssh -t user1@IP_client1 "echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config && sudo systemctl restart ssh"
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@IP_client1
ssh -t user1@IP_client1 sudo systemctl restart ssh

# ...