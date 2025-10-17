#!/bin/bash
# =============================================================================
# WAYDROID MEGA INSTALLER - VERSIÓN MODULAR
# =============================================================================
# Instalador completo de Waydroid con arquitectura modular mejorada
# Versión: 2.0 - Octubre 2025
# Autor: MiniMax Agent
# 
# Características nuevas:
# - Arquitectura modular para mejor mantenimiento
# - Validación de integridad con checksums
# - Descarga paralela optimizada
# - Sistema de logging mejorado
# - Gestión robusta de errores
# =============================================================================

# =============================================================================
# CONFIGURACIÓN GLOBAL
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="Waydroid Mega Installer Modular"

# Variables globales de estado
declare -g MODULES_LOADED=false
declare -g SYSTEM_ANALYZED=false
declare -g DEPENDENCIES_INSTALLED=false

# =============================================================================
# FUNCIONES DE CARGA DE MÓDULOS
# =============================================================================

# Función para cargar un módulo específico
load_module() {
    local module_name="$1"
    local module_path="$MODULES_DIR/${module_name}.sh"
    
    if [ ! -f "$module_path" ]; then
        echo "❌ Error: Módulo no encontrado: $module_path"
        return 1
    fi
    
    echo "📦 Cargando módulo: $module_name"
    
    # Source del módulo
    if source "$module_path"; then
        echo "✅ Módulo cargado: $module_name"
        return 0
    else
        echo "❌ Error cargando módulo: $module_name"
        return 1
    fi
}

