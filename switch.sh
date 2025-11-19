#!/bin/bash

TARGET=$1

if [ -z "$TARGET" ]; then
    echo "Uso: ./switch.sh [blue|green]"
    exit 1
fi

if [ "$TARGET" != "blue" ] && [ "$TARGET" != "green" ]; then
    echo "Error: TARGET debe ser 'blue' o 'green'"
    exit 1
fi

echo "Cambiando tráfico a $TARGET..."

# Crear configuración temporal
cat > /tmp/nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server app-$TARGET:3000;
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
            access_log off;
        }
    }
}
EOF

# Copiar al contenedor y recargar
docker cp /tmp/nginx.conf nginx-proxy:/etc/nginx/nginx.conf
docker exec nginx-proxy nginx -s reload

echo "✓ Tráfico cambiado a $TARGET"