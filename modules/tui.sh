#!/bin/bash
# =============================================================================
# MÓDULO TUI - INTERFAZ DE USUARIO DE TEXTO
# =============================================================================
# Proporciona interfaces de usuario basadas en texto usando dialog/whiptail
# Soporte para modo interactivo y modo silencioso
# =============================================================================

# =============================================================================
# VARIABLES DE CONFIGURACIÓN TUI
# =============================================================================

TUI_TITLE="Waydroid Mega Installer v2.0"
TUI_BACKTITLE="Sistema de Instalación Modular de Waydroid - MiniMax Agent"
TUI_HEIGHT=${TUI_HEIGHT:-20}
TUI_WIDTH=${TUI_WIDTH:-70}
TUI_MENU_HEIGHT=${TUI_MENU_HEIGHT:-12}

# Detectar herramienta de diálogo disponible
TUI_TOOL=""

# =============================================================================
# FUNCIONES DE DETECCIÓN Y CONFIGURACIÓN
# =============================================================================

# Detecta qué herramienta de TUI está disponible
detect_tui_tool() {
    if command -v dialog >/dev/null 2>&1; then
        TUI_TOOL="dialog"
        log_message "✅ Usando dialog para TUI"
        return 0
    elif command -v whiptail >/dev/null 2>&1; then
        TUI_TOOL="whiptail"
        log_message "✅ Usando whiptail para TUI"
        return 0
    else
        log_message "⚠️  No se encontró dialog ni whiptail, usando modo texto simple"
        TUI_TOOL="none"
        return 1
    fi
}

# Instala la herramienta de diálogo si no está disponible
install_tui_tool() {
    if [ "$TUI_TOOL" = "none" ]; then
        log_message "📦 Instalando dialog para mejorar la experiencia..."
        
        if [ "$PACKAGE_MANAGER" = "apt" ]; then
            sudo apt update && sudo apt install -y dialog
        elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
            sudo pacman -S --noconfirm dialog
        elif [ "$PACKAGE_MANAGER" = "dnf" ]; then
            sudo dnf install -y dialog
        elif [ "$PACKAGE_MANAGER" = "zypper" ]; then
            sudo zypper install -y dialog
        fi
        
        # Redetectar después de la instalación
        detect_tui_tool
    fi
}

# =============================================================================
# FUNCIONES DE INTERFAZ BÁSICA
# =============================================================================

# Ejecuta un comando de dialog/whiptail con parámetros comunes
tui_exec() {
    if [ "$TUI_TOOL" = "none" ]; then
        return 1
    fi
    
    $TUI_TOOL --backtitle "$TUI_BACKTITLE" "$@"
}

# Muestra un mensaje informativo
tui_msgbox() {
    local title="$1"
    local message="$2"
    local height=${3:-$TUI_HEIGHT}
    local width=${4:-$TUI_WIDTH}
    
    if [ "$TUI_TOOL" = "none" ]; then
        echo "=== $title ==="
        echo "$message"
        echo
        read -p "Presiona Enter para continuar..."
        return 0
    fi
    
    tui_exec --title "$title" --msgbox "$message" $height $width
}

# Muestra una pregunta sí/no
tui_yesno() {
    local title="$1"
    local question="$2"
    local height=${3:-$TUI_HEIGHT}
    local width=${4:-$TUI_WIDTH}
    
    if [ "$TUI_TOOL" = "none" ]; then
        echo "=== $title ==="
        echo "$question"
        while true; do
            read -p "¿Continuar? (s/n): " yn
            case $yn in
                [Ss]* ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Por favor responde sí (s) o no (n).";;
            esac
        done
    fi
    
    tui_exec --title "$title" --yesno "$question" $height $width
}

# Muestra un menú de selección
tui_menu() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    local menu_height="$5"
    shift 5
    
    if [ "$TUI_TOOL" = "none" ]; then
        echo "=== $title ==="
        echo "$message"
        echo
        local i=1
        while [ $# -gt 0 ]; do
            echo "$i) $2"
            shift 2
            ((i++))
        done
        echo
        read -p "Selecciona una opción: " choice
        echo "$choice"
        return 0
    fi
    
    tui_exec --title "$title" --menu "$message" $height $width $menu_height "$@" 2>&1
}