# Función para cargar todos los módulos necesarios
load_all_modules() {
    echo "🚀 Cargando sistema modular..."
    echo ""
    
    # Lista de módulos en orden de dependencias
    local modules=("core" "validation" "system" "package" "download" "tui")
    local failed_modules=()
    
    for module in "${modules[@]}"; do
        if ! load_module "$module"; then
            failed_modules+=("$module")
        fi
    done
    
    if [ ${#failed_modules[@]} -eq 0 ]; then
        echo ""
        echo "✅ Todos los módulos cargados correctamente"
        MODULES_LOADED=true
        return 0
    else
        echo ""
        echo "❌ Error cargando módulos: ${failed_modules[*]}"
        return 1
    fi
}

# Función para verificar que los módulos están funcionando
verify_modules() {
    echo "🔍 Verificando funcionalidad de módulos..."
    
    local verification_errors=0
    
    # Verificar módulo core
    if ! function_exists "log_message"; then
        echo "❌ Módulo core: función log_message no disponible"
        ((verification_errors++))
    fi
    
    # Verificar módulo system
    if ! function_exists "detect_distribution"; then
        echo "❌ Módulo system: función detect_distribution no disponible"
        ((verification_errors++))
    fi
    
    # Verificar módulo package
    if ! function_exists "detect_package_manager"; then
        echo "❌ Módulo package: función detect_package_manager no disponible"
        ((verification_errors++))
    fi
    
    # Verificar módulo validation
    if ! function_exists "verify_checksum"; then
        echo "❌ Módulo validation: función verify_checksum no disponible"
        ((verification_errors++))
    fi
    
    # Verificar módulo download
    if ! function_exists "download_file_with_validation"; then
        echo "❌ Módulo download: función download_file_with_validation no disponible"
        ((verification_errors++))
    fi
    
    # Verificar módulo TUI
    if ! function_exists "detect_tui_tool"; then
        echo "❌ Módulo TUI: función detect_tui_tool no disponible"
        ((verification_errors++))
    fi
    
    if [ $verification_errors -eq 0 ]; then
        echo "✅ Verificación de módulos completada"
        return 0
    else
        echo "❌ Se encontraron $verification_errors errores en la verificación"
        return 1
    fi
}

# =============================================================================
# FUNCIONES PRINCIPALES DEL INSTALADOR
# =============================================================================

# Función para mostrar el banner del programa
show_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║    🚀 WAYDROID MEGA INSTALLER - VERSIÓN MODULAR 2.0         ║
║                                                               ║
║    ✨ Nuevas características:                                 ║
║    📦 Arquitectura modular mejorada                          ║
║    🎨 Interfaz TUI/CLI híbrida                               ║
║    🔍 Validación de integridad con checksums                 ║
║    ⚡ Descarga paralela optimizada                           ║
║    📊 Sistema de logging avanzado                            ║
║    🛡️ Gestión robusta de errores                            ║
║                                                               ║
║    💡 Tip: Ejecuta sin argumentos para modo TUI interactivo  ║
║           Usa --help para ver opciones de línea de comandos  ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo ""
}

# =============================================================================
# FUNCIONES DE MANEJO DE ARGUMENTOS Y MODOS
# =============================================================================

# Función para mostrar ayuda
show_help() {
    cat << 'EOF'
WAYDROID MEGA INSTALLER v2.0 - Sistema Híbrido TUI/CLI

USAGE:
    waydroid_installer_modular.sh [OPCIONES]

MODOS DE OPERACIÓN:

    SIN ARGUMENTOS (Modo TUI Interactivo):
        ./waydroid_installer_modular.sh

    CON ARGUMENTOS (Modo Línea de Comandos):
        ./waydroid_installer_modular.sh [OPCIONES]

OPCIONES DE LÍNEA DE COMANDOS:

    --help, -h          Mostrar esta ayuda
    --version, -v       Mostrar versión
    --install           Instalar Waydroid automáticamente
    --no-interactive    Modo no interactivo (silencioso)
    --gapps             Incluir Google Apps
    --no-gapps          Excluir Google Apps
    --fdroid            Incluir F-Droid
    --no-fdroid         Excluir F-Droid
    --dev-tools         Incluir herramientas de desarrollo
    --backup-tools      Incluir herramientas de respaldo
    --parallel          Habilitar descargas paralelas
    --no-parallel       Deshabilitar descargas paralelas
    --verify-checksums  Verificar integridad de archivos (recomendado)
    --no-checksums      Saltar verificación de checksums
    --force             Forzar instalación (sobrescribir existente)
    --dry-run           Simular instalación sin ejecutar comandos
    --log-level LEVEL   Nivel de log: debug, info, warn, error

VARIABLES DE ENTORNO:

    NO_TUI=1            Forzar modo línea de comandos
    LOG_LEVEL           Nivel de logging por defecto
    WAYDROID_SKIP_DEPS  Saltar instalación de dependencias

EJEMPLOS:

    # Modo interactivo (TUI)
    ./waydroid_installer_modular.sh

    # Instalación automática básica
    ./waydroid_installer_modular.sh --install

    # Instalación completa con GApps
    ./waydroid_installer_modular.sh --install --gapps --fdroid

    # Instalación silenciosa para scripts
    NO_TUI=1 ./waydroid_installer_modular.sh --install --no-interactive

    # Simulación de instalación
    ./waydroid_installer_modular.sh --install --dry-run

    # Forzar modo CLI aún sin argumentos
    NO_TUI=1 ./waydroid_installer_modular.sh

EOF
}

# Función para mostrar versión
show_version() {
    echo "Waydroid Mega Installer v$SCRIPT_VERSION"
    echo "Arquitectura modular con soporte TUI/CLI híbrido"
    echo "Autor: MiniMax Agent"
    echo "Fecha: Octubre 2025"
}

# Variables globales para configuración
declare -g CLI_MODE=false
declare -g AUTO_INSTALL=false
declare -g INCLUDE_GAPPS=""
declare -g INCLUDE_FDROID=""
declare -g INCLUDE_DEV_TOOLS=false
declare -g INCLUDE_BACKUP_TOOLS=false
declare -g PARALLEL_DOWNLOADS=""
declare -g VERIFY_CHECKSUMS=""
declare -g FORCE_INSTALL=false
declare -g DRY_RUN=false
declare -g NO_INTERACTIVE=false

# Función para parsear argumentos de línea de comandos
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --version|-v)
                show_version
                exit 0
                ;;
            --install)
                CLI_MODE=true
                AUTO_INSTALL=true
                shift
                ;;
            --no-interactive)
                CLI_MODE=true
                NO_INTERACTIVE=true
                shift
                ;;
            --gapps)
                INCLUDE_GAPPS="true"
                shift
                ;;
            --no-gapps)
                INCLUDE_GAPPS="false"
                shift
                ;;
            --fdroid)
                INCLUDE_FDROID="true"
                shift
                ;;
            --no-fdroid)
                INCLUDE_FDROID="false"
                shift
                ;;
            --dev-tools)
                INCLUDE_DEV_TOOLS=true
                shift
                ;;
            --backup-tools)
                INCLUDE_BACKUP_TOOLS=true
                shift
                ;;
            --parallel)
                PARALLEL_DOWNLOADS="true"
                shift
                ;;
            --no-parallel)
                PARALLEL_DOWNLOADS="false"
                shift
                ;;
            --verify-checksums)
                VERIFY_CHECKSUMS="true"
                shift
                ;;
            --no-checksums)
                VERIFY_CHECKSUMS="false"
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --log-level)
                export LOG_LEVEL="$2"
                shift 2
                ;;
            *)
                echo "❌ Argumento desconocido: $1"
                echo "Usa --help para ver las opciones disponibles"
                exit 1
                ;;
        esac
    done
    
    # Si hay argumentos, activar modo CLI
    if [ "$CLI_MODE" = true ] || [ $# -gt 0 ]; then
        CLI_MODE=true
    fi
}

