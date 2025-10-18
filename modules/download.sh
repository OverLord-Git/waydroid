#!/bin/bash
# =============================================================================
# MÓDULO DOWNLOAD - Gestión de descargas con validación
# =============================================================================
# Funcionalidades: descarga de archivos, validación de integridad, 
#                  gestión de URLs, reintentos automáticos
# Versión: 2.0 - Octubre 2025

# Dependencias del módulo
if [ -z "$LOG_FILE" ]; then
    echo "❌ Error: Módulo core no cargado. Cargar modules/core.sh primero."
    exit 1
fi

# =============================================================================
# CONFIGURACIÓN DE DESCARGAS
# =============================================================================

declare -g DOWNLOAD_DIR="/tmp/waydroid_downloads"
declare -g MAX_DOWNLOAD_RETRIES=3
declare -g DOWNLOAD_TIMEOUT=300
declare -g CONCURRENT_DOWNLOADS=3

# URLs de descarga de Waydroid
declare -A WAYDROID_URLS=(
    # Android 13 TV Images
    ["system-tv13"]="https://images.waydro.id/images/system/lineage/waydroid_x86_64/lineage-20.0-20230625-UNOFFICIAL-waydroid_x86_64-system.img.xz"
    ["vendor-tv13"]="https://images.waydro.id/images/vendor/waydroid_x86_64/lineage-20.0-20230625-UNOFFICIAL-waydroid_x86_64-vendor.img.xz"
    
    # Android 11 Vanilla Images
    ["system-vanilla11"]="https://images.waydro.id/images/system/lineage/waydroid_x86_64/lineage-18.1-20230917-UNOFFICIAL-waydroid_x86_64-system.img.xz"
    ["vendor-vanilla11"]="https://images.waydro.id/images/vendor/waydroid_x86_64/lineage-18.1-20230917-UNOFFICIAL-waydroid_x86_64-vendor.img.xz"
    
    # ARM64 Images
    ["system-tv13-arm64"]="https://images.waydro.id/images/system/lineage/waydroid_arm64/lineage-20.0-20230625-UNOFFICIAL-waydroid_arm64-system.img.xz"
    ["vendor-tv13-arm64"]="https://images.waydro.id/images/vendor/waydroid_arm64/lineage-20.0-20230625-UNOFFICIAL-waydroid_arm64-vendor.img.xz"
)

# =============================================================================
# FUNCIONES DE DESCARGA BÁSICA
# =============================================================================

# Función para crear directorio de descargas
prepare_download_directory() {
    local download_dir="${1:-$DOWNLOAD_DIR}"
    
    if [ ! -d "$download_dir" ]; then
        if mkdir -p "$download_dir"; then
            log_message "Directorio de descargas creado: $download_dir" "INFO"
        else
            log_error "No se pudo crear directorio de descargas: $download_dir"
            return 1
        fi
    fi
    
    DOWNLOAD_DIR="$download_dir"
    log_debug "Directorio de descargas configurado: $DOWNLOAD_DIR"
    return 0
}

# Función básica de descarga con reintentos
download_file_basic() {
    local url="$1"
    local output_file="$2"
    local max_retries="${3:-$MAX_DOWNLOAD_RETRIES}"
    local timeout="${4:-$DOWNLOAD_TIMEOUT}"
    
    local retry_count=0
    local download_tool=""
    
    # Determinar herramienta de descarga disponible
    if command_exists wget; then
        download_tool="wget"
    elif command_exists curl; then
        download_tool="curl"
    else
        log_error "No se encontró wget ni curl para descargar"
        return 1
    fi
    
    log_message "Descargando con $download_tool: $url -> $output_file" "INFO"
    
    while [ $retry_count -lt $max_retries ]; do
        ((retry_count++))
        
        echo "🔄 Intento $retry_count/$max_retries..."
        
        # Remover archivo parcial si existe
        rm -f "${output_file}.partial"
        
        case "$download_tool" in
            "wget")
                if wget \
                    --progress=bar:force \
                    --tries=1 \
                    --timeout="$timeout" \
                    --continue \
                    --output-document="${output_file}.partial" \
                    "$url"; then
                    
                    mv "${output_file}.partial" "$output_file"
                    log_message "Descarga exitosa con wget: $output_file" "INFO"
                    return 0
                fi
                ;;
            "curl")
                if curl \
                    --location \
                    --progress-bar \
                    --max-time "$timeout" \
                    --retry 0 \
                    --continue-at - \
                    --output "${output_file}.partial" \
                    "$url"; then
                    
                    mv "${output_file}.partial" "$output_file"
                    log_message "Descarga exitosa con curl: $output_file" "INFO"
                    return 0
                fi
                ;;
        esac
        
        log_warning "Intento $retry_count falló, reintentando..."
        sleep 2
    done
    
    log_error "Descarga falló después de $max_retries intentos"
    rm -f "${output_file}.partial"
    return 1
}

