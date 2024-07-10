#!/bin/bash
# chmod +x "$0"

# Prompt for user inputs
read -p "Enter the name of the user to create: " USERNAME
read -sp "Enter the password for the user: " PASSWORD
echo
read -p "Enter the Node version to install (e.g., 20.11.1): " NODE_VERSION
read -p "Enter the folder name inside /var/www: " WWW_FOLDER
read -p "Enter the GitHub repository URL: " REPO_URL
read -p "Enter the GitHub Actions runner token: " RUNNER_TOKEN
read -p "Enter the GitHub Actions runner version (e.g., 2.308.0): " RUNNER_VERSION
read -p "Enter the GitHub Actions runner name: " RUNNER_NAME
read -p "Enter the GitHub Actions runner labels (comma-separated): " RUNNER_LABELS
read -sp "Enter the sudo password for the new user: " SUDO_PASSWORD
echo

# Update package lists
sudo apt update

# Install Expect
sudo apt-get install -y expect

# Install NVM and Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install $NODE_VERSION
nvm use $NODE_VERSION
nvm alias default $NODE_VERSION

# Echo Node and NPM versions
echo "--- Node Version ---"
node -v
echo "--- NPM Version ---"
npm -v

# Install Nginx
sudo apt install -y nginx
sudo ufw allow 'Nginx HTTP'
sudo systemctl status nginx

# Install Docker and Docker Compose
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Echo Docker and Docker Compose versions
echo "--- Docker Version ---"
docker --version
echo "--- Docker Compose Version ---"
docker-compose --version

# Create a new user and add to necessary groups
sudo adduser --gecos "" $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $USERNAME
sudo usermod -aG docker $USERNAME

# Function to handle sudo with expect
expect_sudo() {
    expect -c "
    spawn $1
    expect \"password for\"
    send \"$SUDO_PASSWORD\r\"
    interact
    "
}

# Create the expect script to automate the GitHub Actions runner configuration
cat <<EOL > config.expect
#!/usr/bin/expect -f
set timeout -1
spawn ./config.sh --url $REPO_URL --token $RUNNER_TOKEN
expect "Enter name of runner: "
send "$RUNNER_NAME\r"
expect "Enter any additional labels (ex. label-1,label-2):"
send "$RUNNER_LABELS\r"
expect "Enter name of work folder:"
send "default\r"
expect eof
EOL
chmod +x config.expect

# Switch to the new user and set up the GitHub Actions runner
su - $USERNAME <<EOF
cd /var/www
mkdir -p $WWW_FOLDER
cd $WWW_FOLDER
sudo curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
sudo tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
cd ..
sudo chmod -R 777 /var/www/$WWW_FOLDER
cd /var/www/$WWW_FOLDER
../config.expect
$(expect_sudo "sudo ./svc.sh install")
$(expect_sudo "sudo ./svc.sh start")
EOF

echo "Setup complete. Please check your GitHub repository settings for the runner status."