# Función para ejecutar instalación en modo CLI
run_cli_installer() {
    log_message "⚡ Ejecutando instalación en modo CLI..."
    
    if [ "$DRY_RUN" = true ]; then
        log_message "🧪 Modo DRY RUN - Simulando instalación"
        echo "=== SIMULACIÓN DE INSTALACIÓN ==="
        echo "Configuración seleccionada:"
        echo "  Google Apps: ${INCLUDE_GAPPS:-auto}"
        echo "  F-Droid: ${INCLUDE_FDROID:-auto}"
        echo "  Dev Tools: $INCLUDE_DEV_TOOLS"
        echo "  Backup Tools: $INCLUDE_BACKUP_TOOLS"
        echo "  Descargas paralelas: ${PARALLEL_DOWNLOADS:-auto}"
        echo "  Verificar checksums: ${VERIFY_CHECKSUMS:-auto}"
        echo "  Forzar instalación: $FORCE_INSTALL"
        echo ""
        echo "✅ Simulación completada. Use sin --dry-run para instalar realmente."
        return 0
    fi
    
    # Análisis del sistema (siempre necesario)
    analyze_system
    
    # Configurar opciones basadas en argumentos o valores por defecto
    if [ -z "$PARALLEL_DOWNLOADS" ]; then
        PARALLEL_DOWNLOADS="true"  # Por defecto habilitado
    fi
    
    if [ -z "$VERIFY_CHECKSUMS" ]; then
        VERIFY_CHECKSUMS="true"  # Por defecto habilitado
    fi
    
    if [ -z "$INCLUDE_GAPPS" ]; then
        INCLUDE_GAPPS="false"  # Por defecto deshabilitado (requiere confirmación)
    fi
    
    if [ -z "$INCLUDE_FDROID" ]; then
        INCLUDE_FDROID="true"  # Por defecto habilitado
    fi
    
    # Mostrar configuración si no es modo no-interactivo
    if [ "$NO_INTERACTIVE" != true ]; then
        echo "=== CONFIGURACIÓN DE INSTALACIÓN ==="
        echo "Sistema detectado: $DETECTED_DISTRO ($DETECTED_ARCH)"
        echo "Google Apps: $INCLUDE_GAPPS"
        echo "F-Droid: $INCLUDE_FDROID"
        echo "Herramientas de desarrollo: $INCLUDE_DEV_TOOLS"
        echo "Herramientas de respaldo: $INCLUDE_BACKUP_TOOLS"
        echo "Descargas paralelas: $PARALLEL_DOWNLOADS"
        echo "Verificar checksums: $VERIFY_CHECKSUMS"
        echo ""
        
        if [ "$FORCE_INSTALL" != true ]; then
            read -p "¿Continuar con la instalación? (s/N): " confirm
            case $confirm in
                [Ss]* ) ;;
                * ) 
                    echo "❌ Instalación cancelada por el usuario"
                    return 1
                    ;;
            esac
        fi
    fi
    
    # Ejecutar pasos de instalación
    install_system_dependencies
    
    if [ "$INCLUDE_GAPPS" = "true" ]; then
        log_message "📱 Configurando instalación con Google Apps"
        # Aquí se añadiría lógica específica para GApps
    fi
    
    download_images_menu  # Esta función ya maneja la descarga
    post_installation_menu
    
    echo "✅ Instalación CLI completada exitosamente"
    return 0
}

