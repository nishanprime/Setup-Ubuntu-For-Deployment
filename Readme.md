# Setup Ubuntu for Deployment

This repository contains a script to set up an Ubuntu server for deployment with Node.js, Nginx, Docker, and GitHub Actions runner.

## Usage

To use this script, follow the instructions below:

### 1. Download and Execute the Script

Open your server terminal and use the following `curl` command to download the script

<!-- 1st step is to download the script -->
<!-- curl -L -o initializer.sh https://raw.githubusercontent.com/nishanprime/Setup-Ubuntu-For-Deployment/main/initializer.sh -->

```bash
curl -L -o initializer.sh https://raw.githubusercontent.com/nishanprime/Setup-Ubuntu-For-Deployment/main/initializer.sh
```

2. Make the Script Executable
Make the downloaded script executable:

```bash
chmod +x initializer.sh
```

3. Execute the Script
Run the script using the following command:

```bash
./initializer.sh
```


### 2. Follow the Prompts

The script will prompt you for the following details:

- **Username**: Enter the name of the user to create.
- **Password**: Enter the password for the new user.
- **Node.js Version**: Enter the Node.js version to install (e.g., 20.11.1).
- **Folder Name**: Enter the folder name inside `/var/www`.
- **GitHub Repository URL**: Enter the GitHub repository URL.
- **GitHub Actions Runner Token**: Enter the GitHub Actions runner token.
- **GitHub Actions Runner Version**: Enter the GitHub Actions runner version (e.g., 2.308.0).
- **GitHub Actions Runner Name**: Enter the name of the GitHub Actions runner.
- **GitHub Actions Runner Labels**: Enter the labels for the GitHub Actions runner (comma-separated).
- **Sudo Password**: Enter the sudo password for the new user.

### 3. Verify Setup

Once the script has completed, check your GitHub repository settings to verify that the runner is online and ready to use.

## Note

Ensure you have sudo privileges to run this script, as it will require root access to install software and configure the system.

This project is licensed under the MIT License - see the [License.md](License.md) file for details.