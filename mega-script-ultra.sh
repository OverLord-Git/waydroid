#!/bin/bash

Mega-Script supremo para instalar Waydroid en múltiples distribuciones %HEADING%mega-script-supremo-para-instalar-waydroid-en-múltiples-distribuciones%HEADING%

Verificado al 11 de octubre de 2025, 20:37 AST %HEADING%verificado-al-11-de-octubre-de-2025-2037-ast%HEADING%

Integra: supechicken (Android TV/ChromeOS), n1lby73 (universal), waydroid-package-manager (APKs), Quackdoc (GPU/spoof), WayBak (backups), Droid-NDK-Extractor (ARM), scrcpy (control remoto), DKMS (módulos dinámicos) %HEADING%integra-supechicken-android-tvchromeos-n1lby73-universal-waydroid-package-manager-apks-quackdoc-gpuspoof-waybak-backups-droid-ndk-extractor-arm-scrcpy-control-remoto-dkms-módulos-dinámicos%HEADING%

Mejoras: Crosh automatizado, Widevine/VA-API check, Flatpak/Snap, pv, limpieza, README dinámico, soporte musl en Alpine %HEADING%mejoras-crosh-automatizado-widevineva-api-check-flatpaksnap-pv-limpieza-readme-dinámico-soporte-musl-en-alpine%HEADING%

Uso: sudo bash mega_waydroid_installer_supreme.sh %HEADING%uso-sudo-bash-mega_waydroid_installer_supreme-sh%HEADING%

Advertencia: Ejecuta bajo tu propio riesgo; revisa https://docs.waydro.id %HEADING%advertencia-ejecuta-bajo-tu-propio-riesgo-revisa-httpsdocs-waydro-id%HEADING%

Configuración de logging %HEADING%configuración-de-logging%HEADING%

LOG_FILE="/var/log/waydroid_install.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1
echo "Inicio de instalación: $(date)" | tee -a "$LOG_FILE"

Función para manejar errores %HEADING%función-para-manejar-errores%HEADING%

function handle_error() {
echo "Error: $1. Revisa $LOG_FILE para detalles." | tee -a "$LOG_FILE" >&2
exit 1
}

Pre-chequeos de requisitos %HEADING%pre-chequeos-de-requisitos%HEADING%

function pre_checks() {
echo "Verificando requisitos..." | tee -a "$LOG_FILE"
FREE_SPACE=$(df -h / | awk 'NR==2 {print $4}' | grep -o '[0-9.]*')
if (( $(echo "$FREE_SPACE < 10" | bc -l) )); then
handle_error "Espacio en disco insuficiente (<10GB)."
fi
if ! lsmod | grep -q binder_linux; then
echo "Advertencia: Módulo binder_linux no cargado. Intentando DKMS..." | tee -a "$LOG_FILE"
install_dkms_binder
fi
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
echo "Advertencia: Ni Wayland ni X11 detectados. Configurando X11 fallback..." | tee -a "$LOG_FILE"
FALLBACK_X11=1
fi
}

Función para instalar binder_linux via DKMS %HEADING%función-para-instalar-binder_linux-via-dkms%HEADING%

function install_dkms_binder() {
echo "Intentando instalar binder_linux via DKMS..." | tee -a "$LOG_FILE"
if command -v dkms &>/dev/null; then
git clone https://github.com/choff/anbox-modules.git /tmp/anbox-modules || handle_error "Falló clon de anbox-modules."
cd /tmp/anbox-modules || handle_error "Falló cambio de directorio."
sudo ./INSTALL.sh || echo "Advertencia: Falló instalación DKMS. Kernel custom puede ser necesario." | tee -a "$LOG_FILE"
sudo modprobe binder_linux || echo "Advertencia: No se pudo cargar binder_linux." | tee -a "$LOG_FILE"
else
echo "DKMS no disponible. Instala dkms o recompila el kernel con CONFIG_ANDROID_BINDER_IPC." | tee -a "$LOG_FILE"
fi
}

Detección de distribución %HEADING%detección-de-distribución%HEADING%

if [ -f /etc/os-release ]; then
DISTRO=$(grep -m1 '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
DISTRO_LIKE=$(grep -m1 '^ID_LIKE=' /etc/os-release | cut -d'=' -f2 | tr -d '"' | awk '{print $1}')
if [ -z "$DISTRO" ]; then DISTRO="unknown"; fi
else
DISTRO="unknown"
fi
if [ -f /etc/chromeos-version ]; then
DISTRO="chromeos"
fi
echo "Distribución detectada: $DISTRO (parecida a: $DISTRO_LIKE)." | tee -a "$LOG_FILE"
case "$DISTRO" in
ubuntu|debian|zorin) SUGGESTED_OPT="Ubuntu/Debian" ;;
arch|endeavour|manjaro) SUGGESTED_OPT="Arch Linux" ;;
opensuse*) SUGGESTED_OPT="openSUSE" ;;
nixos) SUGGESTED_OPT="NixOS" ;;
gentoo) SUGGESTED_OPT="Gentoo" ;;
steamos) SUGGESTED_OPT="SteamOS (Steam Deck)" ;;
chromeos|crostini) SUGGESTED_OPT="ChromeOS (Crostini/Flex)" ;;
void) SUGGESTED_OPT="Void Linux" ;;
kiss) SUGGESTED_OPT="KISS Linux" ;;
fedora|silverblue) SUGGESTED_OPT="Fedora (Silverblue)" ;;
alpine) SUGGESTED_OPT="Alpine Linux" ;;
*) if grep -q Microsoft /proc/version 2>/dev/null; then SUGGESTED_OPT="WSL2 (Windows)"; else SUGGESTED_OPT="Universal Fallback (n1lby73)"; fi ;;
esac
if [ "$SUGGESTED_OPT" != "none" ]; then
echo "Recomendado: $SUGGESTED_OPT" | tee -a "$LOG_FILE"
read -p "¿Usar la sugerencia? (s/n): " use_suggested
if [[ "$use_suggested" == "s" || "$use_suggested" == "S" ]]; then
SELECTED_OPT="$SUGGESTED_OPT"
fi
fi

Mostrar detalles del equipo %HEADING%mostrar-detalles-del-equipo%HEADING%

