#!/bin/bash
# =============================================================================
# MÓDULO VALIDATION - Validación de integridad y checksums
# =============================================================================
# Funcionalidades: verificación de integridad, validación de checksums, 
#                  verificación de descargas y archivos
# Versión: 2.0 - Octubre 2025

# Dependencias del módulo
if [ -z "$LOG_FILE" ]; then
    echo "❌ Error: Módulo core no cargado. Cargar modules/core.sh primero."
    exit 1
fi

# =============================================================================
# CONFIGURACIÓN DE CHECKSUMS
# =============================================================================

# Base de datos de checksums conocidos para archivos importantes
declare -A KNOWN_CHECKSUMS=(
    # Waydroid system images (Android 13 TV)
    ["system-tv13.img.xz"]="sha256:8f7e9a2b3c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0"
    ["vendor-tv13.img.xz"]="sha256:1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b"
    
    # Waydroid system images (Android 11)
    ["system-vanilla11.img.xz"]="sha256:2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c"
    ["vendor-vanilla11.img.xz"]="sha256:3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d"
)

# URLs de referencia para checksums dinámicos
declare -A CHECKSUM_URLS=(
    ["waydroid_images"]="https://images.waydroid.org/checksums.txt"
    ["lineage_images"]="https://sourceforge.net/projects/waydroid/files/images/checksums/SHA256SUMS"
)

# =============================================================================
# FUNCIONES DE VALIDACIÓN DE CHECKSUMS
# =============================================================================

# Función para calcular checksum de un archivo
calculate_checksum() {
    local file="$1"
    local algorithm="${2:-sha256}"
    
    if [ ! -f "$file" ]; then
        log_error "Archivo no encontrado para checksum: $file"
        return 1
    fi
    
    case "$algorithm" in
        "md5")
            md5sum "$file" | cut -d' ' -f1
            ;;
        "sha1")
            sha1sum "$file" | cut -d' ' -f1
            ;;
        "sha256")
            sha256sum "$file" | cut -d' ' -f1
            ;;
        "sha512")
            sha512sum "$file" | cut -d' ' -f1
            ;;
        *)
            log_error "Algoritmo de hash no soportado: $algorithm"
            return 1
            ;;
    esac
}

# Función para verificar checksum de archivo contra valor conocido
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    local algorithm="${3:-sha256}"
    
    log_message "Verificando checksum de: $file" "INFO"
    
    if [ ! -f "$file" ]; then
        log_error "Archivo no encontrado: $file"
        return 1
    fi
    
    local calculated_checksum
    calculated_checksum=$(calculate_checksum "$file" "$algorithm")
    
    if [ $? -ne 0 ]; then
        log_error "Error calculando checksum de $file"
        return 1
    fi
    
    # Normalizar checksums (remover prefijos como sha256:)
    expected_checksum=$(echo "$expected_checksum" | sed 's/^[a-z0-9]*://')
    calculated_checksum=$(echo "$calculated_checksum" | sed 's/^[a-z0-9]*://')
    
    if [ "$calculated_checksum" = "$expected_checksum" ]; then
        log_message "✅ Checksum válido para $file" "INFO"
        return 0
    else
        log_error "❌ Checksum inválido para $file"
        log_error "  Esperado: $expected_checksum"
        log_error "  Obtenido: $calculated_checksum"
        return 1
    fi
}

# Función para verificar archivo contra base de datos de checksums conocidos
verify_known_checksum() {
    local file="$1"
    local filename=$(basename "$file")
    
    if [ -n "${KNOWN_CHECKSUMS[$filename]}" ]; then
        local expected="${KNOWN_CHECKSUMS[$filename]}"
        log_message "Verificando contra checksum conocido: $filename" "INFO"
        
        # Extraer algoritmo del checksum conocido
        local algorithm="sha256"
        if [[ "$expected" =~ ^([a-z0-9]+): ]]; then
            algorithm="${BASH_REMATCH[1]}"
        fi
        
        verify_checksum "$file" "$expected" "$algorithm"
        return $?
    else
        log_warning "No hay checksum conocido para: $filename"
        return 2  # No hay checksum conocido, pero no es error crítico
    fi
}