# Función de descarga con validación de URL
download_file_with_validation() {
    local url="$1"
    local output_file="$2"
    local description="${3:-archivo}"
    
    # Validar URL
    if ! validate_url "$url"; then
        log_error "URL inválida: $url"
        return 1
    fi
    
    # Verificar si el archivo ya existe y es válido
    if [ -f "$output_file" ]; then
        echo "ℹ️ Archivo ya existe: $(basename "$output_file")"
        
        # Si hay validación disponible, verificar integridad
        if function_exists "verify_known_checksum"; then
            if verify_known_checksum "$output_file" 2>/dev/null; then
                echo "✅ Archivo existente válido, omitiendo descarga"
                return 0
            else
                echo "⚠️ Archivo existente inválido, re-descargando..."
                rm -f "$output_file"
            fi
        else
            echo "ℹ️ Usando archivo existente (validación no disponible)"
            return 0
        fi
    fi
    
    # Verificar espacio disponible antes de descargar
    local file_size
    file_size=$(get_remote_file_size "$url")
    if [ $? -eq 0 ] && [ "$file_size" -gt 0 ]; then
        if ! check_available_space "$output_file" "$file_size"; then
            log_error "Espacio insuficiente para descargar: $description"
            return 1
        fi
    fi
    
    echo "📥 Descargando $description..."
    echo "🔗 URL: $url"
    echo "📁 Destino: $output_file"
    
    # Realizar descarga
    if download_file_basic "$url" "$output_file"; then
        echo "✅ Descarga completada: $description"
        
        # Verificar que el archivo no esté vacío
        if [ ! -s "$output_file" ]; then
            log_error "Archivo descargado está vacío: $output_file"
            rm -f "$output_file"
            return 1
        fi
        
        return 0
    else
        log_error "Error descargando: $description"
        return 1
    fi
}

# =============================================================================
# FUNCIONES DE VALIDACIÓN DE URLS
# =============================================================================