echo "Detalles del equipo al iniciar (11/10/2025 20:37 AST):" | tee -a "$LOG_FILE"
echo "------------------------------------------------" | tee -a "$LOG_FILE"
echo "Sistema Operativo: $(uname -s) $(uname -r) $(uname -m)" | tee -a "$LOG_FILE"
echo "CPU: $(lscpu | grep "Model name" | awk -F: '{print $2}' | xargs)" | tee -a "$LOG_FILE"
echo "RAM Total: $(free -h | grep "Mem:" | awk '{print $2}')" | tee -a "$LOG_FILE"
echo "Espacio en Disco: $(df -h / | awk 'NR==2 {print $4}') libre" | tee -a "$LOG_FILE"
echo "Virtualización: $(if grep -q "/lxc" /proc/self/cgroup 2>/dev/null; then echo "Sí (VM/LXC)"; else echo "No"; fi)" | tee -a "$LOG_FILE"
echo "WSL2 detectado: $(if grep -q Microsoft /proc/version 2>/dev/null; then echo "Sí"; else echo "No"; fi)" | tee -a "$LOG_FILE"
echo "ChromeOS/Crostini detectado: $(if [ -f /etc/chromeos-version ]; then echo "Sí"; else echo "No"; fi)" | tee -a "$LOG_FILE"
if [[ "$DISTRO" == "alpine" ]]; then
echo "libc detectada: $(if ldd --version 2>&1 | grep -q musl; then echo "musl"; else echo "glibc u otra"; fi)" | tee -a "$LOG_FILE"
fi
echo "------------------------------------------------" | tee -a "$LOG_FILE"

Ejecutar pre-chequeos %HEADING%ejecutar-pre-chequeos%HEADING%

pre_checks

Menú principal con dialog o select %HEADING%menú-principal-con-dialog-o-select%HEADING%

if command -v dialog &>/dev/null; then
exec 3>&1
opt=$(dialog --menu "Selecciona tu distribución o acción:" 16 60 12 
1 "Ubuntu/Debian" 
2 "Arch Linux" 
3 "SteamOS (Steam Deck)" 
4 "WSL2 (Windows)" 
5 "Install Waydroid Script (casualsnek)" 
6 "Setup Full Desktop in WSL2 (tdcosta100)" 
7 "openSUSE" 
8 "NixOS" 
9 "Gentoo" 
10 "ChromeOS (Crostini/Flex)" 
11 "Universal Fallback (n1lby73)" 
12 "Void Linux" 
13 "KISS Linux" 
14 "Fedora (Silverblue)" 
15 "Alpine Linux" 
16 "Salir" 2>&1 1>&3)
exec 3>&-
case $opt in
1) opt="Ubuntu/Debian" ;;
2) opt="Arch Linux" ;;
3) opt="SteamOS (Steam Deck)" ;;
4) opt="WSL2 (Windows)" ;;
5) opt="Install Waydroid Script (casualsnek)" ;;
6) opt="Setup Full Desktop in WSL2 (tdcosta100)" ;;
7) opt="openSUSE" ;;
8) opt="NixOS" ;;
9) opt="Gentoo" ;;
10) opt="ChromeOS (Crostini/Flex)" ;;
11) opt="Universal Fallback (n1lby73)" ;;
12) opt="Void Linux" ;;
13) opt="KISS Linux" ;;
14) opt="Fedora (Silverblue)" ;;
15) opt="Alpine Linux" ;;
16) opt="Salir" ;;
esac
else
echo "Bienvenido al mega-instalador supremo de Waydroid." | tee -a "$LOG_FILE"
options=("Ubuntu/Debian" "Arch Linux" "SteamOS (Steam Deck)" "WSL2 (Windows)" "Install Waydroid Script (casualsnek)" "Setup Full Desktop in WSL2 (tdcosta100)" "openSUSE" "NixOS" "Gentoo" "ChromeOS (Crostini/Flex)" "Universal Fallback (n1lby73)" "Void Linux" "KISS Linux" "Fedora (Silverblue)" "Alpine Linux" "Salir")
select opt in "${options[@]}"; do
break
done
fi

Si se usó sugerencia, overridea la selección %HEADING%si-se-usó-sugerencia-overridea-la-selección%HEADING%

if [ -n "$SELECTED_OPT" ]; then
opt="$SELECTED_OPT"
fi

Submenú post-instalación %HEADING%submenú-post-instalación%HEADING%

