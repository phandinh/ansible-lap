#!/bin/bash

# Setting parameter
USER_NAME="ansible"
USER_PASSWORD="ansible123"
SSH_KEY_PATH="/home/$USER_NAME/.ssh"
MANAGED_HOSTS=("web1" "db1")
IP_HOSTS=("192.168.99.98" "192.168.99.97")
PORT_SSH=22


# Update system
echo "Updating the system..."
sudo dnf update -y

# Install all nessesary packages
echo "Installing EPEL repository..."
sudo dnf install -y epel-release

echo "Installing Ansible, OpenSSH Server, and sudo..."
sudo dnf install -y ansible openssh-server sudo

echo "Installing sshpass package"
sudo dnf install -y sshpass

echo "Installing netcat"
sudo dnf install netcat

# Modify /etc/hosts
echo "Configuring /etc/hosts..."
sudo bash -c 'cat <<EOL >> /etc/hosts
192.168.99.99 controller
192.168.99.98 web1
192.168.99.97 db1
EOL'

# Create ansible user nếu if it does not exist
echo "Creating user 'ansible' if it does not exist..."
if ! id -u $USER_NAME >/dev/null 2>&1; then
    sudo useradd $USER_NAME
    echo "$USER_NAME:$USER_PASSWORD" | sudo chpasswd
    sudo usermod -aG wheel $USER_NAME
fi


# Config sudo passwordless for user ansible
echo "Configuring passwordless sudo for user $USER_NAME..."
sudo bash -c "echo '$USER_NAME ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$USER_NAME"

# Create SSH key for user ansible if it does not exist
echo "Generating SSH key for user $USER_NAME if not exists..."
if [ ! -f "$SSH_KEY_PATH/id_rsa" ]; then
    echo "Tạo SSH key cho user $USER_NAME..."
    sudo -u $USER_NAME ssh-keygen -t rsa -b 2048 -N "" -f "$SSH_KEY_PATH/id_rsa"
fi

# Copying SSH public key to shared_keys directory
echo "Copying SSH public key to shared_keys directory..."
sudo -u $USER_NAME bash -c 'mkdir -p /home/ansible/shared_keys/ && cp /home/ansible/.ssh/id_rsa.pub /home/ansible/shared_keys/ansible_id_rsa.pub'

# Modify parameters of SSH 
echo "Configuring SSH settings..."
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Check if managed nodes exist or not
echo "Đang đợi các managed nodes sẵn sàng để sao chép SSH keys..."
for ip in "${IP_HOSTS[@]}"; do
    echo "Check connetion to $ip..."
    if [ $"nc -z $ip $PORT_SSH" ]; then
      echo "Connected to ($ip)..."
      # Use sshpass to copy SSH key to remote
      echo "Start to copy public key ($ip) ..."
      sshpass -p "$USER_PASSWORD" ssh-copy-id -o StrictHostKeyChecking=no -i "$SSH_KEY_PATH/id_rsa.pub" "$USER_NAME@$ip"
    fi
done
# Restart SSH
echo "Restarting SSH service..."
sudo systemctl restart sshd
echo "Controller setup completed successfully."