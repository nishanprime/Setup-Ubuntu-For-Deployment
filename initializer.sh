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

read -p "Enter the name of the runner group to add this runner to (default: maingroup): " RUNNER_GROUP
RUNNER_GROUP=${RUNNER_GROUP:-maingroup}


while [ -z "$RUNNER_NAME" ]; do
    read -p "Enter the GitHub Actions runner name (for example, my-runner): " RUNNER_NAME
    if [[ ! "$RUNNER_NAME" =~ ^ ]]; then
        echo "Invalid name. Please try again."
        RUNNER_NAME=""
    fi
done

read -p "Enter the GitHub Actions runner labels (comma-separated, default: self-hosted): " RUNNER_LABELS
RUNNER_LABELS=${RUNNER_LABELS:-self-hosted}
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

# Create a new user and set the password
sudo adduser --disabled-password --gecos "" $USERNAME
echo "$USERNAME:$PASSWORD" | sudo chpasswd
sudo usermod -aG sudo $USERNAME
sudo usermod -aG docker $USERNAME



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
export USER=$USERNAME
export WWW_FOLDER=$WWW_FOLDER

# Switch to the new user
su - $USERNAME <<EOF
cd /var/www
# Create the WWW_FOLDER with sudo and pipe password
echo "$PASSWORD" | sudo -S mkdir -p $WWW_FOLDER
echo "$PASSWORD" | sudo -S chown -R $USERNAME:$USERNAME $WWW_FOLDER

# Navigate to the created directory
cd $WWW_FOLDER

# Download the GitHub Actions runner with sudo
echo "$PASSWORD" | sudo -S curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

# Extract the runner package with sudo
echo "$PASSWORD" | sudo -S tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

# Change back to /var/www and set permissions
cd ..
echo "$PASSWORD" | sudo -S chmod -R 777 $WWW_FOLDER

# Navigate back to the WWW_FOLDER
cd $WWW_FOLDER

# Run the GitHub Actions runner configuration without sudo
./config.sh --url $REPO_URL --token $RUNNER_TOKEN

# Install and start the runner service with sudo
sudo -S ./svc.sh install
sudo -S ./svc.sh start
EOF

echo "Setup complete. Please check your GitHub repository settings for the runner status."