function post_install_menu() {
echo "Post-instalación: ¿Qué joya deseas agregar?" | tee -a "$LOG_FILE"
if command -v dialog &>/dev/null; then
exec 3>&1
post_choice=$(dialog --menu "Opciones post-instalación:" 18 60 8 
1 "Package Manager (APKs/F-Droid)" 
2 "Tweaks Quackdoc (GPU/Spoof)" 
3 "Backup Waydroid (WayBak)" 
4 "ARM Translation (Droid-NDK-Extractor)" 
5 "Android TV Build (supechicken)" 
6 "Control Remoto (scrcpy)" 
7 "Limpiar imágenes descargadas" 
8 "Salir" 2>&1 1>&3)
exec 3>&-
else
echo "1: Package Manager (APKs/F-Droid), 2: Tweaks Quackdoc (GPU/Spoof), 3: Backup Waydroid (WayBak), 4: ARM Translation (Droid-NDK-Extractor), 5: Android TV Build (supechicken), 6: Control Remoto (scrcpy), 7: Limpiar imágenes descargadas, 8: Salir" | tee -a "$LOG_FILE"
read post_choice
fi
case $post_choice in
1)
echo "Instalando Waydroid Package Manager..." | tee -a "$LOG_FILE"
echo "Créditos: waydroid/waydroid-package-manager (https://github.com/waydroid/waydroid-package-manager)"
git clone https://github.com/waydroid/waydroid-package-manager || handle_error "Falló el clon."
cd waydroid-package-manager || handle_error "Falló el cambio de directorio."
chmod +x wpm
if [[ "$DISTRO" == "alpine" ]] && ldd --version 2>&1 | grep -q musl; then
sudo apk add gcompat || handle_error "Falló la instalación de gcompat."
echo "gcompat instalado para compatibilidad con glibc en musl." | tee -a "$LOG_FILE"
fi
echo "Instalado. Uso: ./wpm install  o ./wpm apkinstall <path/to/apk>." | tee -a "$LOG_FILE"
;;
2)
echo "Aplicando tweaks de Quackdoc..." | tee -a "$LOG_FILE"
echo "Créditos: Quackdoc (https://github.com/Quackdoc/waydroid-scripts)"
curl -O https://raw.githubusercontent.com/Quackdoc/waydroid-scripts/main/waydroid-choose-gpu.sh || handle_error "Falló la descarga de GPU script."
chmod +x waydroid-choose-gpu.sh
./waydroid-choose-gpu.sh || handle_error "Falló el tweak GPU."
echo "¿Aplicar spoof-device (Pixel 5 emulation)? (s/n)" | tee -a "$LOG_FILE"
read spoof_choice
if [[ "$spoof_choice" == "s" || "$spoof_choice" == "S" ]]; then
curl -O https://raw.githubusercontent.com/Quackdoc/waydroid-scripts/main/spoof-device.sh || handle_error "Falló la descarga de spoof script."
chmod +x spoof-device.sh
./spoof-device.sh || handle_error "Falló el spoof."
fi
echo "Tweaks aplicados. Reinicia Waydroid." | tee -a "$LOG_FILE"
;;
3)
echo "Configurando backup con WayBak..." | tee -a "$LOG_FILE"
echo "Créditos: WayBak (https://github.com/waydro/waybak)"
git clone https://github.com/waydro/waybak || handle_error "Falló el clon de WayBak."
cd waybak || handle_error "Falló el cambio de directorio."
chmod +x waybak
./waybak backup /var/lib/waydroid || handle_error "Falló el backup."
echo "Backup creado en /var/lib/waydroid/backup. Usa './waybak restore' para restaurar." | tee -a "$LOG_FILE"
;;
4)
echo "Configurando ARM translation con Droid-NDK-Extractor..." | tee -a "$LOG_FILE"
echo "Créditos: sickcodes (https://github.com/sickcodes/Droid-NDK-Extractor)"
git clone https://github.com/sickcodes/Droid-NDK-Extractor || handle_error "Falló el clon."
cd Droid-NDK-Extractor || handle_error "Falló el cambio de directorio."
chmod +x extract-libndk.sh
if [[ "$DISTRO" == "alpine" ]] && ldd --version 2>&1 | grep -q musl; then
sudo apk add gcompat || handle_error "Falló la instalación de gcompat."
echo "gcompat instalado para compatibilidad con glibc en musl." | tee -a "$LOG_FILE"
fi
./extract-libndk.sh || handle_error "Falló la extracción de libndk."
echo "ARM translation configurada. Reinicia Waydroid." | tee -a "$LOG_FILE"
;;
5)
echo "Instalando Android TV Build..." | tee -a "$LOG_FILE"
echo "Créditos: supechicken (https://github.com/supechicken/waydroid-androidtv-build)"
if command -v pv &>/dev/null; then
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
else
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
fi
unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
sudo waydroid upgrade -o -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló upgrade TV."
echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
if waydroid prop get ro.widevine | grep -q "L3"; then
echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
else
echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
fi
if command -v vainfo &>/dev/null; then
vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
else
echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
fi
echo "Build TV integrado. Reinicia con 'waydroid session start' para TV UI." | tee -a "$LOG_FILE"
;;
6)
echo "Instalando scrcpy para control remoto..." | tee -a "$LOG_FILE"
echo "Créditos: Genymobile (https://github.com/Genymobile/scrcpy)"
if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
sudo apt install -y scrcpy || handle_error "Falló instalación de scrcpy."
elif [[ "$DISTRO" == "arch" || "$DISTRO" == "endeavour" || "$DISTRO" == "manjaro" ]]; then
sudo pacman -S --needed scrcpy || handle_error "Falló instalación de scrcpy."
elif [[ "$DISTRO" == "fedora" ]]; then
sudo dnf install -y scrcpy || handle_error "Falló instalación de scrcpy."
elif [[ "$DISTRO" == "alpine" ]]; then
sudo apk add scrcpy || handle_error "Falló instalación de scrcpy."
sudo apk add gcompat || handle_error "Falló instalación de gcompat."
echo "gcompat instalado para compatibilidad con glibc en musl." | tee -a "$LOG_FILE"
elif command -v flatpak &>/dev/null; then
flatpak install -y flathub com.genymobile.scrcpy || handle_error "Falló instalación via Flatpak."
else
echo "scrcpy no disponible en este sistema. Instala manualmente." | tee -a "$LOG_FILE"
fi
echo "scrcpy instalado. Usa 'scrcpy' para controlar Waydroid desde PC/teléfono (ADB debe estar activo)." | tee -a "$LOG_FILE"
;;
7)
echo "Limpiando imágenes descargadas..." | tee -a "$LOG_FILE"
rm -f ~/system-tv13.img ~/vendor-tv13.img ~/system-tv13.img.xz ~/vendor-tv13.img.xz ~/bzImage || echo "No se encontraron imágenes para limpiar." | tee -a "$LOG_FILE"
echo "Imágenes limpiadas." | tee -a "$LOG_FILE"
;;
*) echo "Saliendo de post-instalación." | tee -a "$LOG_FILE" ;;
esac
}

Menú principal %HEADING%menú-principal%HEADING%

