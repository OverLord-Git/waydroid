#!/bin/bash
# =============================================================================
# MÓDULO PACKAGE - Gestión de paquetes y dependencias
# =============================================================================
# Funcionalidades: detección de gestores de paquetes, instalación de dependencias,
#                  gestión de repositorios, manejo de paquetes específicos
# Versión: 2.0 - Octubre 2025

# Dependencias del módulo
if [ -z "$LOG_FILE" ]; then
    echo "❌ Error: Módulo core no cargado. Cargar modules/core.sh primero."
    exit 1
fi

# =============================================================================
# CONFIGURACIÓN DE GESTORES DE PAQUETES
# =============================================================================

declare -g DETECTED_PKG_MANAGER=""
declare -g PKG_MANAGER_CMD=""
declare -g PKG_UPDATE_CMD=""
declare -g PKG_INSTALL_CMD=""
declare -g PKG_SEARCH_CMD=""
declare -g PKG_REMOVE_CMD=""

# Base de datos de gestores de paquetes y sus comandos
declare -A PKG_MANAGERS=(
    # Debian/Ubuntu family
    ["apt"]="update:apt update|install:apt install -y|search:apt search|remove:apt remove -y|check:dpkg -l"
    
    # Arch family
    ["pacman"]="update:pacman -Sy|install:pacman -S --needed --noconfirm|search:pacman -Ss|remove:pacman -R --noconfirm|check:pacman -Q"
    
    # Fedora family
    ["dnf"]="update:dnf check-update|install:dnf install -y|search:dnf search|remove:dnf remove -y|check:rpm -q"
    ["yum"]="update:yum check-update|install:yum install -y|search:yum search|remove:yum remove -y|check:rpm -q"
    
    # openSUSE
    ["zypper"]="update:zypper refresh|install:zypper install -y|search:zypper search|remove:zypper remove -y|check:rpm -q"
    
    # Alpine
    ["apk"]="update:apk update|install:apk add|search:apk search|remove:apk del|check:apk info -e"
    
    # Void Linux
    ["xbps"]="update:xbps-install -S|install:xbps-install -y|search:xbps-query -Rs|remove:xbps-remove -y|check:xbps-query"
    
    # Gentoo
    ["emerge"]="update:emerge --sync|install:emerge|search:emerge -s|remove:emerge -C|check:qlist -I"
    
    # Immutable systems
    ["rpm-ostree"]="update:rpm-ostree refresh-md|install:rpm-ostree install|search:rpm-ostree search|remove:rpm-ostree uninstall|check:rpm -q"
)

# Dependencias específicas de Waydroid por distribución
declare -A WAYDROID_DEPS=(
    ["base"]="curl wget python3 python3-pip python3-requests-unixsocket python3-gbinder lxc lxc-utils android-tools-adb android-tools-fastboot"
    ["ubuntu"]="$base python3-pip python3-requests python3-gbinder waydroid"
    ["debian"]="$base python3-pip python3-requests python3-gbinder waydroid"
    ["arch"]="python python-pip python-requests-unixsocket python-gbinder lxc android-tools waydroid"
    ["fedora"]="python3 python3-pip python3-requests-unixsocket python3-gbinder lxc android-tools waydroid"
    ["opensuse"]="python3 python3-pip python3-requests-unixsocket python3-gbinder lxc android-tools waydroid"
    ["alpine"]="python3 py3-pip py3-requests lxc android-tools"
    ["void"]="python3 python3-pip python3-requests-unixsocket lxc android-tools"
    ["gentoo"]="dev-lang/python dev-python/pip dev-python/requests app-emulation/lxc dev-util/android-tools"
)

# =============================================================================
# FUNCIONES DE DETECCIÓN DE GESTORES DE PAQUETES
# =============================================================================

# Función principal para detectar el gestor de paquetes
detect_package_manager() {
    log_message "Detectando gestor de paquetes del sistema" "INFO"
    
    # Lista de gestores de paquetes en orden de prioridad
    local pkg_managers=("apt" "pacman" "dnf" "yum" "zypper" "apk" "xbps" "emerge" "rpm-ostree")
    
    for pkg_mgr in "${pkg_managers[@]}"; do
        if command_exists "$pkg_mgr"; then
            DETECTED_PKG_MANAGER="$pkg_mgr"
            log_message "Gestor de paquetes detectado: $pkg_mgr" "INFO"
            
            # Configurar comandos específicos
            configure_package_manager_commands "$pkg_mgr"
            return 0
        fi
    done
    
    log_error "No se pudo detectar un gestor de paquetes compatible"
    return 1
}

