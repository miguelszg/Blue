# #!/bin/bash

# # Colores para output
# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[1;33m'
# NC='\033[0m' # No Color

# echo -e "${GREEN}=== Iniciando Deploy Blue-Green ===${NC}"

# # Determinar el entorno activo actual
# CURRENT=$(docker exec nginx-proxy cat /etc/nginx/nginx.conf | grep "server app-" | awk '{print $2}' | cut -d':' -f1 | cut -d'-' -f2)

# if [ "$CURRENT" == "blue" ]; then
#     ACTIVE="blue"
#     INACTIVE="green"
# else
#     ACTIVE="green"
#     INACTIVE="blue"
# fi

# echo -e "${YELLOW}Entorno activo: $ACTIVE${NC}"
# echo -e "${YELLOW}Desplegando en: $INACTIVE${NC}"

# # Build de la nueva versión
# echo -e "${GREEN}Construyendo imagen Docker...${NC}"
# docker-compose build $INACTIVE

# # Iniciar contenedor inactivo
# echo -e "${GREEN}Iniciando contenedor $INACTIVE...${NC}"
# docker-compose up -d $INACTIVE

# # Health check
# echo -e "${GREEN}Verificando salud del servicio...${NC}"
# sleep 5

# HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:300$([ "$INACTIVE" == "blue" ] && echo "1" || echo "2")/health)

# if [ "$HEALTH_CHECK" -eq 200 ]; then
#     echo -e "${GREEN}✓ Health check exitoso${NC}"
    
#     # Ejecutar switch
#     echo -e "${GREEN}Cambiando tráfico a $INACTIVE...${NC}"
#     ./switch.sh $INACTIVE
    
#     # Esperar un poco
#     sleep 3
    
#     # Detener contenedor antiguo
#     echo -e "${YELLOW}Deteniendo contenedor $ACTIVE...${NC}"
#     docker-compose stop $ACTIVE
    
#     echo -e "${GREEN}=== Deploy completado exitosamente ===${NC}"
# else
#     echo -e "${RED}✗ Health check falló. Rollback...${NC}"
#     docker-compose stop $INACTIVE
#     exit 1
# fi