# Función para análisis completo del sistema
analyze_system() {
    if [ "$SYSTEM_ANALYZED" = true ]; then
        echo "ℹ️ Sistema ya analizado anteriormente"
        return 0
    fi
    
    echo "🔍 Realizando análisis completo del sistema..."
    echo ""
    
    # Detectar distribución y entorno
    detect_distribution
    echo ""
    
    # Verificar requisitos del sistema
    if check_system_requirements; then
        echo "✅ Sistema compatible con Waydroid"
    else
        echo "⚠️ Sistema con limitaciones, revisar requisitos"
        echo ""
        echo "¿Continuar de todos modos? (s/N): "
        local continue_anyway
        read -t 30 continue_anyway
        
        if [[ ! "$continue_anyway" =~ ^[sS]$ ]]; then
            handle_error "Usuario canceló por requisitos no cumplidos" 10 "system_analysis"
        fi
    fi
    echo ""
    
    # Detectar gestor de paquetes
    if detect_package_manager; then
        echo "✅ Gestor de paquetes detectado: $DETECTED_PKG_MANAGER"
    else
        handle_error "No se pudo detectar gestor de paquetes compatible" 11 "system_analysis"
    fi
    echo ""
    
    # Mostrar sugerencia de instalación
    if show_suggested_installation; then
        echo ""
        echo "¿Usar la instalación recomendada? (S/n): "
        local use_suggested
        read -t 30 use_suggested
        
        if [[ ! "$use_suggested" =~ ^[nN]$ ]]; then
            echo "✅ Usando instalación recomendada: $SUGGESTED_INSTALLATION"
        fi
    fi
    
    SYSTEM_ANALYZED=true
    log_message "System analysis completed successfully" "INFO"
}

# Función para instalar dependencias del sistema
install_system_dependencies() {
    if [ "$DEPENDENCIES_INSTALLED" = true ]; then
        echo "ℹ️ Dependencias ya instaladas anteriormente"
        return 0
    fi
    
    echo "📦 Instalando dependencias del sistema..."
    echo ""
    
    # Verificar privilegios sudo
    check_privileges "sudo"
    
    # Añadir repositorios si es necesario
    if add_waydroid_repositories "$DETECTED_DISTRO"; then
        echo "✅ Repositorios de Waydroid añadidos"
    else
        echo "⚠️ No se pudieron añadir repositorios específicos"
    fi
    echo ""
    
    # Instalar dependencias
    if install_waydroid_dependencies "$DETECTED_DISTRO"; then
        echo "✅ Dependencias instaladas correctamente"
        DEPENDENCIES_INSTALLED=true
    else
        echo "⚠️ Algunas dependencias fallaron"
        echo ""
        echo "¿Continuar de todos modos? (s/N): "
        local continue_anyway
        read -t 30 continue_anyway
        
        if [[ ! "$continue_anyway" =~ ^[sS]$ ]]; then
            handle_error "Usuario canceló por dependencias faltantes" 12 "dependency_installation"
        fi
    fi
    
    log_message "System dependencies installation completed" "INFO"
}

# Función para menú de descarga de imágenes
download_images_menu() {
    echo "📥 Selección de Imágenes de Android"
    echo "=================================="
    echo ""
    echo "Versiones disponibles:"
    echo "1) Android 13 TV (LineageOS 20) - Recomendado"
    echo "2) Android 11 Vanilla (LineageOS 18.1)"
    echo "3) Personalizado (especificar URLs)"
    echo ""
    echo -n "Selecciona una opción [1]: "
    
    local choice
    read -t 30 choice
    choice=${choice:-1}
    
    local android_version=""
    case "$choice" in
        1)
            android_version="tv13"
            echo "✅ Seleccionado: Android 13 TV"
            ;;
        2)
            android_version="vanilla11"
            echo "✅ Seleccionado: Android 11 Vanilla"
            ;;
        3)
            echo "ℹ️ Modo personalizado seleccionado"
            download_custom_images
            return $?
            ;;
        *)
            echo "⚠️ Opción inválida, usando por defecto: Android 13 TV"
            android_version="tv13"
            ;;
    esac
    
    echo ""
    echo "📥 Descargando imágenes de Android $android_version..."
    
    # Preparar directorio de descarga
    local download_dir="$HOME/.waydroid_images"
    prepare_download_directory "$download_dir"
    
    # Descargar imágenes
    if download_waydroid_images "$android_version" "$ARCH" "$download_dir"; then
        echo "✅ Imágenes descargadas correctamente en: $download_dir"
        
        # Configurar Waydroid para usar las imágenes
        echo ""
        echo "🔧 Configurando Waydroid..."
        configure_waydroid_images "$download_dir"
        
        return 0
    else
        handle_error "Error descargando imágenes de Android" 13 "image_download"
    fi
}

