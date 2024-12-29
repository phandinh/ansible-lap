#!/bin/bash

USER_NAME="ansible"
USER_PASSWORD="ansible123"
SSH_KEY_PATH="/home/$USER_NAME/.ssh"
MANAGED_HOSTS=("web1" "db1")


# Update system
echo "Updating the system..."
sudo dnf update -y

# Install all nessesary packages
echo "Installing EPEL repository..."
sudo dnf install -y epel-release

echo "Installing sudo và OpenSSH Server..."
sudo dnf install -y sudo openssh-server

echo "Installing sshpass package"
sudo dnf install -y sshpass

# Modify /etc/hosts
echo "Configuring /etc/hosts..."
sudo bash -c 'cat <<EOL >> /etc/hosts
192.168.99.99 controller
192.168.99.98 web1
192.168.99.97 db1
EOL'

# Config sudo passwordless for user ansible
echo "Creating user 'ansible' if it does not exist..."
if ! id -u $USER_NAME >/dev/null 2>&1; then
    sudo useradd $USER_NAME
    echo "$USER_NAME:$USER_PASSWORD" | sudo chpasswd
    sudo usermod -aG wheel $USER_NAME
fi

# Config sudo passwordless for user ansible
echo "Configuring passwordless sudo for user 'ansible'..."
sudo bash -c "echo '$USER_NAME ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USER_NAME"

# Create .ssh for user ansible
echo "Creating .ssh directory for user 'ansible'..."
sudo -u  $USER_NAME mkdir -p $SSH_KEY_PATH
sudo chmod 700 $SSH_KEY_PATH



# Modify parameters of SSH
echo "Configuring SSH settings..."
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH
echo "Restarting SSH service..."
sudo systemctl restart sshd


echo "Managed node setup completed successfully."