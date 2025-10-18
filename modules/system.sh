#!/bin/bash
# =============================================================================
# MÓDULO SYSTEM - Detección de sistema y entorno
# =============================================================================
# Funcionalidades: detección de distribuciones, análisis de entorno, 
#                  verificación de requisitos del sistema
# Versión: 2.0 - Octubre 2025

# Dependencias del módulo
if [ -z "$LOG_FILE" ]; then
    echo "❌ Error: Módulo core no cargado. Cargar modules/core.sh primero."
    exit 1
fi

# =============================================================================
# VARIABLES DE SISTEMA
# =============================================================================

declare -g DETECTED_DISTRO=""
declare -g DISTRO_LIKE=""
declare -g DISTRO_VERSION=""
declare -g KERNEL_VERSION=""
declare -g ARCH=""
declare -g VIRT_TYPE=""
declare -g IS_WSL=false
declare -g IS_CHROMEOS=false
declare -g IS_CONTAINER=false
declare -g SUGGESTED_INSTALLATION=""

# Base de datos de distribuciones soportadas
declare -A DISTRO_INFO=(
    # Ubuntu y derivadas
    ["ubuntu"]="apt:ubuntu-waydroid-ppa:gpl"
    ["debian"]="apt:debian-backports:gpl"
    ["mint"]="apt:ubuntu-ppa:gpl"
    ["zorin"]="apt:ubuntu-ppa:gpl"
    ["elementary"]="apt:ubuntu-ppa:gpl"
    ["pop"]="apt:ubuntu-ppa:gpl"
    
    # Arch y derivadas
    ["arch"]="pacman:aur:gpl"
    ["manjaro"]="pacman:aur:gpl"
    ["endeavouros"]="pacman:aur:gpl"
    ["garuda"]="pacman:aur:gpl"
    
    # Fedora y derivadas
    ["fedora"]="dnf:copr:gpl"
    ["silverblue"]="rpm-ostree:copr:gpl"
    ["nobara"]="dnf:copr:gpl"
    
    # openSUSE
    ["opensuse"]="zypper:obs:gpl"
    ["opensuse-leap"]="zypper:obs:gpl"
    ["opensuse-tumbleweed"]="zypper:obs:gpl"
    
    # Gentoo
    ["gentoo"]="emerge:overlay:source"
    
    # Alpine
    ["alpine"]="apk:edge:musl"
    
    # Void
    ["void"]="xbps:void-repo:gpl"
    
    # Entornos especiales
    ["steamos"]="pacman:aur:immutable"
    ["chromeos"]="crostini:manual:restricted"
    ["wsl"]="apt:wsl-specific:virtualized"
)

# =============================================================================
# FUNCIONES DE DETECCIÓN DE DISTRIBUCIÓN
# =============================================================================

# Función principal para detectar distribución
detect_distribution() {
    log_message "Iniciando detección de distribución" "INFO"
    
    # Resetear variables globales
    DETECTED_DISTRO=""
    DISTRO_LIKE=""
    DISTRO_VERSION=""
    
    # Detectar información básica del sistema
    detect_basic_system_info
    
    # Detectar distribución específica
    if detect_special_environments; then
        log_message "Entorno especial detectado: $DETECTED_DISTRO" "INFO"
    else
        detect_standard_distribution
    fi
    
    # Detectar arquitectura y virtualization
    detect_architecture
    detect_virtualization
    
    # Determinar instalación sugerida
    determine_suggested_installation
    
    # Mostrar resumen
    display_system_summary
    
    log_message "Detección de distribución completada: $DETECTED_DISTRO" "INFO"
}

# Detectar información básica del sistema
detect_basic_system_info() {
    KERNEL_VERSION=$(uname -r)
    ARCH=$(uname -m)
    
    log_debug "Kernel: $KERNEL_VERSION, Arch: $ARCH"
}