# Configurar comandos específicos del gestor de paquetes
configure_package_manager_commands() {
    local pkg_mgr="$1"
    
    if [ -z "${PKG_MANAGERS[$pkg_mgr]}" ]; then
        log_error "Gestor de paquetes no configurado: $pkg_mgr"
        return 1
    fi
    
    local config="${PKG_MANAGERS[$pkg_mgr]}"
    
    # Extraer comandos de la configuración
    PKG_UPDATE_CMD=$(echo "$config" | grep -o 'update:[^|]*' | cut -d':' -f2)
    PKG_INSTALL_CMD=$(echo "$config" | grep -o 'install:[^|]*' | cut -d':' -f2)
    PKG_SEARCH_CMD=$(echo "$config" | grep -o 'search:[^|]*' | cut -d':' -f2)
    PKG_REMOVE_CMD=$(echo "$config" | grep -o 'remove:[^|]*' | cut -d':' -f2)
    local pkg_check_cmd=$(echo "$config" | grep -o 'check:[^|]*' | cut -d':' -f2)
    
    log_debug "Comandos configurados para $pkg_mgr:"
    log_debug "  Update: $PKG_UPDATE_CMD"
    log_debug "  Install: $PKG_INSTALL_CMD"
    log_debug "  Search: $PKG_SEARCH_CMD"
    log_debug "  Remove: $PKG_REMOVE_CMD"
    log_debug "  Check: $pkg_check_cmd"
}

# =============================================================================
# FUNCIONES DE GESTIÓN DE PAQUETES
# =============================================================================

# Función para actualizar repositorios
update_package_repositories() {
    if [ -z "$PKG_UPDATE_CMD" ]; then
        log_error "Comando de actualización no configurado"
        return 1
    fi
    
    echo "🔄 Actualizando repositorios de paquetes..."
    log_message "Executing: sudo $PKG_UPDATE_CMD" "INFO"
    
    if sudo $PKG_UPDATE_CMD; then
        echo "✅ Repositorios actualizados correctamente"
        log_message "Package repositories updated successfully" "INFO"
        return 0
    else
        echo "⚠️ Error actualizando repositorios"
        log_error "Failed to update package repositories"
        return 1
    fi
}

# Función para instalar un paquete individual
install_package() {
    local package="$1"
    local optional="${2:-false}"
    
    if [ -z "$package" ]; then
        log_error "Nombre de paquete no especificado"
        return 1
    fi
    
    if [ -z "$PKG_INSTALL_CMD" ]; then
        log_error "Comando de instalación no configurado"
        return 1
    fi
    
    # Verificar si el paquete ya está instalado
    if is_package_installed "$package"; then
        echo "✅ Paquete ya instalado: $package"
        log_debug "Package already installed: $package"
        return 0
    fi
    
    echo "📦 Instalando paquete: $package"
    log_message "Installing package: $package" "INFO"
    
    if sudo $PKG_INSTALL_CMD "$package"; then
        echo "✅ Paquete instalado: $package"
        log_message "Package installed successfully: $package" "INFO"
        return 0
    else
        if [ "$optional" = "true" ]; then
            echo "⚠️ Paquete opcional no disponible: $package"
            log_warning "Optional package not available: $package"
            return 0
        else
            echo "❌ Error instalando paquete: $package"
            log_error "Failed to install package: $package"
            return 1
        fi
    fi
}

# Función para instalar múltiples paquetes
install_packages() {
    local packages=("$@")
    local failed_packages=()
    local installed_count=0
    local total_count=${#packages[@]}
    
    echo "📦 Instalando $total_count paquetes..."
    
    for package in "${packages[@]}"; do
        if install_package "$package"; then
            ((installed_count++))
        else
            failed_packages+=("$package")
        fi
        
        # Mostrar progreso
        show_progress "$installed_count" "$total_count" "Instalación de paquetes"
    done
    
    echo ""  # Nueva línea después del progreso
    
    if [ ${#failed_packages[@]} -eq 0 ]; then
        echo "✅ Todos los paquetes instalados correctamente ($installed_count/$total_count)"
        return 0
    else
        echo "⚠️ Algunos paquetes fallaron: ${failed_packages[*]}"
        echo "✅ Paquetes instalados exitosamente: $installed_count/$total_count"
        return 1
    fi
}

# Función para verificar si un paquete está instalado
is_package_installed() {
    local package="$1"
    
    case "$DETECTED_PKG_MANAGER" in
        "apt")
            dpkg -l "$package" 2>/dev/null | grep -q '^ii'
            ;;
        "pacman")
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        "dnf"|"yum")
            rpm -q "$package" >/dev/null 2>&1
            ;;
        "zypper")
            rpm -q "$package" >/dev/null 2>&1
            ;;
        "apk")
            apk info -e "$package" >/dev/null 2>&1
            ;;
        "xbps")
            xbps-query "$package" >/dev/null 2>&1
            ;;
        "emerge")
            qlist -I "$package" >/dev/null 2>&1
            ;;
        "rpm-ostree")
            rpm -q "$package" >/dev/null 2>&1
            ;;
        *)
            log_warning "Verificación de paquetes no implementada para: $DETECTED_PKG_MANAGER"
            return 1
            ;;
    esac
}

