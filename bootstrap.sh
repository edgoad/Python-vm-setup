#!/usr/bin/env bash
set -e

# -----------------------------
# DevASC VM Bootstrap Script
# -----------------------------

# This script bootstraps a fresh Ubuntu system and applies
# the DevASC Ansible configuration.

# ---- Configuration ----
LAB_REPO_URL="https://github.com/edgoad/Python-vm-setup.git"
LAB_DIR="/opt/Python-vm-setup"

# ---- Sanity checks ----
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root (use sudo)"
  exit 1
fi

export ANSIBLE_COLLECTIONS_PATHS="/usr/share/ansible/collections"

echo "==> Updating package index"
apt update -y

echo "==> Installing base dependencies"
apt install -y \
  git \
  snapd \
  python3 \
  python3-pip \
  python3-venv \
  ansible

systemctl enable --now snapd

echo "==> Verifying Ansible installation"
ansible --version

# ---- Clone lab repository ----
if [[ ! -d "$LAB_DIR" ]]; then
  echo "==> Cloning DevASC lab repository"
  git clone "$LAB_REPO_URL" "$LAB_DIR"
else
  echo "==> DevASC lab repository already exists, skipping clone"
fi

cd "$LAB_DIR"

# ---- Install Ansible role dependencies ----
if [[ -f requirements.yml ]]; then
  echo "==> Installing Ansible roles from requirements.yml"
  ansible-galaxy collection install -r requirements.yml --force
  ansible-galaxy role install -r requirements.yml -p roles/ --force
else
  echo "ERROR: requirements.yml not found in lab repo"
  exit 1
fi

# ---- Run the playbook ----
echo "==> Running DevASC Ansible playbook"
ansible-playbook site.yml

echo "==> Bootstrap complete. DevASC lab is ready."