# Detectar entornos especiales (WSL, ChromeOS, contenedores)
detect_special_environments() {
    # Detectar WSL
    if grep -q Microsoft /proc/version 2>/dev/null || grep -q WSL /proc/version 2>/dev/null; then
        DETECTED_DISTRO="wsl"
        IS_WSL=true
        
        # Detectar versión de WSL
        if grep -q WSL2 /proc/version 2>/dev/null; then
            DISTRO_VERSION="2"
        else
            DISTRO_VERSION="1"
        fi
        
        return 0
    fi
    
    # Detectar ChromeOS/Crostini
    if [ -f /etc/chromeos-version ] || [ -f /opt/google/cros-containers/bin/sommelier ]; then
        DETECTED_DISTRO="chromeos"
        IS_CHROMEOS=true
        
        if [ -f /etc/chromeos-version ]; then
            DISTRO_VERSION=$(cat /etc/chromeos-version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
        fi
        
        return 0
    fi
    
    # Detectar contenedores
    if [ -f /.dockerenv ] || grep -q "/docker/" /proc/self/cgroup 2>/dev/null; then
        IS_CONTAINER=true
        VIRT_TYPE="docker"
        log_debug "Entorno Docker detectado"
    elif grep -q "/lxc/" /proc/self/cgroup 2>/dev/null; then
        IS_CONTAINER=true
        VIRT_TYPE="lxc"
        log_debug "Entorno LXC detectado"
    fi
    
    # Detectar SteamOS
    if [ -f /etc/steamos-release ] || grep -q "steamos" /etc/os-release 2>/dev/null; then
        DETECTED_DISTRO="steamos"
        DISTRO_VERSION=$(grep VERSION_ID /etc/os-release 2>/dev/null | cut -d'=' -f2 | tr -d '"')
        return 0
    fi
    
    return 1
}

# Detectar distribución estándar usando /etc/os-release
detect_standard_distribution() {
    if [ ! -f /etc/os-release ]; then
        log_warning "Archivo /etc/os-release no encontrado"
        DETECTED_DISTRO="unknown"
        return 1
    fi
    
    # Leer información de os-release
    local os_id=""
    local os_id_like=""
    local os_version=""
    
    # Usar source para cargar variables de manera segura
    {
        source /etc/os-release
        os_id="$ID"
        os_id_like="$ID_LIKE"
        os_version="$VERSION_ID"
    } 2>/dev/null
    
    DETECTED_DISTRO="${os_id:-unknown}"
    DISTRO_LIKE="${os_id_like}"
    DISTRO_VERSION="${os_version}"
    
    # Normalizaciones específicas
    case "$DETECTED_DISTRO" in
        "opensuse-leap"|"opensuse-tumbleweed")
            DETECTED_DISTRO="opensuse"
            ;;
        "ubuntu"|"debian"|"arch"|"fedora"|"gentoo"|"alpine"|"void")
            # Distribuciones principales, mantener como están
            ;;
        *)
            # Para distribuciones derivadas, intentar mapear a la base
            if [[ "$DISTRO_LIKE" =~ ubuntu|debian ]]; then
                log_debug "Distribución basada en Debian/Ubuntu detectada: $DETECTED_DISTRO"
            elif [[ "$DISTRO_LIKE" =~ arch ]]; then
                log_debug "Distribución basada en Arch detectada: $DETECTED_DISTRO"
            elif [[ "$DISTRO_LIKE" =~ fedora ]]; then
                log_debug "Distribución basada en Fedora detectada: $DETECTED_DISTRO"
            fi
            ;;
    esac
    
    log_debug "Distribución detectada: $DETECTED_DISTRO (like: $DISTRO_LIKE, version: $DISTRO_VERSION)"
}

# Detectar arquitectura del sistema
detect_architecture() {
    case "$ARCH" in
        "x86_64"|"amd64")
            ARCH="x86_64"
            ;;
        "aarch64"|"arm64")
            ARCH="aarch64"
            ;;
        "armv7l"|"armhf")
            ARCH="armv7l"
            ;;
        *)
            log_warning "Arquitectura no común detectada: $ARCH"
            ;;
    esac
    
    log_debug "Arquitectura normalizada: $ARCH"
}

# Detectar tipo de virtualización
detect_virtualization() {
    # Verificar systemd-detect-virt si está disponible
    if command_exists systemd-detect-virt; then
        local virt_output
        virt_output=$(systemd-detect-virt 2>/dev/null)
        if [ $? -eq 0 ] && [ "$virt_output" != "none" ]; then
            VIRT_TYPE="$virt_output"
            log_debug "Virtualización detectada (systemd): $VIRT_TYPE"
            return
        fi
    fi
    
    # Detección manual de virtualización
    if [ -d /proc/xen ]; then
        VIRT_TYPE="xen"
    elif grep -q "QEMU" /proc/cpuinfo 2>/dev/null; then
        VIRT_TYPE="qemu"
    elif grep -q "VMware" /proc/cpuinfo 2>/dev/null; then
        VIRT_TYPE="vmware"
    elif [ -d /proc/vz ]; then
        VIRT_TYPE="openvz"
    elif dmesg | grep -q "Hypervisor detected" 2>/dev/null; then
        VIRT_TYPE="hypervisor"
    elif [ "$IS_CONTAINER" = true ]; then
        # Ya detectado en detect_special_environments
        :
    else
        VIRT_TYPE="none"
    fi
    
    log_debug "Tipo de virtualización: $VIRT_TYPE"
}