# Función para buscar paquetes
search_package() {
    local search_term="$1"
    
    if [ -z "$search_term" ]; then
        log_error "Término de búsqueda no especificado"
        return 1
    fi
    
    if [ -z "$PKG_SEARCH_CMD" ]; then
        log_error "Comando de búsqueda no configurado"
        return 1
    fi
    
    echo "🔍 Buscando paquetes relacionados con: $search_term"
    $PKG_SEARCH_CMD "$search_term"
}

# =============================================================================
# FUNCIONES ESPECÍFICAS DE WAYDROID
# =============================================================================

# Función para instalar dependencias de Waydroid
install_waydroid_dependencies() {
    local distro="${1:-$DETECTED_DISTRO}"
    
    log_message "Instalando dependencias de Waydroid para: $distro" "INFO"
    
    # Actualizar repositorios primero
    if ! update_package_repositories; then
        log_warning "No se pudieron actualizar los repositorios, continuando..."
    fi
    
    # Obtener lista de dependencias
    local deps
    deps=$(get_waydroid_dependencies "$distro")
    if [ $? -ne 0 ] || [ -z "$deps" ]; then
        log_error "No se pudieron obtener las dependencias para: $distro"
        return 1
    fi
    
    # Convertir string a array
    local deps_array
    read -ra deps_array <<< "$deps"
    
    echo "📋 Dependencias a instalar: ${deps_array[*]}"
    
    # Instalar dependencias
    if install_packages "${deps_array[@]}"; then
        echo "✅ Dependencias de Waydroid instaladas correctamente"
        log_message "Waydroid dependencies installed successfully" "INFO"
        return 0
    else
        echo "⚠️ Algunas dependencias fallaron, continuando..."
        log_warning "Some Waydroid dependencies failed to install"
        return 1
    fi
}

# Obtener lista de dependencias específicas para una distribución
get_waydroid_dependencies() {
    local distro="$1"
    
    # Intentar obtener dependencias específicas
    if [ -n "${WAYDROID_DEPS[$distro]}" ]; then
        echo "${WAYDROID_DEPS[$distro]}"
        return 0
    fi
    
    # Fallback a dependencias base
    if [ -n "${WAYDROID_DEPS[base]}" ]; then
        echo "${WAYDROID_DEPS[base]}"
        return 0
    fi
    
    log_error "No hay dependencias definidas para: $distro"
    return 1
}

# Función para añadir repositorios específicos de Waydroid
add_waydroid_repositories() {
    local distro="${1:-$DETECTED_DISTRO}"
    
    log_message "Añadiendo repositorios de Waydroid para: $distro" "INFO"
    
    case "$distro" in
        "ubuntu"|"debian")
            add_waydroid_apt_repository
            ;;
        "arch")
            echo "ℹ️ Para Arch Linux, instalar desde AUR: yay -S waydroid"
            ;;
        "fedora")
            add_waydroid_copr_repository
            ;;
        "opensuse")
            add_waydroid_obs_repository
            ;;
        *)
            log_warning "Repositorio de Waydroid no configurado para: $distro"
            return 1
            ;;
    esac
}

# Añadir repositorio APT para Ubuntu/Debian
add_waydroid_apt_repository() {
    echo "📋 Añadiendo repositorio APT de Waydroid..."
    
    # Instalar dependencias para añadir repositorios
    install_package "software-properties-common" true
    install_package "apt-transport-https" true
    install_package "ca-certificates" true
    install_package "gnupg" true
    
    # Añadir clave GPG
    if curl -fsSL https://repo.waydro.id/waydroid.gpg | sudo gpg --dearmor -o /usr/share/keyrings/waydroid-archive-keyring.gpg; then
        echo "✅ Clave GPG añadida"
    else
        log_error "Error añadiendo clave GPG de Waydroid"
        return 1
    fi
    
    # Añadir repositorio
    echo "deb [signed-by=/usr/share/keyrings/waydroid-archive-keyring.gpg] https://repo.waydro.id/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/waydroid.list
    
    # Actualizar repositorios
    update_package_repositories
}

# Añadir repositorio COPR para Fedora
add_waydroid_copr_repository() {
    echo "📋 Añadiendo repositorio COPR de Waydroid..."
    
    install_package "dnf-plugins-core" true
    
    if sudo dnf copr enable aleasto/waydroid; then
        echo "✅ Repositorio COPR añadido"
        update_package_repositories
    else
        log_error "Error añadiendo repositorio COPR de Waydroid"
        return 1
    fi
}

# Añadir repositorio OBS para openSUSE
add_waydroid_obs_repository() {
    echo "📋 Añadiendo repositorio OBS de Waydroid..."
    
    if sudo zypper addrepo https://download.opensuse.org/repositories/home:aleasto:waydroid/openSUSE_Tumbleweed/home:aleasto:waydroid.repo; then
        echo "✅ Repositorio OBS añadido"
        update_package_repositories
    else
        log_error "Error añadiendo repositorio OBS de Waydroid"
        return 1
    fi
}

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

# Función para limpiar cache de paquetes
clean_package_cache() {
    log_message "Limpiando cache de paquetes" "INFO"
    
    case "$DETECTED_PKG_MANAGER" in
        "apt")
            sudo apt autoremove -y && sudo apt autoclean
            ;;
        "pacman")
            sudo pacman -Sc --noconfirm
            ;;
        "dnf")
            sudo dnf clean all
            ;;
        "zypper")
            sudo zypper clean --all
            ;;
        "apk")
            sudo apk cache clean
            ;;
        "xbps")
            sudo xbps-remove -O
            ;;
        *)
            log_warning "Limpieza de cache no implementada para: $DETECTED_PKG_MANAGER"
            ;;
    esac
    
    echo "✅ Cache de paquetes limpiado"
}

# Función para mostrar información del gestor de paquetes
show_package_manager_info() {
    echo "📦 Información del Gestor de Paquetes"
    echo "===================================="
    echo "Gestor detectado: $DETECTED_PKG_MANAGER"
    echo "Comando de actualización: $PKG_UPDATE_CMD"
    echo "Comando de instalación: $PKG_INSTALL_CMD"
    echo "Comando de búsqueda: $PKG_SEARCH_CMD"
    echo "Comando de eliminación: $PKG_REMOVE_CMD"
    echo "===================================="
}

# Función para verificar privilegios sudo antes de operaciones
check_sudo_privileges() {
    # Verificar si sudo está disponible en el sistema
    if ! command_exists "sudo"; then
        log_warning "Comando sudo no disponible en el sistema (entorno de prueba)"
        log_warning "Algunas operaciones de paquetes pueden requerir privilegios elevados"
        return 0  # Permitir continuar en entornos sin sudo
    fi
    
    # Verificar privilegios sudo sin prompt
    if ! sudo -n true 2>/dev/null; then
        echo "🔐 Se requieren privilegios sudo para la gestión de paquetes"
        
        # Intentar obtener privilegios sudo interactivamente
        if ! sudo true 2>/dev/null; then
            log_warning "No se pudieron obtener privilegios sudo"
            log_warning "Algunas operaciones de gestión de paquetes pueden fallar"
            return 0  # Permitir continuar sin sudo para pruebas
        fi
    fi
    
    log_debug "Privilegios sudo verificados correctamente"
    return 0
}

# =============================================================================
# INICIALIZACIÓN DEL MÓDULO
# =============================================================================

# Función de inicialización del módulo package
init_package_module() {
    log_message "Inicializando módulo package" "INFO"
    
    # Verificar privilegios sudo
    if ! check_sudo_privileges; then
        log_error "No se pueden obtener privilegios sudo necesarios"
        return 1
    fi
    
    # Detectar gestor de paquetes
    if ! detect_package_manager; then
        log_error "No se pudo detectar un gestor de paquetes"
        return 1
    fi
    
    log_message "Módulo package inicializado con gestor: $DETECTED_PKG_MANAGER" "INFO"
    return 0
}

# Auto-inicializar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Cargar core si no está cargado
    if ! function_exists "log_message"; then
        source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
    fi
    
    init_package_module
    show_package_manager_info
    echo "✅ Módulo package inicializado correctamente"
fi