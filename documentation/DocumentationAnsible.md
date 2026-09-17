## Documentation Ansible - NADER Adam - BTS CIEL IR

### Sommaire

- [I ) Préparation du poste client](#i--préparation-du-poste-client)
  - [1 ) Installation du service SSH](#1--installation-du-service-ssh)

- [II ) Préparation de la machine serveur](#ii--préparation-de-la-machine-serveur)
  - [1 ) Installation des outils nécessaires](#1--installation-des-outils-nécessaires)
  - [2 ) Génération de la clé SSH](#2--génération-de-la-clé-ssh)
  - [3 ) Création du script d'activation de l'accès Root](#4--création-du-script-dactivation-de-laccès-root)
  - [4 ) Attribution des droits d'exécution](#4--attribution-des-droits-dexécution)

- [III ) Déploiement et configuration avec Ansible](#iii--déploiement-et-configuration-avec-ansible)
  - [1 ) Création de l'inventaire Ansible](#1--création-de-l'inventaire-ansible)
  - [2 ) Création du fichier de logs sans contenu](#2--création-du-fichier-de-logs-sans-contenu)
  - [3 ) Création du playbook de récupération des informations réseau](#3--création-du-playbook-de-récupération-des-informations-réseau)
  - [4 ) Playbook UserAnsible.yaml](#4--playbook-useransibleyaml)
  - [5 ) Playbook LancerDecrypter.yaml](#5--playbook-lancerdecrypteryaml)
  - [6 ) Playbook InstallApps.yaml](#6--playbook-installappsyaml)
  - [7 ) Playbook Crontab.yaml](#7--playbook-crontabyaml)

- [IV ) Scénario de mise en situation](#iv--scénario-de-mise-en-situation)
  - [1 ) Lancement des machines](#1--lancement-des-machines)
  - [2 ) Exécution des programmes](#2--exécution-des-programmes)

---

### Résumé du projet

Ce projet permet de déployer et administrer automatiquement plusieurs machines clientes Linux grâce à **Ansible**.

Fonctions principales :

- Préparation des clients **SSH**
- Création d'un utilisateur dédié **ansible**
- Connexion SSH sans mot de passe avec **clé ed25519**
- Configuration des **droits sudo** sans mot de passe
- Mise en place de **Dropbear**
- Activation du **Wake-on-LAN**
- Réveil **automatique** des machines
- Déchiffrement **automatique** au démarrage
- Mise à jour **complète** des systèmes
- Installation **automatique** des logiciels nécessaires
- Mise à jour **automatique** des PCs à 8h00
- Gestion des **erreurs** avec un fichier de logs

---

### Schéma d'architecture

Serveur Ansible
├── Inventaire1.ini
├── CartesReseau.yaml
├── UserAnsible.yaml
├── LancerDecrypter.yaml
└── InstallApps.yaml
       │
            ▼
Clients Linux
├── SSH
├── Utilisateur ansible
├── Dropbear
├── Wake-on-LAN
└── LUKS

---

### Playbooks

| Playbook | Fonction |
|-----------|-----------|
| CartesReseau.yaml | Création de l'inventaire dynamique |
| UserAnsible.yaml | Création du compte ansible |
| LancerDecrypter.yaml | WoL + Déchiffrement |
| InstallApps.yaml | Installation logicielle |
| Crontab.yaml | Mise à jour automatique |

---

### I ) Préparation du poste client

##### 1 ) Installation du service SSH
##### Sur le poste client
`user@client:~$ sudo apt install ssh -y`

Si le PC est neuf, faire:
`user@client:~$  sudo passwd root && sudo apt install ssh -y`

---

### II ) Préparation de la machine serveur

##### 1 ) Installation des outils nécessaires
##### Sur la machine serveur
`user@serveur:~$ sudo apt install ansible -y && sudo apt install ssh -y && sudo apt install wakeonlan -y`

######

##### 2 ) Génération de la clé SSH
`user@serveur:~$ ssh-keygen -t ed25519`

######

##### 3 ) Création du script d'activation de l'accès Root
`user@serveur:~$ nano script.sh`
- Donner au serveur l'accès au root client par SSH + relancer SSH :
```
ssh -o StrictHostKeyChecking=no -t user@IP_client "echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config && sudo systemctl restart ssh"
```    
- Copier la clé générée pour se connecter au root sans mot de passe + relancer SSH :
```
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@IP_client
```

Contenu ***script.sh*** :
```
#!/bin/bash

# Pour chaque user 
ssh -t user1@IP_client1 "echo 'PermitRootLogin yes' | sudo tee -a /etc/ssh/sshd_config && sudo systemctl restart ssh"
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@IP_client1
ssh -t user1@IP_client1 sudo systemctl restart ssh

# ...
```

######

##### 4 ) Attribution des droits d'exécution
`user@serveur:~$ chmod +x script.sh`

---

### III ) Déploiement et configuration avec Ansible

##### 1 ) Création de l'inventaire Ansible
##### Sur la machine serveur
`user@serveur:~$ nano Inventaire1.ini`

Contenu ***Inventaire1.ini*** :
```
[Serveur]
IP_serveur ansible_user=nom_du_user

[Clients]
IP_client1 ansible_user=root

# ...
```

######

##### 2 ) Création du fichier de logs sans contenu
`user@serveur:~$ nano ansibleFails.log`

######

##### 3 ) Création du playbook de récupération des informations réseau
`user@serveur:~$ nano CartesReseau.yaml`

Contenu ***CartesReseau.yaml*** :
```
---
# Partie 1/3 : Création automatique du fichier Inventaire2.ini
#
# Objectif :
# - Créer l'Inventaire2.ini avec une structure Ansible
#   de façon à l'utiliser pour WoL plus tard
#
# Le fichier ne sera pas écrasé s'il existe déjà
# afin de conserver les anciens PCs ajoutés,
# lors de l'ajout de nouveaux PCs.

- name: Initialiser inventaire

# Exécution sur le serveur Ansible
  hosts: localhost

# Exécution directement sur le serveur Ansible
  become: no

  tasks:

# Bloc de création de l'inventaire
    - block:

# Création du fichier inventaire initial
        - name: Créer Inventaire2.ini
          copy:

# Emplacement du fichier final
            dest: /chemin/vers/Inventaire2.ini

# Contenu créé au premier lancement
            content: |
              [Serveur]
              IP_serveur ansible_user=user

              [Clients]

              [UserAnsible]

# Ne remplace pas un inventaire déjà existant
            force: no

# Si la création échoue
      rescue:

        - name: Log erreur création inventaire
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes

# Format de type :
# 2026-06-22 15:17:32 | PC concerné | Nom de l'erreur
            line: "{{ lookup('pipe','TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | localhost | création Inventaire2 failed"

# Partie 2/3 : Récupération des informations réseau
#
# Objectif, récupérer :
# - Nom du PC
# - Adresse IP
# - Adresse MAC
# - Carte réseau utilisée
# - Identifiant unique du système Linux
# - Date d'ajout dans l'inventaire

- name: Récupérer informations réseau

# Exécute les commandes sur tous les PCs du groupe Clients
  hosts: Clients

# Utilisation des droits administrateur
  become: yes

  tasks:

# Bloc principal de récupération
    - block:

# Récupération du nom de la machine
        - name: Récupérer le hostname du PC
          command: hostname

# Sauvegarde du résultat dans une variable
# Utilisation : hostname_pc.stdout
          register: hostname_pc

# Récupération de l'interface réseau active
        - name: Récupérer la carte réseau active
          shell: |
            ip route | grep default | awk '{print $5}'

# Stockage de l'interface
          register: interface_reseau

# Récupération de l'adresse MAC
        - name: Récupérer l'adresse MAC
          shell: |
            ip link show {{ interface_reseau.stdout }} | grep ether | awk '{print $2}'
          register: mac_pc

# Récupération de l'adresse IP
        - name: Récupérer IP du PC
          shell: |
            ip -4 addr show {{ interface_reseau.stdout }} | grep inet | awk '{print $2}' | cut -d/ -f1
          register: ip_pc

# Récupération de l'identifiant unique de la machine Linux
# Sert à identifier le PC de manière unique
        - name: Récupérer Machine ID
          command: cat /etc/machine-id
          register: machine_id

# Date d'ajout dans l'inventaire
        - name: Récupérer date ajout
          command: date "+%Y-%m-%d"
          register: date_ajout

# En cas d'erreur pendant la récupération
      rescue:

        - name: Log erreur récupération réseau
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe','TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | récupération failed"
          delegate_to: localhost

# Partie 3/3 : Ajout automatique dans Inventaire2.ini
#
# Objectif :
# Ajouter le PC dans les deux groupes :
#
# Clients :
# Connexion root temporaire pour préparation
#
# UserAnsible :
# Connexion finale avec l'utilisateur ansible

    - block:

# Ajout du PC dans Clients
        - name: Ajouter PC dans Clients
          become: no
          lineinfile:
            path: /chemin/vers/Inventaire2.ini
            create: yes

# Ajoute sous [Clients]
            insertafter: '^\[Clients\]$'

# Empêche les doublons
            regexp: "^{{ hostname_pc.stdout }} .*ansible_user=root"

# Ligne finale ajoutée
            line: "{{ hostname_pc.stdout }} ansible_host={{ ip_pc.stdout }} ansible_user=root mac={{ mac_pc.stdout }} carte=netplan-{{ interface_reseau.stdout }} machine_id={{ machine_id.stdout }} date={{ date_ajout.stdout }}"
          delegate_to: localhost

# Ajout du PC dans UserAnsible
        - name: Ajouter PC dans UserAnsible
          become: no
          lineinfile:
            path: /chemin/vers/Inventaire2.ini
            create: yes

# Ajoute sous [UserAnsible]
            insertafter: '^\[UserAnsible\]$'

# Empêche les doublons
            regexp: "^{{ hostname_pc.stdout }} .*ansible_user=ansible"

# Ligne finale utilisateur ansible
            line: "{{ hostname_pc.stdout }}_ansible ansible_host={{ ip_pc.stdout }} ansible_user=ansible mac={{ mac_pc.stdout }} carte=netplan-{{ interface_reseau.stdout }} machine_id={{ machine_id.stdout }} date={{ date_ajout.stdout }}"
          delegate_to: localhost

# Si l'ajout échoue
      rescue:

        - name: Log erreur sauvegarde
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe','TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | sauvegarde failed"
          delegate_to: localhost

```

Lors de l'exécution, on aura un Inventaire2.ini final de la forme :

Contenu ***Inventaire2.ini*** :
```
[Serveur]
IP_serveur ansible_user=user

[Clients]
Hostname_client1 ansible_host=IP_client1 ansible_user=root mac=AA:BB:CC:DD:EE:FF carte=netplan-Nom_de_carte1 machine_id=ID_unique_machine1 date=AAAA-MM-JJ

# ...

[UserAnsible]
Hostname_client1 ansible_host=IP_client1 ansible_user=ansible mac=AA:BB:CC:DD:EE:FF carte=netplan-Nom_de_carte1 machine_id=ID_unique_machine1 date=AAAA-MM-JJ

# ...
```
######

##### 4 ) Création du playbook UserAnsible.yaml
`user@serveur:~$ nano UserAnsible.yaml`

Contenu ***UserAnsible.yaml*** :
```
---
# Partie 1/3 : Création et configuration de l'utilisateur Ansible
#
# Objectif :
# Créer un utilisateur dédié à l'administration distante des machines clientes
# qui sera utilisé uniquement par Ansible,
# afin d'éviter l'utilisation du compte root par sécurité

- name: Créer user ansible
  hosts: Clients
  become: yes

  tasks:

    - block:
        - name: Mise à jour complète
          apt:

# Met à jour la liste des paquets disponibles
            update_cache: yes

# Effectue une mise à niveau complète des paquets installés
            upgrade: full

# Supprime les paquets devenus inutiles
            autoremove: yes

# Nettoie le cache local des paquets
            autoclean: yes

      rescue:
        - name: Log - échec mise à jour système
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Maj système failed"
          delegate_to: localhost

    - block:
        - name: Créer utilisateur ansible
          user:
# Nom du compte utilisé par Ansible pour se connecter
            name: ansible
            shell: /bin/bash
            create_home: yes
# Permet d'exécuter des commandes administrateur
            groups: sudo
            append: yes
# Définit le mot de passe pour le compte
            password: "{{ 'mdp_user_ansible' | password_hash('sha512') }}"

      rescue:
        - name: Log erreur création user
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Création utilisateur failed"
          delegate_to: localhost

    - block:
        - name: Ajouter clé SSH
          authorized_key:

# Utilisateur auquel sera associée la clé publique
            user: ansible

# Clé publique permettant une connexion SSH sans mot de passe
# Faire : cat ~/.ssh/id_ed25519.pub
            key: "ssh-ed25519 ..."
            state: present

      rescue:
        - name: Log erreur clé SSH
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Clé SSH failed"
          delegate_to: localhost

    - block:
        - name: Ajouter NOPASSWD
          lineinfile:
            path: /etc/sudoers.d/ansible

# Règle permettant à ansible d'utiliser sudo sans authentification
            line: 'ansible ALL=(ALL) NOPASSWD:ALL'
            create: yes

      rescue:
        - name: Log erreur NOPASSWD
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Ajout NOPASSWD failed"
          delegate_to: localhost

    - block:
        - name: Cacher ansible de log list
          copy:

# Cacher le compte de la liste de connexion
            dest: /var/lib/AccountsService/users/ansible
            content: |
              [User]
              SystemAccount=true

      rescue:
        - name: Log erreur cacher ansible
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Cacher user fail"
          delegate_to: localhost

    - block:
        - name: Restart SSH
          command: systemctl restart ssh

      rescue:
        - name: Log erreur Restart SSH
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Restart SSH fail"
          delegate_to: localhost

# Partie 2/2 : Configuration Dropbear et Wake-on-LAN
#
# Objectif :
# Préparer les machines pour permettre :
# - Le déchiffrement via Dropbear
# - L'allumage à distance via WoL
# - La sécurisation du compte Ansible
- name: Setup Dropbear & WoL
  hosts: Clients
  become: yes

  tasks:

# Installation du service Dropbear dans l'environnement initramfs
    - block:
        - name: Installer Dropbear
          apt:
            name: dropbear-initramfs
            state: present

      rescue:
        - name: Log - échec installation Dropbear
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Dropbear install fail"
          delegate_to: localhost

    - block:
        - name: Ajout Dropbear Options
          lineinfile:
            path: /etc/dropbear/initramfs/dropbear.conf

# Modification du port SSH de Dropbear
# Le port 2222 est utilisé pour éviter le conflit avec SSH classique (port 22)
            line: 'DROPBEAR_OPTIONS="-I 239 -j -k -p 2222 -s"'
            state: present

      rescue:
        - name: Log erreur Dropbear Options
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Ajout Dropbear Options failed"
          delegate_to: localhost

    - block:
        - name: Ajouter Clé dans Dropbear
          lineinfile:
            path: /etc/dropbear/initramfs/authorized_keys
            create: yes

# Clé publique permettant la connexion
# root temporaire pour Dropbear
# Faire : cat ~/.ssh/id_ed25519.pub
            line: "ssh-ed25519 ..."
            state: present

      rescue:
        - name: Log erreur Clé Dropbear
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Ajout Clé Dropbear failed"
          delegate_to: localhost

    - block:
        - name: Relancer initramfs

# Réintégrer la nouvelle configuration Dropbear
          command: sudo update-initramfs -u

      rescue:
        - name: Log erreur Relancer initramfs
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Relancer initramfs failed"
          delegate_to: localhost

    - block:
        - name: Relancer ssh

# Recharge la configuration SSH après modification
          command: sudo systemctl restart ssh

      rescue:
        - name: Log erreur Relancer ssh
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Relancer ssh failed"
          delegate_to: localhost

    - block:
        - name: Activer WoL

# Active le réveil réseau permanent de la carte réseau
          command: nmcli connection modify "{{ carte }}" 802-3-ethernet.wake-on-lan magic

      rescue:
        - name: Log erreur Activer WoL
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Activer WoL failed"
          delegate_to: localhost

    - block:
        - name: Bloquer login avec mdp
          user:
            name: ansible

# Empêche une connexion avec mot de passe
            password_lock: yes

      rescue:
        - name: Log erreur Bloquer login
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Bloquer login failed"
          delegate_to: localhost

    - block:
        - name: Relancer PC
          command: reboot
	  async: 1
	  poll: 0

      rescue:
        - name: Log erreur Relancer
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Relancer failed"
          delegate_to: localhost

# Attendre le relancement complet de tous les PCs
    - name: Pause
      pause:
        seconds: 30

- name: Lancer + Décrypter Pc
  hosts: localhost
  become: no

  tasks:

# Décryptage automatique du disque LUKS
    - name: Décrypter PCs avec Dropbear
      command: >
        ssh -o StrictHostKeyChecking=no -p 2222 root@{{ hostvars[item].ansible_host }}
        'echo -n "mdp_de_decryptage" | cryptroot-unlock'
      loop: "{{ groups['Clients'] }}"
      register: resultat_dropbear
      ignore_errors: yes

    - name: Log décrypte fail
      lineinfile:
        path: /chemin/vers/ansibleFails.log
        create: yes
        line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ item.item }} | Dropbear décrypt fail"
      loop: "{{ resultat_dropbear.results }}"
      when: item.failed
      delegate_to: localhost

# Attente que les machines finissent leur boot complet
    - name: Pause
      pause:
        seconds: 60

```

######

##### 5 ) Création du playbook LancerDecrypter.yaml
`user@serveur:~$ nano LancerDecrypter.yaml`

Contenu ***LancerDecrypter.yaml*** :
```
---
# Partie 1/2 : Réveil des machines avec Wake-on-LAN puis déchiffrement du disque
#
# Objectif :
# Démarrer les machines clientes à distance grâce au Wake-on-LAN (WoL)
# puis déverrouiller automatiquement le disque chiffré LUKS via Dropbear
#
# Le playbook s'exécute d'abord depuis le serveur Ansible,
# puis se connecte aux machines une fois celles-ci démarrées.
- name: Lancer + Décrypter Pc
  hosts: localhost
  become: no

  tasks:

# Envoie un paquet magique WoL à chaque machine dans [Clients]
    - name: Allumer les Pcs avec WoL
      command: wakeonlan "{{ hostvars[item].mac }}"

# Boucle sur tous les clients de l'inventaire
      loop: "{{ groups['Clients'] }}"

# Stocke le résultat de chaque tentative WoL ( pour les logs )
      register: resultat_wol
      ignore_errors: yes

    - name: Log WoL fail
      lineinfile:
        path: /chemin/vers/ansibleFails.log
        create: yes
        line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ item.item }} | WoL fail"

# Reboucle sur les résultats enregistrés précédemment
      loop: "{{ resultat_wol.results }}"

# Exécute le log uniquement si le résultat contient une erreur
      when: item.failed
      delegate_to: localhost

# Attente que les machines aient le temps de démarrer
    - name: Pause
      pause:
        seconds: 120

# Décryptage automatique du disque LUKS
    - name: Décrypter PCs avec Dropbear
      command: >
        ssh -o StrictHostKeyChecking=no -p 2222 root@{{ hostvars[item].ansible_host }}
        'echo -n "mdp_de_decryptage" | cryptroot-unlock'
      loop: "{{ groups['Clients'] }}"
      register: resultat_dropbear
      ignore_errors: yes

    - name: Log décrypte fail
      lineinfile:
        path: /chemin/vers/ansibleFails.log
        create: yes
        line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ item.item }} | Dropbear décrypt fail"
      loop: "{{ resultat_dropbear.results }}"
      when: item.failed
      delegate_to: localhost

# Attente que les machines finissent leur boot complet
    - name: Pause
      pause:
        seconds: 60

# Partie 2/2 : Connexion avec l'utilisateur Ansible et maintenance des machines
#
# Objectif :
# Une fois les machines démarrées et déchiffrées :
# - Se connecter avec l'utilisateur Ansible
# - Effectuer les mises à jour système
# - Éteindre les machines proprement
- name: Mise à jour complète + Shutdown Pc
  hosts: UserAnsible
  become: yes

  tasks:

    - block:
        - name: Maj
          apt:
            update_cache: yes
            upgrade: full
            autoremove: yes
            autoclean: yes

      rescue:
        - name: Log Maj fail
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Maj fail"
          delegate_to: localhost

    - block:
        - name: Shutdown
          command: shutdown now
          async: 1
          poll: 0

      rescue:
        - name: Log shutdown fail
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Shutdown fail"
          delegate_to: localhost

```

######

##### 6 ) Création du playbook InstallApps.yaml
`user@serveur:~$ nano InstallApps.yaml`

Contenu ***InstallApps.yaml*** :
```
---
# Partie 1/1 : Mise à jour du système et installation des logiciels nécessaires
#
# S'exécute sur les PCs du groupe [UserAnsible]
#
# Logiciels installés :
#
# - TeX Live Full
# - Anaconda
# - Dropbox
# - Google Chrome
# - Xournal
# - R
# - RStudio
# - Visual Studio Code
# - Zoom
# - LibreOffice 
#
# Les erreurs produites lors de l'installation sont enregistrées 
# dans le fichier ansibleFails.log
- name: Maj + Installation des App
  hosts: UserAnsible
  become: yes

  tasks:

    - block:
        - name: Mise à jour complète
          apt:
            update_cache: yes
            upgrade: full
            autoremove: yes
            autoclean: yes

      rescue:
        - name: Log - échec mise à jour système
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Maj système failed"
          delegate_to: localhost

    - block:
        - name: Installer texlive-full
          apt:
            name: texlive-full
            state: present

      rescue:
        - name: Log - échec installation texlive-full
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | texlive install failed"
          delegate_to: localhost

    - block:
        - name: Télécharger Anaconda
          get_url:
            url: https://repo.anaconda.com/archive/Anaconda3-2025.12-2-Linux-x86_64.sh
            dest: /tmp/anaconda.sh

      rescue:
        - name: Log - échec téléchargement Anaconda
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Anaconda download failed"
          delegate_to: localhost

    - block:
        - name: Installer Anaconda
          shell: bash /tmp/anaconda.sh -b -p /opt/anaconda/

      rescue:
        - name: Log - échec installation Anaconda
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Anaconda install failed"
          delegate_to: localhost

    - block:
        - name: Télécharger Dropbox
          get_url:
            url: https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2026.01.15_amd64.deb
            dest: /tmp/dropbox.deb

      rescue:
        - name: Log - échec téléchargement Dropbox
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Dropbox download failed"
          delegate_to: localhost

    - block:
        - name: Installer Dropbox
          apt:
            deb: /tmp/dropbox.deb

      rescue:
        - name: Log - échec installation  Dropbox
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Dropbox install failed"
          delegate_to: localhost

    - block:
        - name: Télécharger Chrome
          get_url:
            url: https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            dest: /tmp/google-chrome.deb

      rescue:
        - name: Log - échec téléchargement Chrome
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Chrome download failed"
          delegate_to: localhost

    - block:
        - name: Installer Chrome
          apt:
            deb: /tmp/google-chrome.deb

      rescue:
        - name: Log - échec installation Chrome
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Chrome install failed"
          delegate_to: localhost

    - block:
        - name: Installer Xournal
          apt:
            name: xournal
            state: present

      rescue:
        - name: Log - échec installation Xournal
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Xournal install failed"
          delegate_to: localhost

    - block:
        - name: Installer R
          apt:
            name: r-base
            state: present

      rescue:
        - name: Log - échec installation R
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | R install failed"
          delegate_to: localhost

    - block:
        - name: Télécharger RStudio
          get_url:
            url: https://download1.rstudio.org/electron/jammy/amd64/rstudio-2026.04.0-526-amd64.deb
            dest: /tmp/rstudio.deb

      rescue:
        - name: Log - échec téléchargement RStudio
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | RStudio download failed"
          delegate_to: localhost

    - block:
        - name: Installer RStudio
          apt:
            deb: /tmp/rstudio.deb

      rescue:
        - name: Log - échec installation RStudio
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | RStudio install failed"
          delegate_to: localhost

    - block:
        - name: Télécharger VSCode
          get_url:
            url: https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
            dest: /tmp/vscode.deb

      rescue:
        - name: Log - échec téléchargement VSCode
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | VSCode download failed"
          delegate_to: localhost

    - block:
        - name: Installer VSCode
          apt:
            deb: /tmp/vscode.deb

      rescue:
        - name: Log - échec installation VSCode
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | VSCode install failed"
          delegate_to: localhost

    - block:
        - name: Télécharger Zoom
          get_url:
            url: https://zoom.us/client/latest/zoom_amd64.deb
            dest: /tmp/zoom.deb

      rescue:
        - name: Log - échec téléchargement Zoom
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Zoom download failed"
          delegate_to: localhost

    - block:
        - name: Installer Zoom
          apt:
            deb: /tmp/zoom.deb

      rescue:
        - name: Log - échec installation Zoom
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Zoom install failed"
          delegate_to: localhost

    - block:
        - name: Installer LibreOffice
          apt:
            name: libreoffice
            state: present

      rescue:
        - name: Log - échec installation LibreOffice
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | LibreOffice install failed"
          delegate_to: localhost

```

---

##### 7 ) Création du playbook Crontab.yaml
`user@serveur:~$ nano Crontab.yaml`

Contenu ***Crontab.yaml*** :
```
---
# Partie 1/1 : Ajout d'une tâche Cron
#
# S'exécute sur les PCs du groupe [UserAnsible]
#
# Ajoute un cron qui lance le playbook LancerDecrypter.yaml
# tous les jours à 08h00
#
# Les erreurs produites sont enregistrées
# dans le fichier ansibleFails.log

- name: Configuration du Cron
  hosts: localhost
  become: no

  tasks:

    - block:

        - name: Ajouter le cron de lancement de LancerDecrypter
          cron:
            name: "Lancement automatique LancerDecrypter"
            minute: "0"
            hour: "8"
            job: "/usr/bin/ansible-playbook -i /chemin/vers/Inventaire2.ini /chemin/vers/LancerDecrypter.yaml"

      rescue:

        - name: Log - échec ajout cron LancerDecrypter
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Cron LancerDecrypter failed"

- name: Relancer les PCs
  hosts: UserAnsible
  become: yes
  
  tasks:

    - block:
        - name: Relancer PC
          command: reboot
          async: 1
          poll: 0

      rescue:
        - name: Log erreur Relancer
          become: no
          lineinfile:
            path: /chemin/vers/ansibleFails.log
            create: yes
            line: "{{ lookup('pipe', 'TZ=Europe/Paris date +\"%Y-%m-%d %H:%M:%S\"') }} | {{ inventory_hostname }} | Relancer failed"
          delegate_to: localhost


```

---

### IV ) Scénario de mise en situation

##### 1 ) Démarrage manuel des postes clients

###### 

##### 2 ) Exécution des programmes
##### Sur la machine serveur
`user@serveur:~$ ./script.sh && ansible-playbook -i Inventaire1.ini CartesReseau.yaml && ansible-playbook -i Inventaire2.ini UserAnsible.yaml && ansible-playbook -i Inventaire2.ini InstallApps.yaml && ansible-playbook -i Inventaire2.ini Crontab.yaml`
