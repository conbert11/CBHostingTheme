#!/bin/bash

if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

clear

installTheme(){
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    RESET='\033[0m'

    echo -e "${BLUE}Installing ${YELLOW}sudo${BLUE} if not installed${RESET}"
    apt install sudo -y > /dev/null 2>&1
    cd /var/www/ > /dev/null 2>&1
    echo -e "${BLUE}Unpacking Theme...${RESET}"
    tar -cvf CBHostingTheme_Themebackup.tar.gz pterodactyl > /dev/null 2>&1
    echo -e "${BLUE}Installing Theme... ${RESET}"
    cd /var/www/pterodactyl > /dev/null 2>&1
    echo -e "${BLUE}Download the Theme...${RESET}"
    git clone https://github.com/conbert11/CBHostingTheme.git > /dev/null 2>&1
    cd xCBTheme > /dev/null 2>&1
    echo -e "${BLUE}Removing old Theme resources/themes if exist... ${RESET}"
    rm /var/www/pterodactyl/resources/scripts/CBHostingTheme.css > /dev/null 2>&1
    rm /var/www/pterodactyl/resources/scripts/index.tsx > /dev/null 2>&1
    rm -r xCBTheme > /dev/null 2>&1
    echo -e "${BLUE}Adjust CBHostingTheme panel...${RESET}"
    yarn build:production > /dev/null 2>&1
    sudo php artisan optimize:clear > /dev/null 2>&1
    mv index.tsx /var/www/pterodactyl/resources/scripts/index.tsx > /dev/null 2>&1
    mv xCBTheme.css /var/www/pterodactyl/resources/scripts/CBHostingTheme.css > /dev/null 2>&1
    cd /var/www/pterodactyl > /dev/null 2>&1


    echo -e "${BLUE}Install required Stuff...${RESET}"
    curl -fsSL https://fnm.vercel.app/install | bash - > /dev/null 2>&1
    source ~/.bashrc > /dev/null 2>&1
    fnm use --install-if-missing 16 > /dev/null 2>&1

    npm i -g yarn > /dev/null 2>&1
    yarn > /dev/null 2>&1

    cd /var/www/pterodactyl > /dev/null 2>&1
    bash <(curl https://raw.githubusercontent.com/conbert11/CBHostingTheme/main/install.sh)

}

installThemeQuestion(){
    while true; do
        read -p "Are you sure that you want to install the theme [y/n]? " yn
        case $yn in
            [Yy]* ) installTheme; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

repair(){
    bash <(curl https://raw.githubusercontent.com/conbert11/CBHostingTheme/main/repair.sh)
}

restoreBackUp(){
    echo "Restoring backup..."
    cd /var/www/
    tar -xvf CBHostingThemebackup.tar.gz
    rm CBHostingThemebackup.tar.gz

    cd /var/www/pterodactyl
    yarn build:production
    sudo php artisan optimize:clear
}
echo "Copyright (c) 2024 | Conbert11"
echo ""
echo "Discord: https://dc.cb11.xyz"
echo "Website: https://cb11.xyz"
echo ""
echo "[1] Install theme"
echo "[2] Restore backup"
echo "[3] Repair panel (use if you have an error in the theme installation)"
echo "[4] Exit"

read -p "Please enter a number: " choice
if [ $choice == "1" ]
    then
    installThemeQuestion
fi
if [ $choice == "2" ]
    then
    restoreBackUp
fi
if [ $choice == "3" ]
    then
    repair
fi
if [ $choice == "4" ]
    then
    clear
    echo "Bye!"
    exit
fi