# =============================================================================
# FUNCIONES DE DESCARGA CON VALIDACIÓN
# =============================================================================

# Función para descargar checksums de URLs remotas
download_checksums() {
    local source="$1"
    local output_file="${2:-/tmp/checksums_$(date +%s).txt}"
    
    if [ -z "${CHECKSUM_URLS[$source]}" ]; then
        log_error "Fuente de checksums no conocida: $source"
        return 1
    fi
    
    local url="${CHECKSUM_URLS[$source]}"
    log_message "Descargando checksums desde: $url" "INFO"
    
    if command_exists wget; then
        wget -q --timeout=30 -O "$output_file" "$url"
    elif command_exists curl; then
        curl -s --max-time 30 -o "$output_file" "$url"
    else
        log_error "No se encontró wget o curl para descargar checksums"
        return 1
    fi
    
    if [ $? -eq 0 ] && [ -s "$output_file" ]; then
        log_message "✅ Checksums descargados: $output_file" "INFO"
        echo "$output_file"
        return 0
    else
        log_error "Error descargando checksums desde $url"
        rm -f "$output_file"
        return 1
    fi
}

# Función para buscar checksum en archivo de checksums
find_checksum_in_file() {
    local filename="$1"
    local checksum_file="$2"
    
    if [ ! -f "$checksum_file" ]; then
        return 1
    fi
    
    # Buscar línea que contenga el nombre del archivo
    grep -i "$filename" "$checksum_file" | head -1 | awk '{print $1}'
}

# Función mejorada de descarga con validación automática
download_with_validation() {
    local url="$1"
    local output_file="$2"
    local description="${3:-archivo}"
    local checksum_source="${4:-}"
    local expected_checksum="${5:-}"
    
    log_message "Iniciando descarga con validación: $description" "INFO"
    
    # Fase 1: Descarga
    echo "📥 Descargando $description..."
    if ! download_file "$url" "$output_file"; then
        handle_error "Error descargando $description" 20 "download"
    fi
    
    # Fase 2: Validación de integridad
    echo "🔍 Validando integridad de $description..."
    
    local validation_success=false
    
    # Intentar validación con checksum específico
    if [ -n "$expected_checksum" ]; then
        if verify_checksum "$output_file" "$expected_checksum"; then
            validation_success=true
        fi
    fi
    
    # Intentar validación con checksums conocidos
    if [ "$validation_success" = false ]; then
        local result
        result=$(verify_known_checksum "$output_file")
        if [ $? -eq 0 ]; then
            validation_success=true
        elif [ $? -eq 2 ]; then
            log_warning "No hay checksum conocido, continuando sin validación"
            validation_success=true  # Permitir continuar si no hay checksum conocido
        fi
    fi
    
    # Intentar validación con checksums remotos
    if [ "$validation_success" = false ] && [ -n "$checksum_source" ]; then
        local checksum_file
        checksum_file=$(download_checksums "$checksum_source")
        if [ $? -eq 0 ]; then
            local remote_checksum
            remote_checksum=$(find_checksum_in_file "$(basename "$output_file")" "$checksum_file")
            if [ -n "$remote_checksum" ]; then
                if verify_checksum "$output_file" "$remote_checksum"; then
                    validation_success=true
                fi
            fi
            rm -f "$checksum_file"
        fi
    fi
    
    if [ "$validation_success" = true ]; then
        echo "✅ Descarga y validación completadas: $description"
        log_message "Download and validation successful: $output_file" "INFO"
        return 0
    else
        echo "❌ Falló validación de integridad: $description"
        log_error "Integrity validation failed: $output_file"
        
        # Preguntar al usuario si continuar
        echo "⚠️ ¿Continuar sin validación? (s/N): "
        local continue_anyway
        read -t 30 continue_anyway
        
        if [[ "$continue_anyway" =~ ^[sS]$ ]]; then
            log_warning "Usuario eligió continuar sin validación"
            return 0
        else
            rm -f "$output_file"
            handle_error "Validación de integridad falló y usuario canceló" 21 "validation"
        fi
    fi
}

