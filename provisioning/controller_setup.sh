#!/bin/bash

# Update system
echo "Updating the system..."
sudo dnf update -y

# Install all nessesary packages
echo "Installing EPEL repository..."
sudo dnf install -y epel-release

echo "Installing Ansible, OpenSSH Server, and sudo..."
sudo dnf install -y ansible openssh-server sudo

# Modify /etc/hosts
echo "Configuring /etc/hosts..."
sudo bash -c 'cat <<EOL >> /etc/hosts
192.168.99.99 controller
192.168.99.98 web1
192.168.99.97 db1
EOL'

# Create ansible user nếu if it does not exist
echo "Creating user 'ansible' if it does not exist..."
if ! id -u ansible >/dev/null 2>&1; then
    sudo useradd ansible
    echo "ansible:ansible123" | sudo chpasswd
    sudo usermod -aG wheel ansible
fi

# Config sudo passwordless for user ansible
echo "Configuring passwordless sudo for user 'ansible'..."
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible

# Create SSH key for user ansible if it does not exist
echo "Generating SSH key for user 'ansible' if not exists..."
sudo -u ansible bash -c 'if [ ! -f /home/ansible/.ssh/id_rsa ]; then ssh-keygen -t rsa -b 2048 -N "" -f /home/ansible/.ssh/id_rsa; fi'

# Copying SSH public key to shared_keys directory
echo "Copying SSH public key to shared_keys directory..."
sudo -u ansible bash -c 'mkdir -p /home/ansible/shared_keys/ && cp /home/ansible/.ssh/id_rsa.pub /home/ansible/shared_keys/ansible_id_rsa.pub'

# Modify parameters of SSH 
echo "Configuring SSH settings..."
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH
echo "Restarting SSH service..."
sudo systemctl restart sshd

echo "Copy public key from controller to remote"
if [ $(hostname) = 'controller' ]; then
sshpass -p ansible123 ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@web1
sshpass -p ansible123 ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@db1
fi

echo "Controller setup completed successfully."