case $opt in
"Ubuntu/Debian")
echo "Instalando Waydroid en Ubuntu/Debian..." | tee -a "$LOG_FILE"
echo "Créditos: Waydroid Team (https://docs.waydro.id/usage/install-on-desktops)"
sudo apt update || handle_error "Falló la actualización de paquetes."
sudo apt install -y curl ca-certificates software-properties-common build-essential || handle_error "Falló la instalación de dependencias."
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils || handle_error "Falló la instalación de paquetes de virtualización."
if virsh list &>/dev/null; then
echo "Entorno virtual detectado. Configurando libvirt..." | tee -a "$LOG_FILE"
sudo virsh net-start default || sudo virsh net-define /usr/share/libvirt/networks/default.xml || handle_error "Falló la configuración de red libvirt."
fi
curl -s https://repo.waydro.id | sudo bash || handle_error "Falló la adición del repositorio Waydroid."
if ! sudo apt install -y waydroid; then
echo "Falló instalación via apt. Intentando Flatpak..." | tee -a "$LOG_FILE"
if command -v flatpak &>/dev/null; then
flatpak install -y flathub id.waydro.Waydroid || handle_error "Falló instalación via Flatpak."
else
handle_error "Ni apt ni Flatpak disponibles."
fi
fi
echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
read tv_mode
if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
if command -v pv &>/dev/null; then
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
else
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
fi
unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
if waydroid prop get ro.widevine | grep -q "L3"; then
echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
else
echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
fi
if command -v vainfo &>/dev/null; then
vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
else
echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
fi
echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
else
echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
read android_version
if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
else
sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
fi
fi
if command -v systemctl &>/dev/null; then
sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
fi
if [ -n "$FALLBACK_X11" ]; then
sudo apt install -y weston || handle_error "Falló la instalación de Weston."
weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
fi
echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
post_install_menu
;;

 
"Arch Linux")
    echo "Instalando Waydroid en Arch Linux..." | tee -a "$LOG_FILE"
    echo "Créditos: iEscapedVim (https://github.com/iEscapedVim/Waydroid-Installer)"
    sudo pacman -Syu --needed git base-devel linux-headers || handle_error "Falló la actualización e instalación de dependencias."
    sudo pacman -S --needed qemu virt-manager || handle_error "Falló la instalación de paquetes de virtualización."
    if virsh list &>/dev/null; then
        echo "Entorno virtual detectado. Configurando libvirt..." | tee -a "$LOG_FILE"
        sudo virsh net-start default || sudo virsh net-define /usr/share/libvirt/networks/default.xml || handle_error "Falló la configuración de red libvirt."
    fi
    git clone https://github.com/iEscapedVim/waydroid-installer.git || handle_error "Falló el clon de repositorio."
    cd waydroid-installer || handle_error "Falló el cambio de directorio."
    chmod +x install.sh
    ./install.sh || handle_error "Falló la ejecución del instalador."
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if [ -n "$FALLBACK_X11" ]; then
        sudo pacman -S --needed weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    fi
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"SteamOS (Steam Deck)")
    echo "Instalando Waydroid en SteamOS (Steam Deck)..." | tee -a "$LOG_FILE"
    echo "Créditos: ryanrudolfoba (https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer)"
    sudo pacman -Syu --needed git base-devel || handle_error "Falló la actualización e instalación de dependencias."
    cd ~
    git clone --depth=1 https://github.com/ryanrudolfoba/steamos-waydroid-installer || handle_error "Falló el clon de repositorio."
    cd steamos-waydroid-installer || handle_error "Falló el cambio de directorio."
    chmod +x steamos-waydroid-installer.sh
    ./steamos-waydroid-installer.sh || handle_error "Falló la ejecución del instalador."
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if [ -n "$FALLBACK_X11" ]; then
        sudo pacman -S --needed weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    fi
    echo "Instalación completada. Usa el toolbox para ajustes y lanza desde Game Mode." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"WSL2 (Windows)")
    echo "Instalando Waydroid en WSL2 (Ubuntu en Windows)..." | tee -a "$LOG_FILE"
    echo "Créditos: onomatopellan (https://gist.github.com/onomatopellan/c5220c0efddaff69aaff77cca80b7b8e)"
    sudo apt update || handle_error "Falló la actualización de paquetes."
    sudo apt install -y git bc build-essential flex bison libssl-dev libelf-dev dwarves libncurses-dev || handle_error "Falló la instalación de dependencias de kernel."
    git clone https://github.com/microsoft/WSL2-Linux-Kernel.git || handle_error "Falló el clon de repositorio."
    cd WSL2-Linux-Kernel || handle_error "Falló el cambio de directorio."
    LATEST_KERNEL=$(git ls-remote . | grep -o 'linux-msft-wsl-[0-9.]*' | sort -V | tail -n 1)
    echo "Último kernel disponible: $LATEST_KERNEL. ¿Usar este en lugar de 6.6.87? (s/n)" | tee -a "$LOG_FILE"
    read use_latest
    if [[ "$use_latest" == "s" || "$use_latest" == "S" ]]; then
        git checkout "$LATEST_KERNEL" || handle_error "Falló el checkout del kernel más reciente."
    else
        git checkout linux-msft-wsl-6.6.87 || handle_error "Falló el checkout del kernel predeterminado."
    fi
    cp Microsoft/config-wsl .config
    echo "Configurando kernel (interactivo, habilita CONFIG_ANDROID, CONFIG_ASHMEM, etc.):" | tee -a "$LOG_FILE"
    make menuconfig || handle_error "Falló la configuración del kernel."
    make -j$(nproc) || handle_error "Falló la compilación del kernel."
    sudo make modules_install || handle_error "Falló la instalación de módulos."
    cp arch/x86/boot/bzImage /mnt/c/Users/$(whoami)/bzImage || handle_error "Falló la copia del bzImage."
    WSL_CONFIG="/mnt/c/Users/$(whoami)/.wslconfig"
    if [ -f "$WSL_CONFIG" ]; then
        cp "$WSL_CONFIG" "$WSL_CONFIG.bak" || handle_error "Falló el respaldo de .wslconfig."
        echo "Copia de respaldo de .wslconfig creada." | tee -a "$LOG_FILE"
    fi
    echo "[wsl2]" | tee -a "$WSL_CONFIG"
    echo "kernel=C:\\\\Users\\\\$(whoami)\\\\bzImage" | tee -a "$WSL_CONFIG"
    wsl --shutdown || handle_error "Falló el shutdown de WSL."
    echo "¿Deseas strip symbols from modules para optimizar tamaño? (s/n)" | tee -a "$LOG_FILE"
    read strip_modules
    if [[ "$strip_modules" == "s" || "$strip_modules" == "S" ]]; then
        echo "Stripping symbols from modules..." | tee -a "$LOG_FILE"
        sudo find /lib/modules/$(uname -r) -name '*.ko' -exec strip --strip-unneeded {} \; || handle_error "Falló el strip de módulos."
        echo "Módulos optimizados." | tee -a "$LOG_FILE"
    fi
    echo "¿Crear un archivo .vhdx para módulos? (s/n)" | tee -a "$LOG_FILE"
    read create_vhdx
    if [[ "$create_vhdx" == "s" || "$create_vhdx" == "S" ]]; then
        echo "¿Qué tamaño deseas para el .vhdx? (ej. 512 para 512MB, predeterminado 512)" | tee -a "$LOG_FILE"
        read vhdx_size
        vhdx_size=${vhdx_size:-512}
        echo "Generando archivo .vhdx de ${vhdx_size}MB..." | tee -a "$LOG_FILE"
        sudo mkdir -p /mnt/c/Users/$(whoami)/wsl-modules || handle_error "Falló la creación de directorio."
        sudo make modules_install INSTALL_MOD_PATH=/mnt/c/Users/$(whoami)/wsl-modules || handle_error "Falló la instalación de módulos."
        dd if=/dev/zero of=/mnt/c/Users/$(whoami)/wsl-modules.vhdx bs=1M count=${vhdx_size} || handle_error "Falló la creación de .vhdx."
        mkfs.ntfs -F /mnt/c/Users/$(whoami)/wsl-modules.vhdx || handle_error "Falló el formato NTFS."
        sudo mount /mnt/c/Users/$(whoami)/wsl-modules.vhdx /mnt/wsl-modules || handle_error "Falló el montaje de .vhdx."
        sudo cp -r /mnt/c/Users/$(whoami)/wsl-modules/* /mnt/wsl-modules/ || handle_error "Falló la copia de módulos."
        sudo umount /mnt/wsl-modules || handle_error "Falló el desmontaje."
        echo "modules=C:\\\\Users\\\\$(whoami)\\\\wsl-modules.vhdx" | tee -a "$WSL_CONFIG"
        echo ".vhdx creado." | tee -a "$LOG_FILE"
    fi
    sudo apt install -y weston waydroid || handle_error "Falló la instalación de Weston y Waydroid."
    echo "¿Configurar audio con PulseAudio? (s/n)" | tee -a "$LOG_FILE"
    read setup_audio
    if [[ "$setup_audio" == "s" || "$setup_audio" == "S" ]]; then
        sudo apt install -y pulseaudio || handle_error "Falló la instalación de PulseAudio."
        echo "export PULSE_SERVER=/mnt/wslg/PulseServer" >> ~/.bashrc
        echo "Configurado PulseAudio. Reinicia la terminal." | tee -a "$LOG_FILE"
    fi
    export GALLIUM_DRIVER=d3d12
    if [ -n "$FALLBACK_X11" ]; then
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    else
        weston --backend=wayland-backend.so & || handle_error "Falló el inicio de Weston Wayland."
    fi
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    waydroid session start || handle_error "Falló el inicio de sesión Waydroid."
    waydroid show-full-ui || handle_error "Falló el lanzamiento de UI completa."
    echo "Instalación completada. Audio/GUI ajustado si se seleccionó." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"Install Waydroid Script (casualsnek)")
    echo "Instalando waydroid_script de casualsnek..." | tee -a "$LOG_FILE"
    echo "Créditos: casualsnek (https://github.com/casualsnek/waydroid_script)"
    if [[ "$DISTRO" == "alpine" ]] && ldd --version 2>&1 | grep -q musl; then
        sudo apk add gcompat || handle_error "Falló la instalación de gcompat."
        echo "gcompat instalado para compatibilidad con glibc en musl." | tee -a "$LOG_FILE"
    fi
    sudo apt install -y lzip || handle_error "Falló la instalación de lzip."
    git clone https://github.com/casualsnek/waydroid_script || handle_error "Falló el clon de repositorio."
    cd waydroid_script || handle_error "Falló el cambio de directorio."
    python3 -m venv venv || handle_error "Falló la creación de venv."
    venv/bin/pip install -r requirements.txt || handle_error "Falló la instalación de requirements."
    echo "Instalación completada. Tweaks opcionales:" | tee -a "$LOG_FILE"
    echo "¿Instalar GAPPS, Magisk, o multi-ventana? (gapps/magisk/multi/none)" | tee -a "$LOG_FILE"
    read tweak_option
    case $tweak_option in
        "gapps") sudo venv/bin/python3 main.py install gapps || handle_error "Falló la instalación de GAPPS." ;;
        "magisk") sudo venv/bin/python3 main.py install magisk || handle_error "Falló la instalación de Magisk." ;;
        "multi") waydroid prop set persist.waydroid.multi_windows true || handle_error "Falló la configuración de multi-ventana." ;;
        *) echo "Sin tweaks adicionales." | tee -a "$LOG_FILE" ;;
    esac
    echo "Usa interactivo: sudo venv/bin/python3 main.py" | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"Setup Full Desktop in WSL2 (tdcosta100)")
    echo "Configurando full desktop en WSL2..." | tee -a "$LOG_FILE"
    echo "Créditos: tdcosta100 (https://gist.github.com/tdcosta100/7def60bccc8ae32cf9cacb41064b1c0f)"
    sudo apt update && sudo apt upgrade || handle_error "Falló la actualización y upgrade."
    sudo snap install snap-store  # Opcional
    sudo apt install -y ubuntu-desktop acpi-support-base || handle_error "Falló la instalación de desktop."
    sudo systemctl mask gdm.service || handle_error "Falló el mask de GDM."
    sudo tee /etc/systemd/system/wslg-fix.service > /dev/null <<EOF
 

[Service]
Type=oneshot
ExecStart=-/usr/bin/umount /tmp/.X11-unix
ExecStart=/usr/bin/rm -rf /tmp/.X11-unix
ExecStart=/usr/bin/mkdir /tmp/.X11-unix
ExecStart=/usr/bin/chmod 1777 /tmp/.X11-unix
ExecStart=/usr/bin/ln -s /mnt/wslg/.X11-unix/X0 /tmp/.X11-unix/X0
ExecStart=/usr/bin/chmod 0777 /mnt/wslg/runtime-dir
ExecStart=/usr/bin/chmod 0666 /mnt/wslg/runtime-dir/wayland-0.lock
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable wslg-fix.service || handle_error "Falló la habilitación del servicio."
sudo mkdir -p /etc/systemd/user/org.gnome.Shell@wayland.service.d/ || handle_error "Falló la creación de directorio para override."
sudo tee /etc/systemd/user/org.gnome.Shell@wayland.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/gnome-shell --nested
EOF
wsl.exe --shutdown || handle_error "Falló el shutdown de WSL."
echo "Configuración completada. Reinicia WSL y lanza con: DESKTOP_SESSION=ubuntu GDMSESSION=ubuntu GNOME_SHELL_SESSION_MODE=ubuntu gnome-session" | tee -a "$LOG_FILE"
post_install_menu
;;

 
"openSUSE")
    echo "Instalando Waydroid en openSUSE..." | tee -a "$LOG_FILE"
    echo "Créditos: Runa-Chin (https://gist.github.com/Runa-Chin/0feda66c74e1c6b3e4a8f3f6698d7719)"
    sudo zypper install -y grubby || handle_error "Falló la instalación de grubby."
    sudo grubby --update-kernel="/boot/vmlinuz-$(uname -r)" --args="psi=1" || handle_error "Falló la configuración del kernel."
    echo "Kernel configurado. Reinicia después si es necesario." | tee -a "$LOG_FILE"
    if grep -q "Tumbleweed" /etc/os-release; then
        sudo zypper addrepo -f https://download.opensuse.org/repositories/home:runa-chin:Waydroid/openSUSE_Tumbleweed/home:runa-chin:Waydroid.repo || handle_error "Falló la adición del repositorio."
    else
        sudo zypper addrepo -f https://download.opensuse.org/repositories/home:runa-chin:Waydroid/openSUSE_Slowroll/home:runa-chin:Waydroid.repo || handle_error "Falló la adición del repositorio."
    fi
    sudo zypper refresh || handle_error "Falló la actualización de repositorios."
    sudo zypper install -y waydroid lxc iptables dnsmasq anbox-kmp-default || handle_error "Falló la instalación de paquetes."
    if [ -f /etc/apparmor.d/usr.sbin.dnsmasq ]; then
        sudo sed -i '/@{run}\/waydroid-lxc\//d' /etc/apparmor.d/usr.sbin.dnsmasq
        echo "@{run}/waydroid-lxc/ r," | sudo tee -a /etc/apparmor.d/usr.sbin.dnsmasq
        echo "@{run}/waydroid-lxc/* rw," | sudo tee -a /etc/apparmor.d/usr.sbin.dnsmasq
        sudo systemctl restart apparmor || handle_error "Falló el reinicio de AppArmor."
    fi
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    fi
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if [ -n "$FALLBACK_X11" ]; then
        sudo zypper install -y weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"NixOS")
    echo "Configurando Waydroid en NixOS..." | tee -a "$LOG_FILE"
    echo "Créditos: NixOS Wiki (https://nixos.wiki/wiki/Waydroid)"
    if grep -q waydroid /etc/fstab; then
        echo "Advertencia: Limpia entradas de Waydroid en /etc/fstab si hay conflictos." | tee -a "$LOG_FILE"
    fi
    sudo mkdir -p /etc/nixos || handle_error "Falló la creación de /etc/nixos."
    sudo tee /etc/nixos/waydroid.nix > /dev/null <<EOF
 

{ config, pkgs, ... }:
{
virtualisation.waydroid.enable = true;
systemd.packages = [ pkgs.waydroid-helper ];
environment.systemPackages = [ pkgs.waydroid-helper pkgs.wl-clipboard ];
systemd.services.waydroid-mount.wantedBy = [ "multi-user.target" ];
services.geoclue2.enable = true;
programs.adb.enable = true;
programs.kdeconnect = {
enable = true;
package = pkgs.gnomeExtensions.gsconnect;
};
}
EOF
echo "Aplicando configuración Nix..." | tee -a "$LOG_FILE"
sudo nixos-rebuild switch || handle_error "Falló la reconstrucción de NixOS."
echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
read tv_mode
if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
if command -v pv &>/dev/null; then
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
else
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
fi
unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
if waydroid prop get ro.widevine | grep -q "L3"; then
echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
else
echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
fi
if command -v vainfo &>/dev/null; then
vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
else
echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
fi
echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
else
echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
read android_version
if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
else
sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
fi
fi
if command -v systemctl &>/dev/null; then
systemctl --user start waydroid-monitor || handle_error "Falló el inicio de waydroid-monitor."
fi
if [ -n "$FALLBACK_X11" ]; then
sudo nix-env -iA nixos.weston || handle_error "Falló la instalación de Weston."
weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
fi
echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
post_install_menu
;;

 
"Gentoo")
    echo "Instalando Waydroid en Gentoo..." | tee -a "$LOG_FILE"
    echo "Créditos: Gentoo Wiki (https://wiki.gentoo.org/wiki/Waydroid)"
    if ! zcat /proc/config.gz | grep -q "CONFIG_ASHMEM=y"; then
        echo "Advertencia: Kernel debe soportar CONFIG_ASHMEM y CONFIG_ANDROID_BINDERFS." | tee -a "$LOG_FILE"
        read -p "¿Continuar sin verificar kernel? (s/n): " continue_gentoo
        [[ "$continue_gentoo" != "s" && "$continue_gentoo" != "S" ]] && handle_error "Instalación cancelada por falta de soporte en kernel."
    fi
    sudo emerge --ask sys-apps/waydroid || handle_error "Falló la instalación de Waydroid."
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    fi
    if [ -n "$FALLBACK_X11" ]; then
        sudo emerge --ask weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"ChromeOS (Crostini/Flex)")
    echo "Instalando Waydroid en ChromeOS (Crostini/Flex)..." | tee -a "$LOG_FILE"
    echo "Créditos: supechicken (https://github.com/supechicken/ChromeOS-Waydroid-Installer)"
    echo "¿Usar modo Android TV con kernel precompilado? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando kernel precompilado y build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/crostini-binder-kernel/releases/latest/download/bzImage -O ~/bzImage | pv -s 50M || handle_error "Falló descarga kernel."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/crostini-binder-kernel/releases/latest/download/bzImage -O ~/bzImage || handle_error "Falló descarga kernel."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo apt install -y expect || handle_error "Falló instalación de expect."
        cat << 'EOF' > ~/start_crostini.sh
 

#!/usr/bin/expect
spawn crosh
expect "crosh> "
send "vmc stop termina\r"
expect "crosh> "
send "vmc start termina --enable-gpu --kernel /home/chronos/user/MyFiles/bzImage\r"
expect "crosh> "
send "exit\r"
EOF
chmod +x ~/start_crostini.sh
echo "Ejecutando crosh para iniciar termina con kernel custom..." | tee -a "$LOG_FILE"
expect ~/start_crostini.sh || handle_error "Falló ejecución en crosh."
curl -L https://github.com/supechicken/ChromeOS-Waydroid-Installer/raw/refs/heads/main/installer/01-setup_lxd.sh | bash -eu || handle_error "Falló el setup LXD."
sudo apt update || handle_error "Falló la actualización de paquetes."
sudo apt install -y waydroid || handle_error "Falló la instalación de Waydroid."
sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
if waydroid prop get ro.widevine | grep -q "L3"; then
echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
else
echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
fi
if command -v vainfo &>/dev/null; then
vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
else
echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
fi
echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
else
curl -L https://github.com/supechicken/ChromeOS-Waydroid-Installer/raw/refs/heads/main/installer/01-setup_lxd.sh | bash -eu || handle_error "Falló el setup LXD."
sudo apt update || handle_error "Falló la actualización de paquetes."
if ! sudo apt install -y waydroid; then
echo "Falló instalación via apt. Intentando Flatpak..." | tee -a "$LOG_FILE"
if command -v flatpak &>/dev/null; then
flatpak install -y flathub id.waydro.Waydroid || handle_error "Falló instalación via Flatpak."
else
handle_error "Ni apt ni Flatpak disponibles."
fi
fi
echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
read android_version
if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
else
sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
fi
fi
if [ -n "$FALLBACK_X11" ]; then
sudo apt install -y weston || handle_error "Falló la instalación de Weston."
weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
fi
if command -v systemctl &>/dev/null; then
sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
fi
echo "Instalación completada. Ejecuta 'start-waydroid' para boot." | tee -a "$LOG_FILE"
post_install_menu
;;

 
"Universal Fallback (n1lby73)")
    echo "Instalando Waydroid con fallback universal..." | tee -a "$LOG_FILE"
    echo "Créditos: n1lby73 (https://github.com/n1lby73/waydroid-universal)" | tee -a "$LOG_FILE"
    if ! command -v git &>/dev/null; then
        if command -v apt &>/dev/null; then
            sudo apt update && sudo apt install -y git || handle_error "Falló la instalación de git."
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --needed git || handle_error "Falló la instalación de git."
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y git || handle_error "Falló la instalación de git."
        elif command -v zypper &>/dev/null; then
            sudo zypper install -y git || handle_error "Falló la instalación de git."
        elif command -v apk &>/dev/null; then
            sudo apk add git || handle_error "Falló la instalación de git."
        else
            handle_error "No se detectó un gestor de paquetes soportado para instalar git."
        fi
    fi
    git clone https://github.com/n1lby73/waydroid-universal.git || handle_error "Falló el clon de repositorio universal."
    cd waydroid-universal || handle_error "Falló el cambio de directorio."
    chmod +x install.sh
    ./install.sh || handle_error "Falló la ejecución del instalador universal."
    if [[ "$DISTRO" == "alpine" ]] && ldd --version 2>&1 | grep -q musl; then
        sudo apk add gcompat || handle_error "Falló la instalación de gcompat."
        echo "gcompat instalado para compatibilidad con glibc en musl." | tee -a "$LOG_FILE"
    fi
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    else
        echo "Advertencia: systemctl no disponible. Inicia Waydroid manualmente." | tee -a "$LOG_FILE"
    fi
    if [ -n "$FALLBACK_X11" ]; then
        if command -v apt &>/dev/null; then
            sudo apt install -y weston || handle_error "Falló la instalación de Weston."
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --needed weston || handle_error "Falló la instalación de Weston."
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y weston || handle_error "Falló la instalación de Weston."
        elif command -v zypper &>/dev/null; then
            sudo zypper install -y weston || handle_error "Falló la instalación de Weston."
        elif command -v apk &>/dev/null; then
            sudo apk add weston || handle_error "Falló la instalación de Weston."
        else
            echo "Advertencia: No se pudo instalar Weston automáticamente." | tee -a "$LOG_FILE"
        fi
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"Void Linux")
    echo "Instalando Waydroid en Void Linux..." | tee -a "$LOG_FILE"
    echo "Créditos: Waydroid Docs (https://docs.waydro.id)" | tee -a "$LOG_FILE"
    sudo xbps-install -S waydroid lxc iptables dnsmasq || handle_error "Falló la instalación de Waydroid y dependencias."
    if [ -f /etc/apparmor.d/usr.sbin.dnsmasq ]; then
        sudo sed -i '/@{run}\/waydroid-lxc\//d' /etc/apparmor.d/usr.sbin.dnsmasq
        echo "@{run}/waydroid-lxc/ r," | sudo tee -a /etc/apparmor.d/usr.sbin.dnsmasq
        echo "@{run}/waydroid-lxc/* rw," | sudo tee -a /etc/apparmor.d/usr.sbin.dnsmasq
        sudo systemctl restart apparmor || handle_error "Falló el reinicio de AppArmor."
    fi
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    else
        sudo rc-service waydroid-container start || handle_error "Falló el inicio del contenedor Waydroid."
        sudo rc-update add waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
    fi
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if [ -n "$FALLBACK_X11" ]; then
        sudo xbps-install -S weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"KISS Linux")
    echo "Instalando Waydroid en KISS Linux..." | tee -a "$LOG_FILE"
    echo "Advertencia: KISS Linux requiere configuración manual del kernel (CONFIG_ASHMEM, CONFIG_ANDROID_BINDERFS)." | tee -a "$LOG_FILE"
    if ! zcat /proc/config.gz | grep -q "CONFIG_ASHMEM=y"; then
        echo "Kernel no soporta CONFIG_ASHMEM. Compila un kernel con CONFIG_ASHMEM y CONFIG_ANDROID_BINDERFS." | tee -a "$LOG_FILE"
        read -p "¿Continuar sin verificar kernel? (s/n): " continue_kiss
        [[ "$continue_kiss" != "s" && "$continue_kiss" != "S" ]] && handle_error "Instalación cancelada por falta de soporte en kernel."
    fi
    echo "Clonando repositorio Waydroid..." | tee -a "$LOG_FILE"
    git clone https://github.com/waydroid/waydroid || handle_error "Falló el clon de repositorio Waydroid."
    cd waydroid || handle_error "Falló el cambio de directorio."
    echo "Compilando e instalando Waydroid manualmente..." | tee -a "$LOG_FILE"
    kiss b python3 python-gbinder lxc || handle_error "Falló la instalación de dependencias."
    if ldd --version 2>&1 | grep -q musl; then
        echo "musl libc detectado. Instalando gcompat para compatibilidad con glibc..." | tee -a "$LOG_FILE"
        kiss b gcompat || handle_error "Falló la instalación de gcompat."
    fi
    make || handle_error "Falló la compilación de Waydroid."
    sudo make install || handle_error "Falló la instalación de Waydroid."
    sudo ln -s /usr/local/bin/waydroid /usr/bin/waydroid || handle_error "Falló la creación de enlace simbólico."
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if [ -n "$FALLBACK_X11" ]; then
        kiss b weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    else
        sudo rc-service waydroid-container start || handle_error "Falló el inicio del contenedor Waydroid."
        sudo rc-update add waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
    fi
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"Fedora (Silverblue)")
    echo "Instalando Waydroid en Fedora (Silverblue)..." | tee -a "$LOG_FILE"
    echo "Créditos: Waydroid Docs (https://docs.waydro.id)" | tee -a "$LOG_FILE"
    sudo rpm-ostree install waydroid || handle_error "Falló la instalación de Waydroid."
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
        sudo systemctl start waydroid-container || handle_error "Falló el inicio del contenedor Waydroid."
    else
        echo "Advertencia: systemctl no disponible. Inicia Waydroid manualmente." | tee -a "$LOG_FILE"
    fi
    if [ -n "$FALLBACK_X11" ]; then
        echo "Configurando X11 fallback para Fedora Silverblue..." | tee -a "$LOG_FILE"
        sudo rpm-ostree install weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"Alpine Linux")
    echo "Instalando Waydroid en Alpine Linux..." | tee -a "$LOG_FILE"
    echo "Créditos: Adaptado de Waydroid Docs (https://docs.waydro.id) para Alpine" | tee -a "$LOG_FILE"
    echo "Advertencia: Alpine Linux requiere kernel con CONFIG_ASHMEM y CONFIG_ANDROID_BINDERFS." | tee -a "$LOG_FILE"
    if ! zcat /proc/config.gz | grep -q "CONFIG_ASHMEM=y"; then
        echo "Kernel no soporta CONFIG_ASHMEM. Compila un kernel con CONFIG_ASHMEM y CONFIG_ANDROID_BINDERFS." | tee -a "$LOG_FILE"
        read -p "¿Continuar sin verificar kernel? (s/n): " continue_alpine
        [[ "$continue_alpine" != "s" && "$continue_alpine" != "S" ]] && handle_error "Instalación cancelada por falta de soporte en kernel."
    fi
    sudo apk add --no-cache community || handle_error "Falló la habilitación del repositorio community."
    sudo apk add python3 py3-pip git lxc iptables dnsmasq gcompat || handle_error "Falló la instalación de dependencias."
    if ldd --version 2>&1 | grep -q musl; then
        echo "musl libc detectado. gcompat instalado para compatibilidad con glibc." | tee -a "$LOG_FILE"
    else
        echo "Advertencia: musl libc no detectado. Verifica la configuración de libc." | tee -a "$LOG_FILE"
    fi
    sudo rc-update add lxc-net || handle_error "Falló la habilitación de lxc-net."
    sudo rc-service lxc-net start || handle_error "Falló el inicio de lxc-net."
    echo "Clonando y compilando Waydroid..." | tee -a "$LOG_FILE"
    git clone https://github.com/waydroid/waydroid || handle_error "Falló el clon de repositorio Waydroid."
    cd waydroid || handle_error "Falló el cambio de directorio."
    sudo pip3 install -r requirements.txt || handle_error "Falló la instalación de requisitos Python."
    sudo python3 setup.py install || handle_error "Falló la instalación de Waydroid."
    sudo ln -s /usr/local/bin/waydroid /usr/bin/waydroid || handle_error "Falló la creación de enlace simbólico."
    echo "¿Usar modo Android TV de supechicken? (s/n, predeterminado Android 11 vanilla)" | tee -a "$LOG_FILE"
    read tv_mode
    if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then
        echo "Descargando build Android TV..." | tee -a "$LOG_FILE"
        if command -v pv &>/dev/null; then
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz | pv -s 2G || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz | pv -s 1G || handle_error "Falló descarga vendor TV."
        else
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/system-tv13.img.xz -O ~/system-tv13.img.xz || handle_error "Falló descarga system TV."
            wget https://github.com/supechicken/waydroid-androidtv-build/releases/latest/download/vendor-tv13.img.xz -O ~/vendor-tv13.img.xz || handle_error "Falló descarga vendor TV."
        fi
        unxz ~/system-tv13.img.xz || handle_error "Falló descompresión system."
        unxz ~/vendor-tv13.img.xz || handle_error "Falló descompresión vendor."
        sudo waydroid init -s ~/system-tv13.img -v ~/vendor-tv13.img || handle_error "Falló init TV."
        echo "Verificando soporte Widevine/VA-API..." | tee -a "$LOG_FILE"
        if waydroid prop get ro.widevine | grep -q "L3"; then
            echo "Widevine L3 detectado. Soporte streaming OK." | tee -a "$LOG_FILE"
        else
            echo "Advertencia: Widevine L3 no detectado. Streaming puede fallar." | tee -a "$LOG_FILE"
        fi
        if command -v vainfo &>/dev/null; then
            vainfo | grep -q VAAPI && echo "VA-API detectado. Aceleración de video OK." | tee -a "$LOG_FILE" || echo "Advertencia: VA-API no detectado." | tee -a "$LOG_FILE"
        else
            echo "vainfo no instalado. Instala libva-utils para verificar VA-API." | tee -a "$LOG_FILE"
        fi
        echo "Modo Android TV activado (VA-API/Widevine)." | tee -a "$LOG_FILE"
    else
        echo "¿Usar imagen Android 13 beta? (s/n, predeterminado Android 11)" | tee -a "$LOG_FILE"
        read android_version
        if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then
            sudo waydroid init -s https://ota.waydro.id/system-13 -v https://ota.waydro.id/vendor-13 || handle_error "Falló la inicialización con Android 13."
        else
            sudo waydroid init || handle_error "Falló la inicialización de Waydroid."
        fi
    fi
    if [ -n "$FALLBACK_X11" ]; then
        sudo apk add weston || handle_error "Falló la instalación de Weston."
        weston --backend=x11-backend.so & || handle_error "Falló el inicio de Weston X11."
    fi
    sudo rc-service waydroid-container start || handle_error "Falló el inicio del contenedor Waydroid."
    sudo rc-update add waydroid-container || handle_error "Falló la habilitación del servicio Waydroid."
    echo "Instalación completada. Ejecuta 'waydroid session start' para iniciar." | tee -a "$LOG_FILE"
    post_install_menu
    ;;

"Salir")
    echo "Saliendo del instalador. ¡Hasta la próxima, arquitecto digital!" | tee -a "$LOG_FILE"
    exit 0
    ;;
*)
    echo "Opción inválida. Usa una distribución válida o 'Salir'." | tee -a "$LOG_FILE"
    exit 1
    ;;
 

esac

Generar README dinámico %HEADING%generar-readme-dinámico%HEADING%

echo "Generando README dinámico..." | tee -a "$LOG_FILE"
README_FILE="$HOME/waydroid_setup_readme.md"
cat << EOF > "$README_FILE"

Waydroid Setup - Resumen de Instalación %HEADING%waydroid-setup--resumen-de-instalación%HEADING%

Fecha de instalación: $(date)
Distribución: $DISTRO ($SUGGESTED_OPT)
libc: $(if [[ "$DISTRO" == "alpine" ]] && ldd --version 2>&1 | grep -q musl; then echo "musl (gcompat instalado)"; else echo "glibc u otra"; fi)
Modo Android: $(if [[ "$tv_mode" == "s" || "$tv_mode" == "S" ]]; then echo "Android TV (supechicken)"; else echo "Android $(if [[ "$android_version" == "s" || "$android_version" == "S" ]]; then echo "13 beta"; else echo "11 vanilla"; fi)"; fi)
Widevine: $(if waydroid prop get ro.widevine | grep -q "L3"; then echo "L3 detectado (streaming OK)"; else echo "No detectado (streaming puede fallar)"; fi)
VA-API: $(if command -v vainfo &>/dev/null && vainfo | grep -q VAAPI; then echo "Detectado (aceleración de video OK)"; else echo "No detectado (instala libva-utils)"; fi)
Logs: $LOG_FILE
Comandos útiles:

Iniciar Waydroid: `waydroid session start`
Mostrar UI completa: `waydroid show-full-ui`
Instalar APK: `waydroid app install <path/to/apk>`
Control remoto: `scrcpy` (si instalado)
Backup: `./waybak backup /var/lib/waydroid` (si instalado)
Restaurar: `./waybak restore /var/lib/waydroid/backup` (si instalado)
Notas:
Revisa $LOG_FILE para detalles de instalación.
Si usas ChromeOS, ejecuta `~/start_crostini.sh` para kernel custom.
En Alpine/KISS Linux, verifica soporte de kernel (CONFIG_ASHMEM, CONFIG_ANDROID_BINDERFS).
En Alpine, gcompat asegura compatibilidad con aplicaciones glibc.
Para soporte, visita https://docs.waydro.id o https://github.com/waydroid.
EOF
echo "README generado en $README_FILE." | tee -a "$LOG_FILE"

Limpieza final %HEADING%limpieza-final%HEADING%

echo "¿Limpiar imágenes y archivos temporales? (s/n)" | tee -a "$LOG_FILE"
read cleanup
if [[ "$cleanup" == "s" || "$cleanup" == "S" ]]; then
echo "Limpiando imágenes descargadas y temporales..." | tee -a "$LOG_FILE"
rm -rf ~/system-tv13.img ~/vendor-tv13.img ~/system-tv13.img.xz ~/vendor-tv13.img.xz ~/bzImage ~/waydroid-installer ~/waydroid_script ~/waybak ~/Droid-NDK-Extractor ~/steamos-waydroid-installer ~/anbox-modules ~/waydroid ~/waydroid-universal || echo "No se encontraron archivos para limpiar." | tee -a "$LOG_FILE"
echo "Limpieza completada." | tee -a "$LOG_FILE"
fi

echo "¡Instalación suprema completada, oh arquitecto de los reinos digitales! Revisa $README_FILE para detalles y comandos." | tee -a "$LOG_FILE"
exit 0