# Función para validar formato de URL
validate_url() {
    local url="$1"
    
    # Verificar que la URL no esté vacía
    if [ -z "$url" ]; then
        return 1
    fi
    
    # Verificar formato básico de URL
    if [[ "$url" =~ ^https?://[^[:space:]]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Función para verificar que una URL es accesible
check_url_accessibility() {
    local url="$1"
    local timeout="${2:-30}"
    
    log_debug "Verificando accesibilidad de URL: $url"
    
    if command_exists curl; then
        if curl --head --silent --fail --max-time "$timeout" "$url" >/dev/null 2>&1; then
            log_debug "URL accesible: $url"
            return 0
        fi
    elif command_exists wget; then
        if wget --spider --quiet --timeout="$timeout" "$url" >/dev/null 2>&1; then
            log_debug "URL accesible: $url"
            return 0
        fi
    fi
    
    log_warning "URL no accesible: $url"
    return 1
}

# Función para obtener el tamaño de un archivo remoto
get_remote_file_size() {
    local url="$1"
    
    if command_exists curl; then
        curl --head --silent "$url" | grep -i content-length | awk '{print $2}' | tr -d '\r'
    elif command_exists wget; then
        wget --spider --server-response "$url" 2>&1 | grep -i content-length | awk '{print $2}' | tr -d '\r'
    else
        echo "0"
    fi
}

# =============================================================================
# FUNCIONES DE VERIFICACIÓN DE ESPACIO
# =============================================================================

# Función para verificar espacio disponible
check_available_space() {
    local target_file="$1"
    local required_size="$2"  # en bytes
    
    local target_dir
    target_dir=$(dirname "$target_file")
    
    # Obtener espacio disponible en bytes
    local available_space
    available_space=$(df "$target_dir" | awk 'NR==2 {print $4 * 1024}')
    
    # Añadir margen de seguridad (10%)
    local required_with_margin=$((required_size + required_size / 10))
    
    if [ "$available_space" -ge "$required_with_margin" ]; then
        log_debug "Espacio suficiente: $available_space bytes disponibles, $required_with_margin bytes requeridos"
        return 0
    else
        log_error "Espacio insuficiente: $available_space bytes disponibles, $required_with_margin bytes requeridos"
        return 1
    fi
}

# =============================================================================
# FUNCIONES DE DESCARGA PARALELA
# =============================================================================

# Función para descarga paralela de múltiples archivos
download_multiple_files() {
    local -n downloads_ref=$1  # Array asociativo por referencia
    local max_concurrent="${2:-$CONCURRENT_DOWNLOADS}"
    
    local pids=()
    local download_results=()
    local active_downloads=0
    
    echo "📥 Iniciando descarga paralela de ${#downloads_ref[@]} archivos (máx. $max_concurrent paralelos)"
    
    # Crear función de descarga para background
    download_worker() {
        local url="$1"
        local output_file="$2"
        local description="$3"
        local result_file="$4"
        
        if download_file_with_validation "$url" "$output_file" "$description"; then
            echo "success" > "$result_file"
        else
            echo "failed" > "$result_file"
        fi
    }
    
    # Exportar función para subprocesos
    export -f download_worker
    export -f download_file_with_validation
    export -f download_file_basic
    export -f validate_url
    export -f get_remote_file_size
    export -f check_available_space
    
    # Procesar descargas
    local index=0
    for key in "${!downloads_ref[@]}"; do
        local download_info="${downloads_ref[$key]}"
        local url=$(echo "$download_info" | cut -d'|' -f1)
        local output_file=$(echo "$download_info" | cut -d'|' -f2)
        local description=$(echo "$download_info" | cut -d'|' -f3)
        
        # Esperar si hay demasiadas descargas activas
        while [ $active_downloads -ge $max_concurrent ]; do
            wait_for_download_completion pids[@] download_results[@]
            active_downloads=${#pids[@]}
        done
        
        # Iniciar nueva descarga
        local result_file="/tmp/download_result_$$_$index"
        download_worker "$url" "$output_file" "$description" "$result_file" &
        local pid=$!
        
        pids+=("$pid")
        download_results+=("$result_file")
        ((active_downloads++))
        ((index++))
        
        log_debug "Descarga iniciada: PID $pid, archivo: $description"
    done
    
    # Esperar a que terminen todas las descargas
    echo "⏳ Esperando a que terminen todas las descargas..."
    wait
    
    # Verificar resultados
    local success_count=0
    local failed_count=0
    
    for result_file in "${download_results[@]}"; do
        if [ -f "$result_file" ]; then
            local result=$(cat "$result_file")
            if [ "$result" = "success" ]; then
                ((success_count++))
            else
                ((failed_count++))
            fi
            rm -f "$result_file"
        else
            ((failed_count++))
        fi
    done
    
    echo "📊 Resumen de descargas: $success_count exitosas, $failed_count fallidas"
    
    if [ $failed_count -eq 0 ]; then
        echo "✅ Todas las descargas completadas exitosamente"
        return 0
    else
        echo "⚠️ Algunas descargas fallaron"
        return 1
    fi
}

# Función auxiliar para esperar completación de descargas
wait_for_download_completion() {
    local -n pids_ref=$1
    local -n results_ref=$2
    
    local new_pids=()
    local new_results=()
    
    for i in "${!pids_ref[@]}"; do
        local pid="${pids_ref[$i]}"
        local result_file="${results_ref[$i]}"
        
        if kill -0 "$pid" 2>/dev/null; then
            # Proceso aún activo
            new_pids+=("$pid")
            new_results+=("$result_file")
        else
            # Proceso terminado
            log_debug "Descarga completada: PID $pid"
        fi
    done
    
    pids_ref=("${new_pids[@]}")
    results_ref=("${new_results[@]}")
}

# =============================================================================
# FUNCIONES ESPECÍFICAS DE WAYDROID
# =============================================================================

# Función para descargar imágenes de Waydroid
download_waydroid_images() {
    local android_version="${1:-tv13}"
    local architecture="${2:-x86_64}"
    local target_dir="${3:-$HOME}"
    
    log_message "Descargando imágenes de Waydroid: Android $android_version ($architecture)" "INFO"
    
    # Preparar directorio de destino
    if ! prepare_download_directory "$target_dir"; then
        return 1
    fi
    
    # Determinar imágenes a descargar
    local system_key="system-${android_version}"
    local vendor_key="vendor-${android_version}"
    
    if [ "$architecture" = "aarch64" ]; then
        system_key="${system_key}-arm64"
        vendor_key="${vendor_key}-arm64"
    fi
    
    # Verificar que las URLs existan
    if [ -z "${WAYDROID_URLS[$system_key]}" ] || [ -z "${WAYDROID_URLS[$vendor_key]}" ]; then
        log_error "URLs no encontradas para: $android_version ($architecture)"
        return 1
    fi
    
    # Configurar descargas
    declare -A downloads=(
        ["system"]="${WAYDROID_URLS[$system_key]}|$target_dir/system.img.xz|Imagen del sistema Android"
        ["vendor"]="${WAYDROID_URLS[$vendor_key]}|$target_dir/vendor.img.xz|Imagen vendor Android"
    )
    
    # Descargar archivos
    if download_multiple_files downloads 2; then
        echo "✅ Imágenes de Waydroid descargadas correctamente"
        
        # Validar integridad si hay módulo de validación disponible
        if function_exists "validate_system_files"; then
            echo "🔍 Validando integridad de imágenes..."
            validate_system_files "$target_dir" "system.img.xz" "vendor.img.xz"
        fi
        
        return 0
    else
        log_error "Error descargando imágenes de Waydroid"
        return 1
    fi
}

# Función para descargar scripts adicionales
download_waydroid_scripts() {
    local target_dir="${1:-$DOWNLOAD_DIR}"
    
    log_message "Descargando scripts adicionales de Waydroid" "INFO"
    
    # URLs de scripts útiles
    declare -A script_urls=(
        ["waydroid-extras"]="https://raw.githubusercontent.com/casualsnek/waydroid_script/main/waydroid_extras.py"
        ["gapps-installer"]="https://raw.githubusercontent.com/casualsnek/waydroid_script/main/install_gapps.py"
    )
    
    prepare_download_directory "$target_dir"
    
    for script_name in "${!script_urls[@]}"; do
        local url="${script_urls[$script_name]}"
        local output_file="$target_dir/${script_name}.py"
        
        if download_file_with_validation "$url" "$output_file" "Script $script_name"; then
            chmod +x "$output_file"
            echo "✅ Script descargado: $script_name"
        else
            echo "⚠️ Error descargando script: $script_name"
        fi
    done
}

# =============================================================================
# FUNCIONES DE LIMPIEZA
# =============================================================================

# Función para limpiar archivos de descarga
cleanup_downloads() {
    local keep_completed="${1:-false}"
    
    log_message "Limpiando archivos de descarga" "INFO"
    
    if [ "$keep_completed" = "true" ]; then
        # Solo eliminar archivos parciales
        find "$DOWNLOAD_DIR" -name "*.partial" -delete 2>/dev/null || true
        echo "🧹 Archivos parciales eliminados"
    else
        # Eliminar todo el directorio de descargas
        rm -rf "$DOWNLOAD_DIR"
        echo "🧹 Directorio de descargas limpiado completamente"
    fi
}

# =============================================================================
# FUNCIONES DE INFORMACIÓN
# =============================================================================

# Función para mostrar información de descargas
show_download_info() {
    echo "📥 Información de Descargas"
    echo "=========================="
    echo "Directorio de descargas: $DOWNLOAD_DIR"
    echo "Máximo reintentos: $MAX_DOWNLOAD_RETRIES"
    echo "Timeout: $DOWNLOAD_TIMEOUT segundos"
    echo "Descargas concurrentes: $CONCURRENT_DOWNLOADS"
    echo ""
    
    if [ -d "$DOWNLOAD_DIR" ]; then
        local file_count
        file_count=$(find "$DOWNLOAD_DIR" -type f 2>/dev/null | wc -l)
        local dir_size
        dir_size=$(du -sh "$DOWNLOAD_DIR" 2>/dev/null | cut -f1)
        
        echo "Archivos en directorio: $file_count"
        echo "Tamaño total: $dir_size"
    else
        echo "Directorio de descargas no existe"
    fi
    echo "=========================="
}

# =============================================================================
# INICIALIZACIÓN DEL MÓDULO
# =============================================================================

# Función de inicialización del módulo download
init_download_module() {
    log_message "Inicializando módulo download" "INFO"
    
    # Verificar herramientas de descarga
    if ! command_exists wget && ! command_exists curl; then
        log_error "No se encontró wget ni curl para descargar archivos"
        return 1
    fi
    
    # Crear directorio de descargas
    prepare_download_directory
    
    log_message "Módulo download inicializado correctamente" "INFO"
    return 0
}

# Auto-inicializar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Cargar core si no está cargado
    if ! function_exists "log_message"; then
        source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
    fi
    
    init_download_module
    show_download_info
    echo "✅ Módulo download inicializado correctamente"
fi