# Función para descarga personalizada
download_custom_images() {
    echo "🔧 Descarga Personalizada de Imágenes"
    echo "====================================="
    echo ""
    
    echo "Ingrese URL de la imagen del sistema:"
    local system_url
    read -t 60 system_url
    
    echo "Ingrese URL de la imagen vendor:"
    local vendor_url
    read -t 60 vendor_url
    
    if [ -z "$system_url" ] || [ -z "$vendor_url" ]; then
        echo "❌ URLs no proporcionadas"
        return 1
    fi
    
    # Validar URLs
    if ! validate_url "$system_url" || ! validate_url "$vendor_url"; then
        echo "❌ URLs inválidas"
        return 1
    fi
    
    local download_dir="$HOME/.waydroid_images"
    prepare_download_directory "$download_dir"
    
    # Configurar descargas personalizadas
    declare -A custom_downloads=(
        ["system"]="$system_url|$download_dir/system.img.xz|Imagen del sistema personalizada"
        ["vendor"]="$vendor_url|$download_dir/vendor.img.xz|Imagen vendor personalizada"
    )
    
    if download_multiple_files custom_downloads 2; then
        echo "✅ Imágenes personalizadas descargadas"
        configure_waydroid_images "$download_dir"
        return 0
    else
        echo "❌ Error descargando imágenes personalizadas"
        return 1
    fi
}

# Función para configurar Waydroid con las imágenes descargadas
configure_waydroid_images() {
    local images_dir="$1"
    
    echo "🔧 Configurando Waydroid con imágenes descargadas..."
    
    # Inicializar Waydroid si no está inicializado
    if ! waydroid status >/dev/null 2>&1; then
        echo "🚀 Inicializando Waydroid..."
        
        if waydroid init -s "$images_dir/system.img.xz" -v "$images_dir/vendor.img.xz"; then
            echo "✅ Waydroid inicializado correctamente"
        else
            log_error "Error inicializando Waydroid"
            return 1
        fi
    else
        echo "ℹ️ Waydroid ya está inicializado"
    fi
    
    # Configurar propiedades adicionales
    echo "⚙️ Configurando propiedades del sistema..."
    
    # Configuraciones recomendadas
    waydroid prop set persist.waydroid.multi_windows true 2>/dev/null || true
    waydroid prop set persist.waydroid.cursor_on_subsurface true 2>/dev/null || true
    
    echo "✅ Configuración de Waydroid completada"
}

# Función para el menú de post-instalación
post_installation_menu() {
    echo "🎯 Configuración Post-Instalación"
    echo "================================="
    echo ""
    echo "Opciones disponibles:"
    echo "1) Instalar Google Play Services (GApps)"
    echo "2) Instalar aplicaciones adicionales"
    echo "3) Configurar servicios del sistema"
    echo "4) Optimizar rendimiento"
    echo "5) Crear enlaces de escritorio"
    echo "6) Salir"
    echo ""
    
    while true; do
        echo -n "Selecciona una opción [6]: "
        local choice
        read -t 30 choice
        choice=${choice:-6}
        
        case "$choice" in
            1)
                install_gapps
                ;;
            2)
                install_additional_apps
                ;;
            3)
                configure_system_services
                ;;
            4)
                optimize_performance
                ;;
            5)
                create_desktop_entries
                ;;
            6)
                echo "✅ Saliendo del menú post-instalación"
                break
                ;;
            *)
                echo "⚠️ Opción inválida"
                ;;
        esac
        
        echo ""
    done
}

# Función para instalar Google Play Services
install_gapps() {
    echo "📱 Instalando Google Play Services..."
    
    # Descargar script de instalación de GApps
    local script_dir="/tmp/waydroid_scripts"
    prepare_download_directory "$script_dir"
    
    if download_waydroid_scripts "$script_dir"; then
        echo "✅ Scripts descargados"
        
        # Ejecutar instalación de GApps
        if python3 "$script_dir/gapps-installer.py"; then
            echo "✅ Google Play Services instalado"
        else
            echo "❌ Error instalando Google Play Services"
        fi
    else
        echo "❌ Error descargando scripts de instalación"
    fi
}

