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
        return 1
    fi
    return 0
}

# Clean NodeJS installation
clean_nodejs() {
    print_message "YELLOW" "Cleaning existing NodeJS installation..."
    
    # Remove existing nodejs and npm
    apt-get remove -y nodejs npm &>/dev/null
    apt-get purge -y nodejs npm &>/dev/null
    apt-get autoremove -y &>/dev/null
    
    # Remove NodeSource repository if exists
    rm -f /etc/apt/sources.list.d/nodesource.list &>/dev/null
    rm -f /etc/apt/sources.list.d/nodesource.list.save &>/dev/null
    
    # Clear apt cache
    apt-get clean &>/dev/null
    apt-get update &>/dev/null
}

# Install NodeJS 16
install_nodejs() {
    print_message "GREEN" "Installing NodeJS 16..."
    
    # Clean existing installation
    clean_nodejs
    
    # Install curl if not present
    apt-get install -y curl &>/dev/null
    
    # Add NodeSource repository for Node.js 16
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash - &>/dev/null
    
    # Install Node.js 16
    if ! apt-get install -y nodejs=16.* &>/dev/null; then
        print_message "RED" "Failed to install NodeJS 16"
        return 1
    fi
    
    # Verify installation
    local node_version=$(node -v)
    if [[ $node_version != v16* ]]; then
        print_message "RED" "NodeJS installation verification failed"
        return 1
    fi
    
    print_message "GREEN" "NodeJS ${node_version} installed successfully"
    return 0
}

# Install Yarn
install_yarn() {
    print_message "GREEN" "Installing Yarn..."
    
    # Remove existing yarn if present
    npm uninstall -g yarn &>/dev/null
    
    # Install yarn globally
    if ! npm install -g yarn &>/dev/null; then
        print_message "RED" "Failed to install Yarn"
        return 1
    fi
    
    print_message "GREEN" "Yarn installed successfully"
    return 0
}

# Create backup
create_backup() {
    print_message "GREEN" "Creating backup..."
    cd /var/www/ || exit 1
    local backup_file="pterodactyl_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    if ! tar -czf "$backup_file" pterodactyl &>/dev/null; then
        print_message "RED" "Failed to create backup"
        return 1
    fi
    print_message "GREEN" "Backup created: $backup_file"
    return 0
}

# Install theme function
install_theme() {
    check_root
    
    # Create backup first
    if ! create_backup; then
        print_message "RED" "Backup creation failed, aborting installation"
        exit 1
    fi
    
    # Install NodeJS
    if ! install_nodejs; then
        print_message "RED" "NodeJS installation failed, aborting installation"
        exit 1
    fi
    
    # Install Yarn
    if ! install_yarn; then
        print_message "RED" "Yarn installation failed, aborting installation"
        exit 1
    }
    
    print_message "GREEN" "Installing theme..."
    cd /var/www/pterodactyl || exit 1
    
    # Remove old theme if exists
    if [ -d "CBHostingTheme" ]; then
        rm -rf CBHostingTheme
    fi

    # Clone theme repository
    if ! git clone https://github.com/conbert11/CBHostingTheme.git &>/dev/null; then
        print_message "RED" "Failed to clone theme repository"
        exit 1
    fi
    
    # Move theme files
    cd CBHostingTheme || exit 1
    mv index.tsx /var/www/pterodactyl/resources/scripts/ &>/dev/null
    mv CBHostingTheme.css /var/www/pterodactyl/resources/scripts/ &>/dev/null
    
    # Build theme
    cd /var/www/pterodactyl || exit 1
    if ! yarn &>/dev/null; then
        print_message "RED" "Failed to install dependencies"
        exit 1
    fi
    
    if ! yarn build:production &>/dev/null; then
        print_message "RED" "Failed to build theme"
        exit 1
    fi
    
    if ! php artisan optimize:clear &>/dev/null; then
        print_message "RED" "Failed to clear cache"
        exit 1
    fi
    
    print_message "GREEN" "Theme installation completed successfully!"
}

# Restore backup function
restore_backup() {
    check_root
    print_message "GREEN" "Restoring backup..."
    
    cd /var/www/ || exit 1
    local latest_backup=$(ls -t pterodactyl_backup_*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        print_message "RED" "No backup file found!"
        exit 1
    }
    
    if ! tar -xzf "$latest_backup" &>/dev/null; then
        print_message "RED" "Failed to restore backup"
        exit 1
    }
    
    rm "$latest_backup" &>/dev/null
    
    cd /var/www/pterodactyl || exit 1
    if ! yarn build:production &>/dev/null; then
        print_message "RED" "Failed to rebuild panel"
        exit 1
    }
    
    if ! php artisan optimize:clear &>/dev/null; then
        print_message "RED" "Failed to clear cache"
        exit 1
    }
    
    print_message "GREEN" "Backup restored successfully!"
}

# Repair function
repair_panel() {
    check_root
    print_message "GREEN" "Repairing panel..."
    
    if ! curl -s https://raw.githubusercontent.com/conbert11/CBHostingTheme/main/repair.sh | bash &>/dev/null; then
        print_message "RED" "Failed to run repair script"
        exit 1
    }
    
    print_message "GREEN" "Panel repair completed!"
}

# Main menu
show_menu() {
    clear
    echo "Copyright (c) 2024 Conbert11"
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
