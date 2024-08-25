#!/bin/bash

if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

clear

installTheme(){
    cd /var/www/
    tar -cvf CBHostingThemebackup.tar.gz pterodactyl
    echo "Installing theme..."
    cd /var/www/pterodactyl
    rm -r CBHostingTheme
    git clone https://github.com/conbert11/CBHostingTheme.git
    cd CBHostingTheme
    rm /var/www/pterodactyl/resources/scripts/CBHostingTheme.css
    rm /var/www/pterodactyl/resources/scripts/index.tsx
    mv index.tsx /var/www/pterodactyl/resources/scripts/index.tsx
    mv CBHostingTheme.css /var/www/pterodactyl/resources/scripts/CBHostingTheme.css
    cd /var/www/pterodactyl


    echo -e "${BLUE}Install required Stuff...${RESET}"
    curl -fsSL https://fnm.vercel.app/install | bash - > /dev/null 2>&1
    source ~/.bashrc > /dev/null 2>&1
    fnm use --install-if-missing 22 > /dev/null 2>&1

    npm i -g yarn > /dev/null 2>&1
    yarn > /dev/null 2>&1


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
    exit
fi
