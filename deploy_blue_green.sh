#!/bin/bash
set -e

# --- Configuración ---
APP_DIR="$HOME/blue"
ENV_FILE="$APP_DIR/.env"

cd "$APP_DIR"

echo "=========================================="
echo "🚀 Blue-Green Deployment"
echo "=========================================="

# --- 1. Leer el estado actual ---
if [ ! -f "$ENV_FILE" ]; then
    echo "📝 Creando .env inicial con blue"
    echo "CURRENT_PRODUCTION=blue" > "$ENV_FILE"
fi

source "$ENV_FILE"

# --- 2. Determinar slots ---
if [ "$CURRENT_PRODUCTION" == "blue" ]; then
    INACTIVE_SLOT="green"
    ACTIVE_SLOT="blue"
    INACTIVE_PORT=3002
else
    INACTIVE_SLOT="blue"
    ACTIVE_SLOT="green"
    INACTIVE_PORT=3001
fi

echo "📊 Entorno activo actual: $ACTIVE_SLOT"
echo "🎯 Desplegando en: $INACTIVE_SLOT (puerto $INACTIVE_PORT)"
echo "=========================================="

# --- 3. Construir nueva imagen ---
echo "🔨 Construyendo imagen para $INACTIVE_SLOT..."
docker-compose build --no-cache $INACTIVE_SLOT

# --- 4. Detener el contenedor inactivo si existe ---
echo "🛑 Deteniendo $INACTIVE_SLOT (si existe)..."
docker-compose stop $INACTIVE_SLOT 2>/dev/null || true

# --- 5. Iniciar contenedor inactivo ---
echo "▶️  Iniciando contenedor $INACTIVE_SLOT..."
docker-compose up -d $INACTIVE_SLOT

# --- 6. Health check ---
echo "🏥 Esperando 10s para health check..."
sleep 10

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$INACTIVE_PORT/health)

if [ "$HEALTH_CHECK" -eq 200 ]; then
    echo "✅ Health check exitoso en puerto $INACTIVE_PORT"
    
    # --- 7. Actualizar nginx.conf para apuntar al nuevo contenedor ---
    echo "🔄 Cambiando tráfico de Nginx a $INACTIVE_SLOT..."
    
    sed -i "s/server app-blue:3000;/server app-$INACTIVE_SLOT:3000;/g" nginx.conf
    sed -i "s/server app-green:3000;/server app-$INACTIVE_SLOT:3000;/g" nginx.conf
    
    # Reiniciar nginx para aplicar cambios
    docker-compose restart nginx
    
    echo "⏳ Esperando 5s para que Nginx aplique cambios..."
    sleep 5
    
    # --- 8. Detener contenedor antiguo ---
    echo "🛑 Deteniendo contenedor antiguo: $ACTIVE_SLOT..."
    docker-compose stop $ACTIVE_SLOT
    
    # --- 9. Actualizar estado ---
    echo "CURRENT_PRODUCTION=$INACTIVE_SLOT" > "$ENV_FILE"
    
    echo "=========================================="
    echo "✅ ¡Despliegue completado exitosamente!"
    echo "📦 Nuevo entorno activo: $INACTIVE_SLOT"
    echo "🔌 Puerto: $INACTIVE_PORT"
    echo "=========================================="
    
    # Mostrar estado final
    echo ""
    echo "Estado final:"
    curl -s http://localhost/deployment-status | jq 2>/dev/null || curl -s http://localhost/deployment-status
    
else
    echo "❌ Health check falló en puerto $INACTIVE_PORT (HTTP $HEALTH_CHECK)"
    echo "🔙 Rollback: deteniendo $INACTIVE_SLOT"
    docker-compose stop $INACTIVE_SLOT
    exit 1
fi