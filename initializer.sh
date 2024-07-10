#!/bin/bash
# chmod +x "$0"

# Prompt for user inputs
read -p "Enter the name of the user to create: " USERNAME
read -s -p "Enter the password for the user: " PASSWORD
echo
read -s -p "Confirm the password: " PASSWORD_CONFIRM
while [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; do
    echo
    echo "Passwords do not match. Please try again."
    read -s -p "Enter the password for the user: " PASSWORD
    read -s -p "Confirm the password: " PASSWORD_CONFIRM
done
echo

# Set default values if not provided
read -p "Enter the Node version to install (default: 20.11.1): " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-20.11.1}

read -p "Enter the folder name inside /var/www (default: mywebsite): " WWW_FOLDER
WWW_FOLDER=${WWW_FOLDER:-mywebsite}

while [ -z "$REPO_URL" ]; do
    read -p "Enter the GitHub repository URL: " REPO_URL
    if [[ ! "$REPO_URL" =~ ^ ]]; then
        echo "Invalid URL. Please try again."
        REPO_URL=""
    fi
done

while [ -z "$RUNNER_TOKEN" ]; do
    read -p "Enter the GitHub Actions runner token: " RUNNER_TOKEN
    if [[ ! "$RUNNER_TOKEN" =~ ^[0-9a-zA-Z]+$ ]]; then
        echo "Invalid token. Please try again."
        RUNNER_TOKEN=""
    fi
done

read -p "Enter the GitHub Actions runner version (default: 2.317.0): " RUNNER_VERSION
RUNNER_VERSION=${RUNNER_VERSION:-2.317.0}

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

# Create a new user and set the password
sudo adduser --disabled-password --gecos "" $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $USERNAME
sudo usermod -aG docker $USERNAME

# Create necessary directories and set permissions
sudo mkdir -p /var/www/$WWW_FOLDER
sudo chown -R $USERNAME:$USERNAME /var/www/$WWW_FOLDER
sudo chmod -R 777 /var/www/$WWW_FOLDER

# Download and extract the GitHub Actions runner
sudo -u $USERNAME bash <<EOF
cd /var/www/$WWW_FOLDER
curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz
EOF

# Instructions for the user to complete the setup manually
cat <<EOL
================================================================================
                   GitHub Actions Runner Configuration                          
================================================================================

Please complete the GitHub Actions runner configuration manually.

Note: Your password is: $PASSWORD for the user: $USERNAME
You will be prompted to enter the password during the configuration process.

1. Switch to the user:
--------------------------------------------------------------------------------
\033[31m   su - $USERNAME \033[0m
--------------------------------------------------------------------------------

2. Navigate to the correct directory:
--------------------------------------------------------------------------------
\033[31m   cd /var/www/$WWW_FOLDER \033[0m
--------------------------------------------------------------------------------

3. Run the following command to configure the runner:
--------------------------------------------------------------------------------
\033[31m   ./config.sh --url $REPO_URL --token $RUNNER_TOKEN \033[0m
--------------------------------------------------------------------------------

4. After completing the configuration, install and start the runner service:
--------------------------------------------------------------------------------
\033[31m   sudo ./svc.sh install \033[0m
\033[31m   sudo ./svc.sh start \033[0m
--------------------------------------------------------------------------------

================================================================================
EOL

echo "Please complete the above steps manually and you're all set!"

EOL

echo "Please complete the above steps manually and you're all set!"
