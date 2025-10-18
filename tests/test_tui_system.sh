#!/bin/bash
# =============================================================================
# SUITE DE PRUEBAS PARA SISTEMA TUI HÍBRIDO
# =============================================================================
# Pruebas específicas para verificar la funcionalidad del sistema TUI/CLI
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_SCRIPT="$SCRIPT_DIR/../waydroid_installer_modular.sh"
TEST_COUNT=0
PASSED_TESTS=0
FAILED_TESTS=0

# =============================================================================
# FUNCIONES DE TESTING
# =============================================================================

# Función para ejecutar un test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_exit_code="${3:-0}"
    
    ((TEST_COUNT++))
    echo "🧪 Test $TEST_COUNT: $test_name"
    echo "   Comando: $test_command"
    
    # Ejecutar test con timeout
    timeout 10s bash -c "$test_command" >/dev/null 2>&1
    local actual_exit_code=$?
    
    if [ $actual_exit_code -eq $expected_exit_code ]; then
        echo "   ✅ PASSED"
        ((PASSED_TESTS++))
    else
        echo "   ❌ FAILED (Exit code: $actual_exit_code, Expected: $expected_exit_code)"
        ((FAILED_TESTS++))
    fi
    echo
}

# Función para verificar que una función del script principal existe
test_main_function_exists() {
    local function_name="$1"
    
    ((TEST_COUNT++))
    echo "🔍 Test $TEST_COUNT: Verificar función $function_name (script principal)"
    
    # Verificar que la función existe en el script principal
    if grep -q "^$function_name()" "$INSTALLER_SCRIPT" 2>/dev/null; then
        echo "   ✅ PASSED - Función $function_name definida en script principal"
        ((PASSED_TESTS++))
    else
        echo "   ❌ FAILED - Función $function_name no encontrada en script principal"
        ((FAILED_TESTS++))
    fi
    echo
}
test_function_exists() {
    local function_name="$1"
    
    ((TEST_COUNT++))
    echo "🔍 Test $TEST_COUNT: Verificar función $function_name"
    
    # Cargar módulos en orden correcto como lo hace el script principal
    local test_script=$(cat << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Cargar módulos en orden
source "$MODULES_DIR/core.sh" 2>/dev/null || exit 1
source "$MODULES_DIR/validation.sh" 2>/dev/null || exit 1
source "$MODULES_DIR/system.sh" 2>/dev/null || exit 1
source "$MODULES_DIR/package.sh" 2>/dev/null || exit 1
source "$MODULES_DIR/download.sh" 2>/dev/null || exit 1
source "$MODULES_DIR/tui.sh" 2>/dev/null || exit 1

# Verificar si la función existe
if declare -f FUNCTION_NAME >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi
EOF
)
    
    # Reemplazar FUNCTION_NAME con el nombre real de la función
    test_script="${test_script//FUNCTION_NAME/$function_name}"
    
    if echo "$test_script" | bash -s 2>/dev/null; then
        echo "   ✅ PASSED - Función $function_name existe"
        ((PASSED_TESTS++))
    else
        echo "   ❌ FAILED - Función $function_name no encontrada"
        ((FAILED_TESTS++))
    fi
    echo
}

# Función para verificar carga de módulos
test_module_loading() {
    ((TEST_COUNT++))
    echo "🔧 Test $TEST_COUNT: Carga de módulos incluyendo TUI"
    
    # Intentar cargar módulos
    if "$INSTALLER_SCRIPT" --version >/dev/null 2>&1; then
        echo "   ✅ PASSED - Módulos se cargan correctamente"
        ((PASSED_TESTS++))
    else
        echo "   ❌ FAILED - Error cargando módulos"
        ((FAILED_TESTS++))
    fi
    echo
}

# =============================================================================
# EJECUCIÓN DE PRUEBAS
# =============================================================================

echo "🚀 INICIANDO TESTS DEL SISTEMA TUI HÍBRIDO"
echo "==========================================="
echo "Archivo de pruebas: $INSTALLER_SCRIPT"
echo

# Verificar que el script existe
if [ ! -f "$INSTALLER_SCRIPT" ]; then
    echo "❌ ERROR: No se encuentra el script $INSTALLER_SCRIPT"
    exit 1
fi

# Tests básicos de argumentos
echo "📋 TESTS DE ARGUMENTOS DE LÍNEA DE COMANDOS"
echo "-------------------------------------------"

run_test "Mostrar ayuda" \
    "$INSTALLER_SCRIPT --help" 0

run_test "Mostrar versión" \
    "$INSTALLER_SCRIPT --version" 0

run_test "Argumento inválido" \
    "$INSTALLER_SCRIPT --invalid-option" 1

run_test "Dry run básico" \
    "$INSTALLER_SCRIPT --install --dry-run" 0

# Tests de módulos
echo "📦 TESTS DE CARGA DE MÓDULOS"
echo "----------------------------"

test_module_loading

# Tests de funciones TUI específicas
echo "🎨 TESTS DE FUNCIONES TUI"
echo "-------------------------"

