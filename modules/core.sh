#!/bin/bash
# =============================================================================
# MÓDULO CORE - Funciones básicas del sistema
# =============================================================================
# Funcionalidades centrales: logging, error handling, limpieza
# Versión: 2.0 - Octubre 2025

# Variables globales del core
declare -g LOG_FILE="/var/log/waydroid_install.log"
declare -g DEBUG_MODE=${DEBUG_MODE:-0}
declare -g ORIGINAL_DIR="$(pwd)"
declare -g SCRIPT_VERSION="2.0.0"
declare -g SCRIPT_NAME="Waydroid Mega Installer"

# =============================================================================
# FUNCIONES DE LOGGING
# =============================================================================

# Función de logging que no interfiere con dialog/read
log_message() {
    local level="${2:-INFO}"
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Crear directorio de log si no existe
    sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    
    # Escribir al log con formato estructurado
    echo "[$timestamp] [$level] $message" | sudo tee -a "$LOG_FILE" >/dev/null 2>&1
    
    # Mostrar en stderr si está en modo debug
    if [ "$DEBUG_MODE" -eq 1 ]; then
        echo "[$level] $message" >&2
    fi
}

# Función de logging específica para errores
log_error() {
    log_message "$1" "ERROR"
}

# Función de logging específica para warnings
log_warning() {
    log_message "$1" "WARNING"
}

# Función de logging específica para debug
log_debug() {
    if [ "$DEBUG_MODE" -eq 1 ]; then
        log_message "$1" "DEBUG"
    fi
}

# =============================================================================
# GESTIÓN DE ERRORES
# =============================================================================

# Función mejorada para manejar errores con contexto
handle_error() {
    local error_msg="$1"
    local error_code="${2:-1}"
    local context="${3:-unknown}"
    
    log_error "Context: $context - $error_msg"
    
    echo "❌ Error: $error_msg" >&2
    echo "📋 Contexto: $context" >&2
    echo "📋 Revisa $LOG_FILE para detalles completos." >&2
    
    # Ejecutar limpieza
    cleanup_on_error "$context"
    
    exit "$error_code"
}

# Función de limpieza mejorada con contexto
cleanup_on_error() {
    local context="${1:-general}"
    
    log_message "Ejecutando limpieza por error en contexto: $context" "WARNING"
    
    # Volver al directorio original
    cd "$ORIGINAL_DIR" 2>/dev/null || true
    
    # Limpiar descargas incompletas
    cleanup_partial_downloads
    
    # Limpiar procesos específicos según contexto
    case "$context" in
        "download")
            cleanup_download_context
            ;;
        "installation")
            cleanup_installation_context
            ;;
        "module")
            cleanup_module_context
            ;;
    esac
    
    log_message "Limpieza completada para contexto: $context" "INFO"
}

# Limpiar descargas parciales
cleanup_partial_downloads() {
    local partial_files=(
        "$HOME/system-tv13.img.xz.partial"
        "$HOME/vendor-tv13.img.xz.partial"
        "/tmp/waydroid_temp_*"
        "/tmp/anbox-modules-*"
    )
    
    for file_pattern in "${partial_files[@]}"; do
        rm -f $file_pattern 2>/dev/null || true
    done
    
    log_debug "Partial downloads cleaned"
}

# Limpiar contexto de descarga
cleanup_download_context() {
    # Terminar descargas en progreso
    pkill -f "wget.*waydroid" 2>/dev/null || true
    pkill -f "curl.*waydroid" 2>/dev/null || true
    
    log_debug "Download context cleaned"
}

# Limpiar contexto de instalación
cleanup_installation_context() {
    # Detener servicios si están ejecutándose
    systemctl --user stop waydroid-container.service 2>/dev/null || true
    
    log_debug "Installation context cleaned"
}

# Limpiar contexto de módulos
cleanup_module_context() {
    # Descargar módulos temporales si aplica
    log_debug "Module context cleaned"
}

# =============================================================================
# FUNCIONES DE UTILIDAD
# =============================================================================

# Función segura para cambio de directorio con validación
safe_cd() {
    local target_dir="$1"
    local context="${2:-directory_change}"
    
    if [ -z "$target_dir" ]; then
        handle_error "safe_cd: directorio no especificado" 2 "$context"
    fi
    
    if [ ! -d "$target_dir" ]; then
        handle_error "Directorio no existe: $target_dir" 3 "$context"
    fi
    
    if ! cd "$target_dir" 2>/dev/null; then
        handle_error "No se pudo cambiar al directorio: $target_dir" 4 "$context"
    fi
    
    log_debug "Changed directory to: $(pwd)"
}

# Verificar si una función existe
function_exists() {
    declare -f "$1" > /dev/null
    return $?
}

# Verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para mostrar progreso
show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    local percentage=$((current * 100 / total))
    
    printf "\r🔄 %s: [%-50s] %d%% (%d/%d)" \
        "$description" \
        "$(printf '#%.0s' $(seq 1 $((percentage / 2))))" \
        "$percentage" \
        "$current" \
        "$total"
    
    if [ "$current" -eq "$total" ]; then
        echo " ✅"
    fi
}

# Función para pausar con timeout
pause_with_timeout() {
    local timeout="${1:-10}"
    local message="${2:-Presiona Enter para continuar}"
    
    echo -n "$message [${timeout}s timeout]: "
    read -t "$timeout" || echo -e "\n⏰ Timeout alcanzado, continuando..."
}

# Función para verificar privilegios
check_privileges() {
    local required_level="$1"  # "user" o "sudo"
    
    case "$required_level" in
        "user")
            if [ "$EUID" -eq 0 ]; then
                log_warning "Ejecutándose como root, pero se requiere usuario normal"
                return 1
            fi
            ;;
        "sudo")
            if ! sudo -n true 2>/dev/null; then
                echo "🔐 Se requieren privilegios sudo para esta operación"
                if ! sudo true; then
                    handle_error "No se pudieron obtener privilegios sudo" 5 "privileges"
                fi
            fi
            ;;
    esac
    
    return 0
}

# =============================================================================
# INICIALIZACIÓN DEL MÓDULO
# =============================================================================

# Función de inicialización del módulo core
init_core_module() {
    log_message "Inicializando módulo core v$SCRIPT_VERSION" "INFO"
    
    # Crear directorio de log si no existe
    sudo mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    
    # Configurar traps para limpieza automática
    trap 'cleanup_on_error "signal_interrupt"' INT TERM
    
    # Verificar dependencias básicas
    local required_commands=("bash" "date" "pwd" "whoami")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            handle_error "Comando requerido no encontrado: $cmd" 10 "core_init"
        fi
    done
    
    log_message "Módulo core inicializado correctamente" "INFO"
    return 0
}

# Auto-inicializar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_core_module
    echo "✅ Módulo core inicializado correctamente"
fi