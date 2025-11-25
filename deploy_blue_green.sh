#!/bin/bash
set -e

APP_DIR="$HOME/blue"
ENV_FILE="$APP_DIR/.env"
cd "$APP_DIR"

echo "=========================================="
echo "🚀 Blue-Green Deployment"
echo "=========================================="

# Crear .env si no existe
if [ ! -f "$ENV_FILE" ]; then
    echo "CURRENT_PRODUCTION=green" > "$ENV_FILE"
fi

source "$ENV_FILE"

# Determinar slots
if [ "$CURRENT_PRODUCTION" == "blue" ]; then
    INACTIVE_SLOT="green"
    ACTIVE_SLOT="blue"
    INACTIVE_PORT=3002
else
    INACTIVE_SLOT="blue"
    ACTIVE_SLOT="green"
    INACTIVE_PORT=3001
fi

echo "📊 Activo: $ACTIVE_SLOT → Desplegando: $INACTIVE_SLOT (puerto $INACTIVE_PORT)"
echo "=========================================="

# Limpiar completamente el slot inactivo
echo "🧹 Limpiando $INACTIVE_SLOT..."
docker stop app-$INACTIVE_SLOT 2>/dev/null || true
docker rm -f app-$INACTIVE_SLOT 2>/dev/null || true

# Construir imagen
echo "🔨 Construyendo imagen..."
docker-compose build --no-cache $INACTIVE_SLOT

# Crear y arrancar contenedor nuevo
echo "▶️  Iniciando $INACTIVE_SLOT..."
docker-compose up -d --no-deps $INACTIVE_SLOT

# Health check
echo "🏥 Health check (15s)..."
sleep 15
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$INACTIVE_PORT/health || echo "000")

if [ "$HEALTH" -eq 200 ]; then
    echo "✅ Health check OK"
    
    # Actualizar nginx
    echo "🔄 Actualizando Nginx..."
    cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server app-$INACTIVE_SLOT:3000;
    }

    server {
        listen 80;
        
        location / {
            proxy_pass http://backend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /health {
            proxy_pass http://backend/health;
        }

        location /deployment-status {
            proxy_pass http://backend/deployment-status;
        }
    }
}
EOF
    
    docker-compose restart nginx
    sleep 5
    
    # Detener y ELIMINAR antiguo
    echo "🛑 Deteniendo y eliminando $ACTIVE_SLOT..."
    docker stop app-$ACTIVE_SLOT 2>/dev/null || true
    docker rm app-$ACTIVE_SLOT 2>/dev/null || true
    
    # Actualizar estado
    echo "CURRENT_PRODUCTION=$INACTIVE_SLOT" > "$ENV_FILE"
    
    echo "=========================================="
    echo "✅ Deploy exitoso: $INACTIVE_SLOT activo"
    echo "=========================================="
    curl -s http://localhost/deployment-status | jq -c 2>/dev/null || curl -s http://localhost/deployment-status
    
else
    echo "❌ Health check falló (HTTP $HEALTH)"
    docker stop app-$INACTIVE_SLOT 2>/dev/null || true
    docker rm -f app-$INACTIVE_SLOT 2>/dev/null || true
    exit 1
fi