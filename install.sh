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

# Function to print debug information
debug_log() {
    local message=$1
    echo -e "${colors[YELLOW]}[DEBUG] ${message}${colors[RESET]}"
}

# Clean NodeJS installation
clean_nodejs() {
    print_message "YELLOW" "Cleaning existing NodeJS installation..."
    apt-get remove -y nodejs npm 
    apt-get purge -y nodejs npm 
    apt-get autoremove -y 
    rm -f /etc/apt/sources.list.d/nodesource.list 
    rm -f /etc/apt/sources.list.d/nodesource.list.save 
    apt-get clean 
    apt-get update 
}

# Install NodeJS 16
install_nodejs() {
    print_message "GREEN" "Installing NodeJS 16..."
    clean_nodejs
    
    debug_log "Installing curl..."
    apt-get install -y curl
    
    debug_log "Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    
    debug_log "Installing NodeJS 16..."
    apt-get install -y nodejs
    
    # Verify installation
    local node_version=$(node -v)
    debug_log "Installed NodeJS version: ${node_version}"
    
    if [[ $node_version != v16* ]]; then
        print_message "RED" "NodeJS installation verification failed"
        return 1
    fi
    
    print_message "GREEN" "NodeJS ${node_version} installed successfully"
    return 0
}

# Install theme function
install_theme() {
    if [[ $EUID -ne 0 ]]; then
        print_message "RED" "This script must be run as root"
        exit 1
    fi
    
    # Create backup
    print_message "GREEN" "Creating backup..."
    cd /var/www/
    tar -czf "pterodactyl_backup_$(date +%Y%m%d_%H%M%S).tar.gz" pterodactyl
    
    # Install NodeJS
    if ! install_nodejs; then
        print_message "RED" "NodeJS installation failed"
        exit 1
    fi
    
    debug_log "Installing build essentials..."
    apt-get install -y build-essential python3
    
    print_message "GREEN" "Installing theme..."
    cd /var/www/pterodactyl
    
    debug_log "Removing old theme if exists..."
    rm -rf CBHostingTheme
    
    debug_log "Cloning theme repository..."
    git clone https://github.com/conbert11/CBHostingTheme.git
    
    debug_log "Moving theme files..."
    cd CBHostingTheme
    cp -f index.tsx /var/www/pterodactyl/resources/scripts/
    cp -f CBHostingTheme.css /var/www/pterodactyl/resources/scripts/
    
    cd /var/www/pterodactyl
    
    debug_log "Installing npm..."
    apt-get install -y npm
    
    debug_log "Installing yarn..."
    npm install -g yarn
    
    debug_log "Clearing yarn cache..."
    yarn cache clean
    
    debug_log "Running yarn install..."
    yarn install --verbose
    
    debug_log "Building theme..."
    yarn build:production --verbose
    
    if [ $? -ne 0 ]; then
        print_message "RED" "Theme build failed. Check the logs above for errors."
        exit 1
    fi
    
    debug_log "Clearing Laravel cache..."
    php artisan optimize:clear
    
    print_message "GREEN" "Theme installation completed successfully!"
}

# Main menu
show_menu() {
    clear
    echo "Copyright (c) 2024 Conbert11"
    echo "This program is free software: you can redistribute it and/or modify"
    echo
    echo "Theme Installer Menu:"
    echo "1) Install theme (with debug output)"
    echo "2) Restore backup"
    echo "3) Exit"
    echo
}

# Main program
main() {
    while true; do
        show_menu
        read -p "Please enter your choice [1-3]: " choice
        
        case $choice in
            1) 
                read -p "Are you sure you want to install the theme? [y/N] " confirm
                [[ $confirm == [yY] ]] && install_theme
                ;;
            2)
                cd /var/www/
                latest_backup=$(ls -t pterodactyl_backup_*.tar.gz 2>/dev/null | head -1)
                if [ -z "$latest_backup" ]; then
                    print_message "RED" "No backup found!"
                else
                    tar -xzf "$latest_backup"
                    rm "$latest_backup"
                    cd /var/www/pterodactyl
                    yarn build:production
                    php artisan optimize:clear
                    print_message "GREEN" "Backup restored successfully!"
                fi
                ;;
            3) 
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