# =============================================================================
# FUNCIONES DE ANÁLISIS DE REQUISITOS
# =============================================================================

# Verificar requisitos del sistema
check_system_requirements() {
    log_message "Verificando requisitos del sistema" "INFO"
    
    local requirements_met=true
    
    # Verificar arquitectura soportada
    case "$ARCH" in
        "x86_64"|"aarch64")
            echo "✅ Arquitectura soportada: $ARCH"
            ;;
        *)
            echo "❌ Arquitectura no soportada: $ARCH"
            requirements_met=false
            ;;
    esac
    
    # Verificar versión de kernel
    check_kernel_version || requirements_met=false
    
    # Verificar espacio en disco
    check_disk_space || requirements_met=false
    
    # Verificar memoria RAM
    check_memory || requirements_met=false
    
    # Verificar dependencias críticas
    check_critical_dependencies || requirements_met=false
    
    if [ "$requirements_met" = true ]; then
        echo "✅ Todos los requisitos del sistema se cumplen"
        return 0
    else
        echo "❌ Algunos requisitos del sistema no se cumplen"
        return 1
    fi
}

# Verificar versión del kernel
check_kernel_version() {
    local kernel_version
    kernel_version=$(uname -r | cut -d'-' -f1)
    local major_version
    major_version=$(echo "$kernel_version" | cut -d'.' -f1)
    local minor_version
    minor_version=$(echo "$kernel_version" | cut -d'.' -f2)
    
    # Waydroid requiere kernel >= 3.8 para binder
    if [ "$major_version" -gt 3 ] || ([ "$major_version" -eq 3 ] && [ "$minor_version" -ge 8 ]); then
        echo "✅ Versión de kernel soportada: $kernel_version"
        return 0
    else
        echo "❌ Versión de kernel muy antigua: $kernel_version (mínimo: 3.8)"
        return 1
    fi
}

# Verificar espacio en disco mejorado
check_disk_space() {
    log_debug "Verificando espacio en disco..."
    
    # Obtener espacio libre en GB usando awk (sin dependencia de bc)
    local free_space_kb
    free_space_kb=$(df / | awk 'NR==2 {print $4}')
    local free_space_gb=$((free_space_kb / 1024 / 1024))
    
    log_debug "Espacio libre detectado: ${free_space_gb}GB"
    
    local required_space=10
    
    if [ "$free_space_gb" -ge "$required_space" ]; then
        echo "✅ Espacio en disco suficiente: ${free_space_gb}GB (requerido: ${required_space}GB)"
        return 0
    else
        echo "❌ Espacio en disco insuficiente: ${free_space_gb}GB (requerido: ${required_space}GB)"
        return 1
    fi
}

# Verificar memoria RAM
check_memory() {
    local total_mem_kb
    total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    
    local required_mem=2
    
    if [ "$total_mem_gb" -ge "$required_mem" ]; then
        echo "✅ Memoria suficiente: ${total_mem_gb}GB (requerido: ${required_mem}GB)"
        return 0
    else
        echo "⚠️ Memoria limitada: ${total_mem_gb}GB (recomendado: ${required_mem}GB)"
        return 0  # No es crítico, solo advertencia
    fi
}

# Verificar dependencias críticas del sistema
check_critical_dependencies() {
    local critical_commands=("bash" "curl" "wget" "awk" "grep" "sed")
    local missing_commands=()
    
    for cmd in "${critical_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -eq 0 ]; then
        echo "✅ Dependencias críticas disponibles"
        return 0
    else
        echo "❌ Dependencias críticas faltantes: ${missing_commands[*]}"
        return 1
    fi
}

# =============================================================================
# FUNCIONES DE SUGERENCIAS
# =============================================================================

# Determinar instalación sugerida basada en la detección
determine_suggested_installation() {
    if [ -n "${DISTRO_INFO[$DETECTED_DISTRO]}" ]; then
        SUGGESTED_INSTALLATION="$DETECTED_DISTRO"
    elif [ -n "$DISTRO_LIKE" ]; then
        # Intentar con la distribución base
        for base_distro in $DISTRO_LIKE; do
            if [ -n "${DISTRO_INFO[$base_distro]}" ]; then
                SUGGESTED_INSTALLATION="$base_distro"
                break
            fi
        done
    fi
    
    # Casos especiales
    case "$DETECTED_DISTRO" in
        "wsl")
            SUGGESTED_INSTALLATION="wsl-ubuntu"
            ;;
        "chromeos")
            SUGGESTED_INSTALLATION="chromeos-crostini"
            ;;
        "steamos")
            SUGGESTED_INSTALLATION="steamos-deck"
            ;;
    esac
    
    if [ -z "$SUGGESTED_INSTALLATION" ]; then
        SUGGESTED_INSTALLATION="generic-fallback"
    fi
    
    log_debug "Instalación sugerida: $SUGGESTED_INSTALLATION"
}

