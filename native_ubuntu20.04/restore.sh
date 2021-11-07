#!/bin/bash

scripts_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
backups_path=$scripts_path/backups
source $scripts_path/commons.sh

home=$HOME
user=$USER

remove_and_ask_password

crear_directorio_si_no_existe() {

    if test -d $1; then

        print_text "el directorio $1 ya existe"

    else

        print_text "el directorio $1 no existe"
        print_text "creando el directorio $1"

        mkdir -p $1

    fi
}

sustituir_revisando_origen_y_destino() {

    ruta_origen=$1
    ruta_destino=$2

    crear_directorio_si_no_existe $ruta_destino

    if test -f $ruta_origen; then

        print_text "la ruta $ruta_origen es de un archivo"
        print_text "copiando el archivo de la ruta $ruta_origen a la ruta $ruta_destino"

        cp -r -f $ruta_origen $ruta_destino

    elif test -d $ruta_origen; then

        print_text "la ruta $ruta_origen es de un directorio"
        print_text "copiando el contenido de la ruta $ruta_origen a la ruta $ruta_destino"

        cp -r -f $ruta_origen/* $ruta_destino

    else

        print_text "la ruta de origen $ruta_origen no existe"

    fi

}

print_title "Iniciando Restauración De Configuraciones Personalizadas"

print_title "1/10 - Descomprimiendo Directorio De Respaldos"

cd $scripts_path

if test -f backups.tar.gz; then

    print_text "respaldo encontrado"

    tar xzf backups.tar.gz backups

else

    print_text "respaldo no encontrado, abortando restauración"
    print_title "Restauraciones De Configuraciones Personalizadas Abortada"

    exit 1
    
fi

print_title "2/10 - Restaurando Configuraciones Del Indicador Del Sistema"

ruta_backup_widgets=$backups_path/widgets/.indicator-sysmonitor.json
ruta_origen_widgets=$home
sustituir_revisando_origen_y_destino $ruta_backup_widgets $ruta_origen_widgets

print_title "3/10 - Restaurando Configuraciones De Fuentes Personalizadas"

ruta_backup_fuentes=$backups_path/fuentes
ruta_origen_fuentes=$home/.fonts
sustituir_revisando_origen_y_destino $ruta_backup_fuentes $ruta_origen_fuentes

print_title "4/10 - Restaurando Configuraciones De Terminal"

ruta_terminal=$backups_path/terminal
archivo_terminal=$ruta_terminal/gnome-terminal.dconf
dconf load /org/gnome/terminal/legacy/profiles:/ <$archivo_terminal

print_title "5/10 - Restaurando Configuraciones De Tilix"

ruta_tilix=$backups_path/tilix
archivo_tilix=$ruta_tilix/tilix.dconf
dconf load /com/gexperts/Tilix/ <$archivo_tilix
sudo update-alternatives --set x-terminal-emulator /usr/bin/tilix.wrapper

print_title "6/10 - Restaurando Configuraciones De Iconos De Snap"

ruta_backup_snap=$backups_path/snap
ruta_origen_snap=/var/lib/snapd/desktop/applications/
sudo find $ruta_origen_snap -type f -exec chmod 777 {} \;
sleep 2
sustituir_revisando_origen_y_destino $ruta_backup_snap $ruta_origen_snap
sleep 2
sudo find $ruta_origen_snap -type f -exec chmod 755 {} \;

print_title "7/10 - Restaurando Configuraciones De Zsh Y P10k"

ruta_backup_zsh_1=$backups_path/zsh/.p10k.zsh
ruta_backup_zsh_2=$backups_path/zsh/.zshrc
rute_origen_zsh=$home
sustituir_revisando_origen_y_destino $ruta_backup_zsh_1 $rute_origen_zsh
sustituir_revisando_origen_y_destino $ruta_backup_zsh_2 $rute_origen_zsh

print_title "8/10 - Restaurando Configuraciones De Iconos Con Numix"

gsettings set org.gnome.desktop.interface icon-theme 'Numix-Circle'

print_title "9/10 - Restaurando Configuraciones De Docker Engine"

if grep -q docker /etc/group; then

    print_text "el grupo docker ya existe, no hace falta hacer más cambios"

else

    print_text "el grupo docker no existe, creando grupo docker"

    sudo addgroup --system docker

fi

if getent group docker | grep -q "\b$user\b"; then

    print_text "el usuario $user ya pertenece al grupo docker, no hace falta hacer más cambios"

else

    print_text "el usuario $user no pertenece aún al grupo docker, agregando $user al grupo docker"

    sudo adduser $user docker

fi

print_title "10/10 - Eliminando Directorio De Respaldos"

rm -r backups
print_text "directorio de respaldos removido"


print_title "Restauraciones De Configuraciones Personalizadas Finalizadas"