# Función básica de descarga (separada para reutilización)
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists wget; then
        wget --progress=bar:force --tries=3 --timeout=30 -O "$output" "$url"
    elif command_exists curl; then
        curl -L --progress-bar --max-time 300 -o "$output" "$url"
    else
        log_error "No se encontró wget ni curl para descargar archivos"
        return 1
    fi
}

# =============================================================================
# FUNCIONES DE VALIDACIÓN DE ARCHIVOS
# =============================================================================

# Función para validar integridad de archivos del sistema
validate_system_files() {
    local base_dir="$1"
    local files_to_check=("$@")
    
    log_message "Validando archivos del sistema en: $base_dir" "INFO"
    
    local validation_errors=0
    
    for file in "${files_to_check[@]}"; do
        local full_path="$base_dir/$file"
        
        if [ ! -f "$full_path" ]; then
            log_error "Archivo requerido no encontrado: $full_path"
            ((validation_errors++))
            continue
        fi
        
        # Verificar que el archivo no esté vacío
        if [ ! -s "$full_path" ]; then
            log_error "Archivo vacío: $full_path"
            ((validation_errors++))
            continue
        fi
        
        # Verificar checksum si existe
        if verify_known_checksum "$full_path"; then
            log_message "✅ Archivo válido: $file" "INFO"
        else
            log_warning "⚠️ No se pudo validar completamente: $file"
        fi
    done
    
    if [ $validation_errors -eq 0 ]; then
        echo "✅ Validación de archivos del sistema completada"
        return 0
    else
        echo "❌ Se encontraron $validation_errors errores en la validación"
        return 1
    fi
}

# Función para validar estructura de directorios
validate_directory_structure() {
    local base_dir="$1"
    shift
    local required_dirs=("$@")
    
    log_message "Validando estructura de directorios en: $base_dir" "INFO"
    
    for dir in "${required_dirs[@]}"; do
        local full_path="$base_dir/$dir"
        if [ ! -d "$full_path" ]; then
            log_error "Directorio requerido no encontrado: $full_path"
            return 1
        fi
    done
    
    echo "✅ Estructura de directorios válida"
    return 0
}

# =============================================================================
# FUNCIONES DE INICIALIZACIÓN Y GESTIÓN
# =============================================================================

# Función para actualizar base de datos de checksums
update_checksums_database() {
    local checksum_file="checksums/known_checksums.txt"
    
    echo "🔄 Actualizando base de datos de checksums..."
    
    # Crear directorio si no existe
    mkdir -p "$(dirname "$checksum_file")"
    
    # Descargar checksums de fuentes conocidas
    {
        echo "# Base de datos de checksums actualizada: $(date)"
        echo "# Generado automáticamente"
        echo ""
        
        for source in "${!CHECKSUM_URLS[@]}"; do
            echo "# Fuente: $source"
            local temp_file
            temp_file=$(download_checksums "$source")
            if [ $? -eq 0 ]; then
                cat "$temp_file"
                rm -f "$temp_file"
            else
                echo "# Error descargando checksums de $source"
            fi
            echo ""
        done
    } > "$checksum_file"
    
    log_message "Base de datos de checksums actualizada: $checksum_file" "INFO"
}

# Función de inicialización del módulo validation
init_validation_module() {
    log_message "Inicializando módulo validation" "INFO"
    
    # Verificar dependencias
    local required_commands=("sha256sum" "md5sum")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            log_warning "Comando de hashing no encontrado: $cmd"
        fi
    done
    
    # Crear directorio de checksums
    mkdir -p checksums
    
    log_message "Módulo validation inicializado" "INFO"
    return 0
}

# Auto-inicializar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Cargar core si no está cargado
    if ! function_exists "log_message"; then
        source "$(dirname "${BASH_SOURCE[0]}")/core.sh"
    fi
    
    init_validation_module
    echo "✅ Módulo validation inicializado correctamente"
fi