# Muestra una lista de verificación (checklist)
tui_checklist() {
    local title="$1"
    local message="$2"
    local height="$3"
    local width="$4"
    local list_height="$5"
    shift 5
    
    if [ "$TUI_TOOL" = "none" ]; then
        echo "=== $title ==="
        echo "$message"
        echo
        echo "Opciones disponibles (escribe los números separados por espacios):"
        local items=()
        local i=1
        while [ $# -gt 0 ]; do
            echo "$i) $2 [$3]"
            items+=("$1")
            shift 3
            ((i++))
        done
        echo
        read -p "Selecciona opciones: " selections
        echo "$selections"
        return 0
    fi
    
    tui_exec --title "$title" --checklist "$message" $height $width $list_height "$@" 2>&1
}

# Muestra una barra de progreso
tui_gauge() {
    local title="$1"
    local message="$2"
    local percent="$3"
    local height=${4:-8}
    local width=${5:-$TUI_WIDTH}
    
    if [ "$TUI_TOOL" = "none" ]; then
        echo "[$percent%] $message"
        return 0
    fi
    
    echo "$percent" | tui_exec --title "$title" --gauge "$message" $height $width 0
}

# =============================================================================
# PANTALLAS ESPECÍFICAS DEL INSTALADOR
# =============================================================================

# Pantalla de bienvenida
tui_welcome_screen() {
    local message="Bienvenido al Waydroid Mega Installer v2.0

Este instalador te ayudará a configurar Waydroid en tu sistema Linux de manera automatizada.

Características:
• Detección automática del sistema
• Instalación de dependencias
• Configuración de repositorios
• Descarga e instalación de Waydroid
• Validación de integridad de archivos
• Configuración inicial

¿Deseas continuar con la instalación?"

    tui_yesno "Bienvenida" "$message" 18 $TUI_WIDTH
}

# Pantalla de selección de componentes
tui_component_selection() {
    local message="Selecciona los componentes que deseas instalar:

Puedes seleccionar múltiples opciones usando ESPACIO y confirmar con ENTER."

    local components
    components=$(tui_checklist "Selección de Componentes" "$message" \
        $TUI_HEIGHT $TUI_WIDTH $TUI_MENU_HEIGHT \
        "waydroid-core" "Waydroid (núcleo principal)" "on" \
        "waydroid-props" "Propiedades del sistema" "on" \
        "waydroid-image" "Imagen del sistema Android" "on" \
        "google-apps" "Google Apps (GApps)" "off" \
        "f-droid" "F-Droid Store" "on" \
        "dev-tools" "Herramientas de desarrollo" "off" \
        "backup-tools" "Herramientas de respaldo" "off")
    
    echo "$components"
}

# Pantalla de configuración de red
tui_network_config() {
    local message="Configuración de red y descargas:

Selecciona las opciones de descarga y configuración de red."

    local network_options
    network_options=$(tui_checklist "Configuración de Red" "$message" \
        $TUI_HEIGHT $TUI_WIDTH $TUI_MENU_HEIGHT \
        "parallel-downloads" "Descargas paralelas (más rápido)" "on" \
        "verify-checksums" "Verificar integridad de archivos" "on" \
        "use-mirrors" "Usar servidores espejo" "on" \
        "retry-failed" "Reintentar descargas fallidas" "on")
    
    echo "$network_options"
}

# Pantalla de selección de distribución
tui_distribution_selection() {
    local detected_distro="$1"
    local message="Sistema detectado: $detected_distro

¿Deseas continuar con la configuración automática o seleccionar manualmente?"

    local choice
    choice=$(tui_menu "Configuración del Sistema" "$message" \
        $TUI_HEIGHT $TUI_WIDTH $TUI_MENU_HEIGHT \
        "auto" "Configuración automática (recomendado)" \
        "manual" "Selección manual de distribución" \
        "advanced" "Configuración avanzada")
    
    echo "$choice"
}

# Pantalla de configuración avanzada
tui_advanced_config() {
    local message="Configuración avanzada del sistema:

Estas opciones son para usuarios experimentados."

    local advanced_options
    advanced_options=$(tui_checklist "Configuración Avanzada" "$message" \
        $TUI_HEIGHT $TUI_WIDTH $TUI_MENU_HEIGHT \
        "custom-kernel" "Compilar módulos del kernel" "off" \
        "gpu-acceleration" "Habilitar aceleración GPU" "on" \
        "audio-support" "Soporte completo de audio" "on" \
        "networking-bridge" "Configurar puente de red" "off" \
        "selinux-config" "Configurar SELinux/AppArmor" "off" \
        "debug-mode" "Modo de depuración" "off")
    
    echo "$advanced_options"
}

# Pantalla de confirmación final
tui_final_confirmation() {
    local components="$1"
    local network_config="$2"
    local advanced_config="$3"
    
    local message="Resumen de la configuración:

Componentes seleccionados:
$components

Configuración de red:
$network_config

Configuración avanzada:
$advanced_config

¿Confirmas que deseas proceder con la instalación?"

    tui_yesno "Confirmación Final" "$message" 22 $TUI_WIDTH
}

# Pantalla de progreso de instalación
tui_installation_progress() {
    local step="$1"
    local total_steps="$2"
    local current_task="$3"
    
    local percent=$(( (step * 100) / total_steps ))
    local message="Paso $step de $total_steps: $current_task"
    
    tui_gauge "Instalando Waydroid" "$message" "$percent"
}

# Pantalla de resultado final
tui_final_result() {
    local success="$1"
    local log_file="$2"
    
    if [ "$success" = "true" ]; then
        local message="¡Instalación completada exitosamente!

Waydroid ha sido instalado y configurado correctamente en tu sistema.

Para iniciar Waydroid, ejecuta:
  waydroid show-full-ui

Para más información, consulta:
  waydroid --help

Log de instalación guardado en:
$log_file"
        
        tui_msgbox "Instalación Exitosa" "$message" 20 $TUI_WIDTH
    else
        local message="❌ La instalación ha fallado

Se ha producido un error durante la instalación de Waydroid.

Por favor, revisa el log de errores en:
$log_file

Puedes ejecutar el instalador nuevamente o reportar el problema."
        
        tui_msgbox "Error de Instalación" "$message" 16 $TUI_WIDTH
    fi
}

# =============================================================================
# FUNCIONES DE CONTROL DE FLUJO
# =============================================================================

# Ejecuta el flujo completo de TUI
run_tui_installer() {
    log_message "🎨 Iniciando interfaz TUI..."
    
    # Detectar e instalar herramienta TUI si es necesario
    detect_tui_tool
    if [ "$TUI_TOOL" = "none" ]; then
        install_tui_tool
    fi
    
    # Pantalla de bienvenida
    if ! tui_welcome_screen; then
        log_message "❌ Usuario canceló la instalación"
        return 1
    fi
    
    # Detección del sistema
    tui_gauge "Analizando Sistema" "Detectando distribución y configuración..." 10
    analyze_system
    
    # Selección de distribución
    local distro_choice
    distro_choice=$(tui_distribution_selection "$DETECTED_DISTRO")
    
    if [ "$distro_choice" = "manual" ]; then
        # Aquí se podría implementar selección manual
        log_message "⚠️  Selección manual no implementada aún, usando detección automática"
    fi
    
    # Selección de componentes
    local selected_components
    selected_components=$(tui_component_selection)
    
    if [ -z "$selected_components" ]; then
        tui_msgbox "Error" "No se seleccionaron componentes para instalar."
        return 1
    fi
    
    # Configuración de red
    local network_config
    network_config=$(tui_network_config)
    
    # Configuración avanzada (opcional)
    local advanced_config=""
    if echo "$distro_choice" | grep -q "advanced"; then
        advanced_config=$(tui_advanced_config)
    fi
    
    # Confirmación final
    if ! tui_final_confirmation "$selected_components" "$network_config" "$advanced_config"; then
        log_message "❌ Usuario canceló la instalación en la confirmación final"
        return 1
    fi
    
    # Proceso de instalación
    tui_installation_progress 1 5 "Instalando dependencias del sistema..."
    install_system_dependencies
    
    tui_installation_progress 2 5 "Configurando repositorios..."
    setup_waydroid_repository
    
    tui_installation_progress 3 5 "Descargando Waydroid..."
    install_waydroid_package
    
    tui_installation_progress 4 5 "Descargando imágenes del sistema..."
    download_system_images
    
    tui_installation_progress 5 5 "Configuración final..."
    configure_waydroid
    
    # Resultado final
    if [ $? -eq 0 ]; then
        tui_final_result "true" "$LOG_FILE"
        return 0
    else
        tui_final_result "false" "$LOG_FILE"
        return 1
    fi
}

# Verificar si se debe usar TUI
should_use_tui() {
    # No usar TUI si:
    # - Se pasaron argumentos específicos
    # - Variable de entorno NO_TUI está establecida
    # - No hay terminal interactivo
    
    if [ $# -gt 0 ]; then
        return 1  # Hay argumentos, usar modo CLI
    fi
    
    if [ -n "$NO_TUI" ]; then
        return 1  # Variable NO_TUI establecida
    fi
    
    if [ ! -t 0 ] || [ ! -t 1 ]; then
        return 1  # No hay terminal interactivo
    fi
    
    return 0  # Usar TUI
}

# =============================================================================
# FUNCIONES DE AYUDA
# =============================================================================

# Muestra ayuda sobre el uso del TUI
show_tui_help() {
    cat << 'EOF'
=== AYUDA DEL TUI ===

El Waydroid Mega Installer soporta dos modos de operación:

1. MODO INTERACTIVO (TUI):
   - Se activa automáticamente cuando no se pasan argumentos
   - Proporciona una interfaz gráfica de texto fácil de usar
   - Guía paso a paso a través del proceso de instalación

2. MODO LÍNEA DE COMANDOS:
   - Se activa cuando se pasan argumentos específicos
   - Permite automatización y scripting
   - Útil para instalaciones desatendidas

EJEMPLOS DE USO:

  # Modo interactivo (TUI)
  ./waydroid_installer_modular.sh

  # Modo línea de comandos
  ./waydroid_installer_modular.sh --install --gapps

  # Deshabilitar TUI forzosamente
  NO_TUI=1 ./waydroid_installer_modular.sh

REQUISITOS PARA TUI:
  - Terminal interactivo
  - dialog o whiptail (se instala automáticamente si falta)

EOF
}

log_message "✅ Módulo TUI cargado correctamente"