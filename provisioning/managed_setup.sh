#!/bin/bash

# Update system
echo "Updating the system..."
sudo dnf update -y

# Install all nessesary packages
echo "Installing EPEL repository..."
sudo dnf install -y epel-release

echo "Installing sudo và OpenSSH Server..."
sudo dnf install -y sudo openssh-server

# Modify /etc/hosts
echo "Configuring /etc/hosts..."
sudo bash -c 'cat <<EOL >> /etc/hosts
192.168.99.99 controller
192.168.99.98 web1
192.168.99.97 db1
EOL'

# Config sudo passwordless for user ansible
echo "Creating user 'ansible' if it does not exist..."
if ! id -u ansible >/dev/null 2>&1; then
    sudo useradd ansible
    echo "ansible:ansible123" | sudo chpasswd
    sudo usermod -aG wheel ansible
fi

# Config sudo passwordless for user ansible
echo "Configuring passwordless sudo for user 'ansible'..."
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible

# Create .ssh for user ansible
echo "Creating .ssh directory for user 'ansible'..."
sudo -u ansible mkdir -p /home/ansible/.ssh
sudo chmod 700 /home/ansible/.ssh



# Modify parameters of SSH
echo "Configuring SSH settings..."
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

if [ $(hostname) != 'controller' ]; then
sshpass -p ansible123 ssh ansible@controller
sshpass -p ansible123 ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@web1
sshpass -p ansible123 ssh-copy-id -i ~/.ssh/id_rsa.pub ansible@db1
fi

# Restart SSH
echo "Restarting SSH service..."
sudo systemctl restart sshd


echo "Managed node setup completed successfully."