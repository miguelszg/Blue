# 🚀 Blue-Green Deployment con Docker y Nginx

Implementación completa de estrategia de despliegue Blue-Green utilizando Docker, Nginx y scripts automatizados.

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Arquitectura](#-arquitectura)
- [Requisitos](#-requisitos)
- [Instalación](#-instalación)
- [Uso](#-uso)
- [Pipeline CI/CD](#-pipeline-cicd)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Comandos Útiles](#-comandos-útiles)

## 📖 Descripción

Este proyecto implementa una estrategia de despliegue **Blue-Green** que permite:

- ✅ Despliegues sin downtime
- ✅ Rollback instantáneo
- ✅ Pruebas en producción sin afectar usuarios
- ✅ Reducción de riesgo en despliegues

### ¿Qué es Blue-Green Deployment?

Es una técnica donde se mantienen dos ambientes idénticos de producción:
- **Blue (Azul)**: Ambiente activo sirviendo tráfico
- **Green (Verde)**: Ambiente en espera/actualización

Al desplegar una nueva versión:
1. Se actualiza el ambiente inactivo (ej. Green)
2. Se prueban los cambios en Green
3. Se cambia el tráfico de Blue a Green
4. Blue queda como respaldo para rollback instantáneo

## 🏗️ Arquitectura

```
                    Internet
                       |
                       ↓
              ┌─────────────────┐
              │   Nginx Proxy   │
              │    (Port 80)    │
              └─────────────────┘
                       |
         ┌─────────────┴─────────────┐
         ↓                           ↓
  ┌─────────────┐            ┌─────────────┐
  │  App Blue   │            │ App Green   │
  │  (Port 3000)│            │ (Port 3000) │
  │  Container  │            │  Container  │
  └─────────────┘            └─────────────┘
       ACTIVO                    STANDBY
```

**Componentes:**
- **Nginx**: Reverse proxy que dirige el tráfico
- **App Blue/Green**: Contenedores Docker con la aplicación Node.js
- **Scripts**: Automatización del despliegue y switch
- **Docker Compose**: Orquestación de contenedores

## 📦 Requisitos

- Docker 20.10+
- Docker Compose 2.0+
- Git
- Bash
- curl (para health checks)

### Instalación de Requisitos (Ubuntu/Debian)

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo apt install docker-compose-plugin -y

# Verificar instalación
docker --version
docker compose version
```

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/blue-green-deployment.git
cd blue-green-deployment
```

### 2. Dar Permisos de Ejecución

```bash
chmod +x scripts/*.sh
```

### 3. Iniciar los Servicios

```bash
# Construir las imágenes y levantar todos los contenedores
docker compose build
docker compose up -d

# Verificar que los contenedores estén corriendo
docker compose ps
```

### 4. Verificar Instalación

```bash
# Verificar health check
curl http://localhost/health

# Acceder a la aplicación
# Abre en tu navegador: http://localhost
```

## 💻 Uso

### Despliegue de Nueva Versión

```bash
# Desplegar versión 1.0.0
./scripts/deploy.sh 1.0.0

# Desplegar versión 2.0.0
./scripts/deploy.sh 2.0.0
```

**Este script:**
1. ✅ Detecta el ambiente activo actual
2. ✅ Construye la nueva imagen Docker
3. ✅ Actualiza el ambiente inactivo
4. ✅ Realiza health checks automáticos
5. ✅ Deja el nuevo ambiente listo para switch

### Cambiar de Ambiente (Switch)

```bash
# Cambiar del ambiente activo al actualizado
./scripts/switch.sh
```

**Este script:**
1. ✅ Verifica salud del nuevo ambiente
2. ✅ Actualiza configuración de Nginx
3. ✅ Recarga Nginx sin downtime
4. ✅ Verifica el cambio exitoso

### Rollback (Volver Atrás)

```bash
# El rollback es instantáneo - solo ejecuta switch de nuevo
./scripts/switch.sh
```

El ambiente anterior sigue corriendo, por lo que el rollback es inmediato.

## 🔄 Pipeline CI/CD

El proyecto incluye un pipeline de GitHub Actions que automatiza:

### Configuración de Secrets

En GitHub, ve a: `Settings → Secrets and variables → Actions`

Añade estos secrets:
- `SSH_PRIVATE_KEY`: Tu llave SSH privada
- `SSH_HOST`: IP o dominio de tu servidor
- `SSH_USER`: Usuario SSH (ej: ubuntu, miguelon)

### Funcionamiento del Pipeline

```yaml
Evento: Push a main
    ↓
Build & Test
    ↓
Deploy a Servidor
    ↓
Health Check
    ↓
✅ Listo
```

**Triggers:**
- Push a `main` → Deploy automático
- Push a `develop` → Solo build y test
- Workflow manual → Deploy con versión específica

## 📁 Estructura del Proyecto

```
blue-green-deployment/
├── app/                          # Aplicación Node.js
│   ├── server.js                 # Servidor Express
│   ├── package.json              # Dependencias
│   └── public/
│       └── index.html            # Frontend
├── nginx/
│   └── nginx.conf                # Configuración de Nginx
├── scripts/
│   ├── deploy.sh                 # Script de despliegue
│   └── switch.sh                 # Script de cambio de ambiente
├── .github/
│   └── workflows/
│       └── deploy.yml            # Pipeline CI/CD
├── Dockerfile                    # Imagen de la aplicación
├── docker-compose.yml            # Orquestación
├── .gitignore
└── README.md
```

## 🛠️ Comandos Útiles

### Docker

```bash
# Ver logs de un contenedor
docker logs app-blue
docker logs app-green
docker logs nginx-proxy

# Ver logs en tiempo real
docker logs -f app-blue

# Inspeccionar salud de contenedor
docker inspect --format='{{.State.Health.Status}}' app-blue

# Reiniciar un contenedor
docker restart app-blue

# Ver uso de recursos
docker stats
```

### Docker Compose

```bash
# Levantar servicios
docker compose up -d

# Detener servicios
docker compose down

# Reconstruir y levantar
docker compose up -d --build

# Ver logs de todos los servicios
docker compose logs -f

# Ver estado de servicios
docker compose ps
```

### Health Checks

```bash
# Verificar salud de la aplicación
curl http://localhost/health

# Ver información detallada
curl http://localhost/api/info | jq

# Verificar Nginx
curl http://localhost/nginx-status
```

### Limpieza

```bash
# Detener y eliminar contenedores
docker compose down

# Eliminar también volúmenes
docker compose down -v

# Limpiar imágenes huérfanas
docker image prune -a

# Limpieza completa de Docker
docker system prune -a --volumes
```

## 🧪 Testing

### Test Manual de Blue-Green

```bash
# 1. Ver ambiente actual
curl http://localhost/health | jq '.environment'

# 2. Desplegar nueva versión
./scripts/deploy.sh 2.0.0

# 3. Verificar que el inactivo se actualizó
docker logs app-green  # o app-blue según cuál sea inactivo

# 4. Hacer switch
./scripts/switch.sh

# 5. Verificar nuevo ambiente activo
curl http://localhost/health | jq '.environment'

# 6. Rollback si es necesario
./scripts/switch.sh
```

### Simular Fallo y Rollback

```bash
# 1. Detener el ambiente inactivo para simular fallo
docker stop app-green

# 2. Intentar switch (debe fallar)
./scripts/switch.sh
# ❌ Error: app-green no está saludable

# 3. Levantar de nuevo y corregir
docker start app-green
```

## 📊 Monitoreo

### Ver Estado del Sistema

```bash
# Estado completo
docker compose ps

# Salud de contenedores
for container in app-blue app-green; do
  echo "$container: $(docker inspect --format='{{.State.Health.Status}}' $container)"
done
```

### Logs Centralizados

```bash
# Ver todos los logs
docker compose logs -f

# Filtrar por servicio
docker compose logs -f nginx
```

## 🔐 Seguridad

- ✅ Contenedores corren con usuario no-root
- ✅ Health checks configurados
- ✅ Nginx como proxy reverso
- ✅ Logs de acceso habilitados
- ✅ Timeouts configurados

## 🐛 Troubleshooting

### Problema: Contenedor no está healthy

```bash
# Ver logs del contenedor
docker logs app-blue

# Verificar health check manualmente
docker exec app-blue curl http://localhost:3000/health
```

### Problema: Nginx no recarga

```bash
# Verificar configuración de Nginx
docker exec nginx-proxy nginx -t

# Recargar manualmente
docker exec nginx-proxy nginx -s reload
```

### Problema: Puerto 80 ya en uso

```bash
# Ver qué está usando el puerto
sudo lsof -i :80

# Detener el servicio conflictivo o cambiar puerto en docker-compose.yml
```

## 📚 Referencias

- [Blue-Green Deployment - Martin Fowler](https://martinfowler.com/bliki/BlueGreenDeployment.html)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## 👤 Autor

**Carlossbel**
- Proyecto: Huitzilin
- Universidad Tecnológica de Querétaro

## 📄 Licencia

Este proyecto es de código abierto para fines educativos.

---

**¡Disfruta desplegando sin downtime! 🚀**