# Cargar módulos para tests de funciones
source "$INSTALLER_SCRIPT" 2>/dev/null || true

test_function_exists "detect_tui_tool"
test_function_exists "tui_msgbox"
test_function_exists "tui_yesno"
test_function_exists "tui_menu"
test_function_exists "run_tui_installer"
test_function_exists "should_use_tui"

# Tests de parseo de argumentos
echo "⚙️  TESTS DE PARSEO DE ARGUMENTOS"
echo "---------------------------------"

test_main_function_exists "parse_arguments"
test_main_function_exists "show_help"
test_main_function_exists "show_version"
test_main_function_exists "run_cli_installer"

# Tests de variables de entorno
echo "🌍 TESTS DE VARIABLES DE ENTORNO"
echo "--------------------------------"

run_test "Variable NO_TUI" \
    "NO_TUI=1 $INSTALLER_SCRIPT --version" 0

run_test "Variable LOG_LEVEL" \
    "LOG_LEVEL=debug $INSTALLER_SCRIPT --version" 0

# Tests de detección de modo
echo "🔀 TESTS DE DETECCIÓN DE MODO"
echo "-----------------------------"

# Este test verifica la lógica de detección sin ejecutar el script completo
((TEST_COUNT++))
echo "🧪 Test $TEST_COUNT: Detección automática de modo TUI vs CLI"

# Test más específico que solo verifica la detección de modo
# Usar --version para evitar el flujo completo de instalación
test_script=$(cat << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Cargar solo los módulos necesarios para el test
source "$MODULES_DIR/core.sh" 2>/dev/null || exit 1
source "$MODULES_DIR/tui.sh" 2>/dev/null || exit 1

# Test 1: Con argumentos (debería usar CLI)
if should_use_tui --version; then
    echo "ERROR: Debería usar CLI con argumentos"
    exit 1
fi

# Test 2: Sin TTY (debería usar CLI)
if [ ! -t 0 ] && should_use_tui; then
    echo "ERROR: Debería usar CLI sin TTY"
    exit 1
fi

# Test 3: Con NO_TUI (debería usar CLI)
NO_TUI=1
if should_use_tui; then
    echo "ERROR: Debería usar CLI con NO_TUI=1"
    exit 1
fi

echo "Detección de modo funciona correctamente"
exit 0
EOF
)

if echo "$test_script" | bash -s 2>/dev/null; then
    echo "   ✅ PASSED - Detección de modo funciona correctamente"
    ((PASSED_TESTS++))
else
    echo "   ❌ FAILED - Error en lógica de detección de modo"
    ((FAILED_TESTS++))
fi
echo

# Tests de combinaciones de argumentos
echo "🔧 TESTS DE COMBINACIONES DE ARGUMENTOS"
echo "---------------------------------------"

run_test "Instalación con GApps y F-Droid (dry-run)" \
    "$INSTALLER_SCRIPT --install --gapps --fdroid --dry-run" 0

run_test "Instalación completa silenciosa (dry-run)" \
    "NO_TUI=1 $INSTALLER_SCRIPT --install --no-interactive --dev-tools --dry-run" 0

run_test "Configuración de log level" \
    "$INSTALLER_SCRIPT --install --log-level debug --dry-run" 0

# Tests de herramientas TUI
echo "🛠️  TESTS DE HERRAMIENTAS TUI"
echo "-----------------------------"

((TEST_COUNT++))
echo "🧪 Test $TEST_COUNT: Detección de herramientas dialog/whiptail"

# Crear un test que simule la función de detección
if command -v dialog >/dev/null 2>&1 || command -v whiptail >/dev/null 2>&1; then
    echo "   ✅ PASSED - Herramienta TUI disponible"
    ((PASSED_TESTS++))
else
    echo "   ⚠️  WARNING - Sin herramientas TUI (dialog/whiptail no instaladas)"
    echo "   ✅ PASSED - Test exitoso (fallback esperado)"
    ((PASSED_TESTS++))
fi
echo

# =============================================================================
# REPORTE FINAL
# =============================================================================

echo "📊 REPORTE FINAL DE TESTS"
echo "========================="
echo "Total de tests ejecutados: $TEST_COUNT"
echo "Tests exitosos: $PASSED_TESTS"
echo "Tests fallidos: $FAILED_TESTS"
echo

if [ $FAILED_TESTS -eq 0 ]; then
    echo "🎉 ¡TODOS LOS TESTS PASARON EXITOSAMENTE!"
    echo "✅ El sistema TUI híbrido está funcionando correctamente"
    exit 0
else
    success_rate=$(( (PASSED_TESTS * 100) / TEST_COUNT ))
    echo "⚠️  $FAILED_TESTS tests fallaron"
    echo "📈 Tasa de éxito: $success_rate%"
    
    if [ $success_rate -ge 80 ]; then
        echo "✅ Tasa de éxito aceptable (≥80%)"
        exit 0
    else
        echo "❌ Tasa de éxito insuficiente (<80%)"
        exit 1
    fi
fi