# Mostrar información de la instalación sugerida
show_suggested_installation() {
    if [ -n "$SUGGESTED_INSTALLATION" ] && [ "$SUGGESTED_INSTALLATION" != "generic-fallback" ]; then
        echo "💡 Instalación recomendada para $DETECTED_DISTRO: $SUGGESTED_INSTALLATION"
        
        # Mostrar información adicional si está disponible
        if [ -n "${DISTRO_INFO[$SUGGESTED_INSTALLATION]}" ]; then
            local info="${DISTRO_INFO[$SUGGESTED_INSTALLATION]}"
            local pkg_manager=$(echo "$info" | cut -d':' -f1)
            local repo_type=$(echo "$info" | cut -d':' -f2)
            
            echo "  📦 Gestor de paquetes: $pkg_manager"
            echo "  🏪 Repositorio: $repo_type"
        fi
        
        return 0
    else
        echo "⚠️ Distribución no detectada automáticamente, usar instalación manual"
        return 1
    fi
}

# =============================================================================
# FUNCIONES DE INFORMACIÓN DEL SISTEMA
# =============================================================================

# Mostrar resumen completo del sistema
display_system_summary() {
    echo ""
    echo "📊 Resumen del Sistema"
    echo "========================"
    echo "🐧 Distribución: $DETECTED_DISTRO"
    [ -n "$DISTRO_VERSION" ] && echo "📋 Versión: $DISTRO_VERSION"
    [ -n "$DISTRO_LIKE" ] && echo "🔗 Basada en: $DISTRO_LIKE"
    echo "🏗️ Arquitectura: $ARCH"
    echo "🔧 Kernel: $KERNEL_VERSION"
    echo "🌐 Virtualización: $VIRT_TYPE"
    [ "$IS_WSL" = true ] && echo "🪟 WSL: Sí (v$DISTRO_VERSION)"
    [ "$IS_CHROMEOS" = true ] && echo "💻 ChromeOS: Sí"
    [ "$IS_CONTAINER" = true ] && echo "📦 Contenedor: Sí ($VIRT_TYPE)"
    echo "========================"
    echo ""
}

# Mostrar información detallada del sistema para debug
show_detailed_system_info() {
    echo "🔍 Información Detallada del Sistema"
    echo "====================================="
    
    # Información del SO
    echo "--- Sistema Operativo ---"
    echo "Distribución: $DETECTED_DISTRO"
    echo "Familia: $DISTRO_LIKE"
    echo "Versión: $DISTRO_VERSION"
    echo "Kernel: $KERNEL_VERSION"
    echo "Arquitectura: $ARCH"
    
    # Información de hardware
    echo ""
    echo "--- Hardware ---"
    local cpu_info
    cpu_info=$(lscpu 2>/dev/null | grep "Model name" | awk -F: '{print $2}' | xargs || echo "No detectado")
    echo "CPU: $cpu_info"
    
    local ram_info
    ram_info=$(free -h 2>/dev/null | grep "Mem:" | awk '{print $2}' || echo "No detectado")
    echo "RAM: $ram_info"
    
    local disk_info
    disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}' || echo "No detectado")
    echo "Espacio libre: $disk_info"
    
    # Información de virtualización
    echo ""
    echo "--- Virtualización ---"
    echo "Tipo: $VIRT_TYPE"
    echo "WSL: $IS_WSL"
    echo "ChromeOS: $IS_CHROMEOS"
    echo "Contenedor: $IS_CONTAINER"
    
    # Información del entorno
    echo ""
    echo "--- Entorno ---"
    echo "Usuario: $(whoami)"
    echo "Directorio: $(pwd)"
    echo "PATH: $PATH"
    
    echo "====================================="
}

# =============================================================================
# INICIALIZACIÓN DEL MÓDULO
# =============================================================================

# Función de inicialización del módulo system
init_system_module() {
    log_message "Inicializando módulo system" "INFO"
    
    # Verificar dependencias básicas
    local required_commands=("uname" "awk" "grep" "cut")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            log_error "Comando requerido no encontrado: $cmd"
            return 1
        fi
    done
    
    log_message "Módulo system inicializado correctamente" "INFO"
    return 0
}

# Auto-inicializar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Cargar core si no está cargado
    if ! function_exists "log_message"; then
        source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
    fi
    
    init_system_module
    detect_distribution
    check_system_requirements
    show_suggested_installation
    echo "✅ Módulo system ejecutado correctamente"
fi