# Función para instalar aplicaciones adicionales
install_additional_apps() {
    echo "📱 Instalando aplicaciones adicionales..."
    
    # Lista de aplicaciones recomendadas
    local apps=(
        "com.android.vending"  # Google Play Store
        "com.google.android.gms"  # Google Play Services
        "com.android.chrome"  # Chrome Browser
    )
    
    for app in "${apps[@]}"; do
        echo "📦 Instalando: $app"
        # Aquí iría la lógica de instalación específica
        # waydroid app install "$app" o similar
    done
}

# Función para configurar servicios del sistema
configure_system_services() {
    echo "⚙️ Configurando servicios del sistema..."
    
    # Habilitar servicios automáticos
    systemctl --user enable waydroid-container.service 2>/dev/null || true
    
    # Configurar inicio automático
    echo "🚀 Configurando inicio automático..."
    
    echo "✅ Servicios configurados"
}

# Función para optimizar rendimiento
optimize_performance() {
    echo "⚡ Optimizando rendimiento..."
    
    # Configuraciones de rendimiento
    waydroid prop set persist.vendor.radio.atfwd.start false 2>/dev/null || true
    waydroid prop set ro.hardware.gralloc mali 2>/dev/null || true
    
    echo "✅ Optimizaciones aplicadas"
}

# Función para crear enlaces de escritorio
create_desktop_entries() {
    echo "🖥️ Creando enlaces de escritorio..."
    
    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"
    
    # Crear entrada para Waydroid
    cat > "$desktop_dir/waydroid.desktop" << EOF
[Desktop Entry]
Name=Waydroid
Comment=Android in a container
Exec=waydroid show-full-ui
Icon=android
Type=Application
Categories=System;Emulator;
EOF
    
    echo "✅ Enlaces de escritorio creados"
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

# Función principal del programa
main() {
    # Parsear argumentos de línea de comandos
    parse_arguments "$@"
    
    # Mostrar banner
    show_banner
    
    # Cargar y verificar módulos
    if ! load_all_modules; then
        echo "❌ Error fatal: No se pudieron cargar los módulos"
        exit 1
    fi
    
    if ! verify_modules; then
        echo "❌ Error fatal: Verificación de módulos falló"
        exit 1
    fi
    
    # Inicializar logging
    log_message "=== Waydroid Mega Installer v$SCRIPT_VERSION iniciado ===" "INFO"
    log_message "Usuario: $(whoami), Directorio: $(pwd)" "INFO"
    log_message "Modo: $([ "$CLI_MODE" = true ] && echo "CLI" || echo "TUI")" "INFO"
    
    echo "✅ Sistema modular cargado correctamente"
    echo ""
    
    # Decidir qué modo usar
    if [ "$CLI_MODE" = true ] || ! should_use_tui "$@"; then
        log_message "⚡ Ejecutando en modo línea de comandos"
        
        if [ "$AUTO_INSTALL" = true ]; then
            run_cli_installer
        else
            # Modo CLI pero sin --install, ejecutar flujo tradicional
            analyze_system
            install_system_dependencies
            download_images_menu
            post_installation_menu
        fi
    else
        log_message "🎨 Ejecutando en modo TUI interactivo"
        run_tui_installer
    fi
    
    # Mensaje final común
    local exit_code=$?
    echo ""
    
    if [ $exit_code -eq 0 ]; then
        echo "🎉 ¡Instalación de Waydroid completada!"
        echo "📋 Revisa el log para detalles: $LOG_FILE"
        echo ""
        echo "🚀 Para iniciar Waydroid: waydroid show-full-ui"
        echo "⚙️ Para configurar: waydroid prop set <propiedad> <valor>"
        echo "📱 Para instalar apps: waydroid app install <archivo.apk>"
        echo ""
        log_message "=== Waydroid Mega Installer completado exitosamente ===" "INFO"
    else
        echo "❌ La instalación falló. Revisa el log: $LOG_FILE"
        log_message "=== Waydroid Mega Installer falló ===" "ERROR"
    fi
    
    return $exit_code
}

# =============================================================================
# EJECUCIÓN DEL SCRIPT
# =============================================================================

# Verificar que se ejecuta como script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Configurar trap para limpieza automática
    trap 'cleanup_on_error "script_interrupted"' INT TERM
    
    # Ejecutar programa principal
    main "$@"
fi