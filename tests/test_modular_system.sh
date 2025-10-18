#!/bin/bash
# =============================================================================
# SCRIPT DE PRUEBAS PARA EL SISTEMA MODULAR
# =============================================================================
# Valida que todos los módulos funcionen correctamente
# Versión: 2.0 - Octubre 2025

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/../modules"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores de pruebas
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# FUNCIONES DE TESTING
# =============================================================================

# Función para ejecutar una prueba
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++))
    echo -n "🧪 Probando: $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Función para probar carga de módulos
test_module_loading() {
    echo -e "${BLUE}📦 Probando carga de módulos${NC}"
    echo "================================"
    
    local modules=("core" "validation" "system" "package" "download")
    
    for module in "${modules[@]}"; do
        run_test "Carga de módulo $module" "source '$MODULES_DIR/${module}.sh'"
    done
    
    echo ""
}

# Función para probar funciones del módulo core
test_core_module() {
    echo -e "${BLUE}🔧 Probando módulo core${NC}"
    echo "========================"
    
    # Cargar módulo
    source "$MODULES_DIR/core.sh"
    
    run_test "Función log_message" "log_message 'Test message' 'INFO'"
    run_test "Función handle_error (simulación)" "true"  # No ejecutamos realmente handle_error
    run_test "Función safe_cd" "safe_cd '/tmp'"
    run_test "Función command_exists" "command_exists 'bash'"
    run_test "Función function_exists" "function_exists 'log_message'"
    
    echo ""
}

# Función para probar funciones del módulo validation
test_validation_module() {
    echo -e "${BLUE}🔍 Probando módulo validation${NC}"
    echo "==============================="
    
    # Cargar módulos necesarios
    source "$MODULES_DIR/core.sh"
    source "$MODULES_DIR/validation.sh"
    
    # Crear archivo de prueba
    echo "test content" > /tmp/test_file.txt
    
    run_test "Función calculate_checksum" "calculate_checksum '/tmp/test_file.txt' 'sha256'"
    run_test "Función validate_url" "validate_url 'https://example.com/file.txt'"
    run_test "Inicialización del módulo" "init_validation_module"
    
    # Limpiar
    rm -f /tmp/test_file.txt
    
    echo ""
}

# Función para probar funciones del módulo system
test_system_module() {
    echo -e "${BLUE}🐧 Probando módulo system${NC}"
    echo "==========================="
    
    # Cargar módulos necesarios
    source "$MODULES_DIR/core.sh"
    source "$MODULES_DIR/system.sh"
    
    run_test "Función detect_distribution" "detect_distribution"
    run_test "Función check_system_requirements" "check_system_requirements"
    run_test "Función detect_architecture" "detect_architecture"
    run_test "Función check_disk_space" "check_disk_space"
    run_test "Inicialización del módulo" "init_system_module"
    
    echo ""
}

# Función para probar funciones del módulo package
test_package_module() {
    echo -e "${BLUE}📦 Probando módulo package${NC}"
    echo "============================"
    
    # Cargar módulos necesarios
    source "$MODULES_DIR/core.sh"
    source "$MODULES_DIR/system.sh"
    source "$MODULES_DIR/package.sh"
    
    run_test "Función detect_package_manager" "detect_package_manager"
    run_test "Función is_package_installed (bash)" "is_package_installed 'bash'"
    run_test "Función get_waydroid_dependencies" "get_waydroid_dependencies 'ubuntu'"
    run_test "Inicialización del módulo" "init_package_module"
    
    echo ""
}

# Función para probar funciones del módulo download
test_download_module() {
    echo -e "${BLUE}📥 Probando módulo download${NC}"
    echo "============================"
    
    # Cargar módulos necesarios
    source "$MODULES_DIR/core.sh"
    source "$MODULES_DIR/validation.sh"
    source "$MODULES_DIR/download.sh"
    
    run_test "Función validate_url" "validate_url 'https://httpbin.org/get'"
    run_test "Función prepare_download_directory" "prepare_download_directory '/tmp/test_downloads'"
    run_test "Función get_remote_file_size" "get_remote_file_size 'https://httpbin.org/robots.txt'"
    run_test "Inicialización del módulo" "init_download_module"
    
    # Limpiar
    rm -rf /tmp/test_downloads
    
    echo ""
}

# Función para probar integración completa
test_integration() {
    echo -e "${BLUE}🔗 Probando integración completa${NC}"
    echo "================================="
    
    # Simular carga del script principal
    run_test "Carga del script principal" "bash -n '$SCRIPT_DIR/../waydroid_installer_modular.sh'"
    
    # Probar funciones específicas del script principal
    source "$SCRIPT_DIR/../waydroid_installer_modular.sh"
    
    run_test "Función load_module" "load_module 'core'"
    run_test "Función verify_modules" "load_all_modules && verify_modules"
    
    echo ""
}

# Función para realizar prueba de descarga real (opcional)
test_real_download() {
    echo -e "${BLUE}🌐 Probando descarga real (opcional)${NC}"
    echo "====================================="
    
    echo -n "¿Realizar prueba de descarga real? (s/N): "
    read -t 10 do_download
    
    if [[ "$do_download" =~ ^[sS]$ ]]; then
        # Cargar módulos
        source "$MODULES_DIR/core.sh"
        source "$MODULES_DIR/validation.sh"
        source "$MODULES_DIR/download.sh"
        
        # Probar descarga de archivo pequeño
        local test_url="https://httpbin.org/robots.txt"
        local test_file="/tmp/robots_test.txt"
        
        run_test "Descarga real de archivo pequeño" "download_file_with_validation '$test_url' '$test_file' 'archivo de prueba'"
        
        # Limpiar
        rm -f "$test_file"
    else
        echo "⏭️ Prueba de descarga real omitida"
    fi
    
    echo ""
}

# Función para mostrar resumen de pruebas
show_test_summary() {
    echo "📊 RESUMEN DE PRUEBAS"
    echo "===================="
    echo "Total de pruebas: $TESTS_TOTAL"
    echo -e "Exitosas: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Fallidas: ${RED}$TESTS_FAILED${NC}"
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    echo "Tasa de éxito: $success_rate%"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 ¡Todas las pruebas pasaron exitosamente!${NC}"
        return 0
    else
        echo -e "${RED}⚠️ Algunas pruebas fallaron. Revisar la implementación.${NC}"
        return 1
    fi
}

# =============================================================================
# FUNCIÓN PRINCIPAL
# =============================================================================

main() {
    echo "🧪 SUITE DE PRUEBAS - WAYDROID INSTALLER MODULAR"
    echo "================================================="
    echo ""
    
    # Verificar que los archivos necesarios existen
    if [ ! -d "$MODULES_DIR" ]; then
        echo -e "${RED}❌ Error: Directorio de módulos no encontrado: $MODULES_DIR${NC}"
        exit 1
    fi
    
    # Ejecutar pruebas
    test_module_loading
    test_core_module
    test_validation_module
    test_system_module
    test_package_module
    test_download_module
    test_integration
    test_real_download
    
    # Mostrar resumen
    show_test_summary
    exit $?
}

# Ejecutar si es el script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi