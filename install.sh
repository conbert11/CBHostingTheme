#!/bin/bash

# Define color codes
declare -A colors=(
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[1;33m'
    ["BLUE"]='\033[0;34m'
    ["MAGENTA"]='\033[0;35m'
    ["CYAN"]='\033[0;36m'
    ["RESET"]='\033[0m'
)

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${colors[$color]}${message}${colors[RESET]}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message "RED" "This script must be run as root"
        exit 1
    fi
}

# Function to execute commands with error handling
execute_command() {
    local command=$1
    local error_message=$2
    
    if ! eval "$command" > /dev/null 2>&1; then
        print_message "RED" "Error: $error_message"
        exit 1
    fi
}

# Create backup
create_backup() {
    print_message "GREEN" "Creating backup..."
    cd /var/www/ || exit 1
    execute_command "tar -czf pterodactyl_backup_$(date +%Y%m%d_%H%M%S).tar.gz pterodactyl" "Failed to create backup"
}

# Install required dependencies
install_dependencies() {
    print_message "GREEN" "Installing dependencies..."
    execute_command "apt update" "Failed to update package list"
    execute_command "apt install -y sudo git curl nodejs npm" "Failed to install dependencies"
}

# Install theme function
install_theme() {
    check_root
    create_backup
    install_dependencies

    print_message "GREEN" "Installing theme..."
    cd /var/www/pterodactyl || exit 1
    
    # Remove old theme if exists
    if [ -d "CBHostingTheme" ]; then
        execute_command "rm -rf CBHostingTheme" "Failed to remove old theme"
    fi

    # Clone new theme
    execute_command "git clone https://github.com/conbert11/CBHostingTheme.git" "Failed to clone theme repository"
    
    # Setup theme files
    cd CBHostingTheme || exit 1
    execute_command "mv index.tsx /var/www/pterodactyl/resources/scripts/" "Failed to move index.tsx"
    execute_command "mv CBHostingTheme.css /var/www/pterodactyl/resources/scripts/" "Failed to move CSS file"

    # Setup Node.js version
    REQUIRED_NODE_VERSION="16.20.2"
    CURRENT_NODE_VERSION=$(node -v)

    if [ "$CURRENT_NODE_VERSION" != "v$REQUIRED_NODE_VERSION" ]; then
        print_message "YELLOW" "Installing Node.js version $REQUIRED_NODE_VERSION..."
        execute_command "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash" "Failed to install NVM"
        source ~/.nvm/nvm.sh
        execute_command "nvm install $REQUIRED_NODE_VERSION" "Failed to install Node.js"
        execute_command "nvm use $REQUIRED_NODE_VERSION" "Failed to switch Node.js version"
    fi

    # Install and build
    cd /var/www/pterodactyl || exit 1
    execute_command "npm install -g yarn" "Failed to install Yarn"
    execute_command "yarn" "Failed to install dependencies"
    execute_command "yarn build:production" "Failed to build production"
    execute_command "php artisan optimize:clear" "Failed to clear cache"

    print_message "GREEN" "Theme installation completed successfully!"
}

# Restore backup function
restore_backup() {
    check_root
    print_message "GREEN" "Restoring backup..."
    
    local latest_backup=$(ls -t /var/www/pterodactyl_backup_*.tar.gz 2>/dev/null | head -1)
    if [ -z "$latest_backup" ]; then
        print_message "RED" "No backup file found!"
        exit 1
    fi

    cd /var/www/ || exit 1
    execute_command "tar -xzf $latest_backup" "Failed to restore backup"
    execute_command "rm $latest_backup" "Failed to clean up backup file"
    
    cd /var/www/pterodactyl || exit 1
    execute_command "yarn build:production" "Failed to rebuild panel"
    execute_command "php artisan optimize:clear" "Failed to clear cache"
    
    print_message "GREEN" "Backup restored successfully!"
}

# Repair function
repair_panel() {
    check_root
    print_message "GREEN" "Repairing panel..."
    execute_command "curl -s https://raw.githubusercontent.com/conbert11/CBHostingTheme/main/repair.sh | bash" "Failed to run repair script"
}

# Main menu
show_menu() {
    clear
    echo "Copyright (c) 2024 Angelillo15 and Conbert11"
    echo "This program is free software: you can redistribute it and/or modify"
    echo
    echo "Theme Installer Menu:"
    echo "1) Install theme"
    echo "2) Restore backup"
    echo "3) Repair panel"
    echo "4) Exit"
    echo
}

# Main program
main() {
    check_root
    
    while true; do
        show_menu
        read -p "Please enter your choice [1-4]: " choice
        
        case $choice in
            1) 
                read -p "Are you sure you want to install the theme? [y/N] " confirm
                [[ $confirm == [yY] ]] && install_theme
                ;;
            2) restore_backup ;;
            3) repair_panel ;;
            4) 
                print_message "GREEN" "Goodbye!"
                exit 0
                ;;
            *)
                print_message "RED" "Invalid option. Please try again."
                ;;
        esac
    done
}

# Start the program
main
