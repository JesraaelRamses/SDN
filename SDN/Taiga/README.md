# SDN

This repository contains the infrastructure-as-code and configurations to deploy an automation and monitoring stack in a Software-Defined Networking (SDN) environment using containers with Podman.

It includes:

AWX (Ansible Tower open source) for automation
Prometheus + Grafana for observability
Taiga with SNMP and Mailhog for management and testing
All running on RHEL with Podman
Technologies
Podman (rootless containers)
Ansible AWX
Prometheus, Grafana
SNMP, Mailhog
Taiga
Networking: SDN on Dell VEP4600 (optional)
SDN


# Este repositorio contiene la infraestructura 

Como código y configuraciones para desplegar un stack de automatización y monitoreo en un entorno de Redes Definidas por Software (SDN) usando contenedores con Podman.

Incluye:

AWX (Ansible Tower open source) para automatización
Prometheus + Grafana para observabilidad
Taiga con SNMP y Mailhog para gestión y pruebas
Todo corriendo sobre RHEL con Podman
Tecnologías
Podman (contenedores rootless)
Ansible AWX
Prometheus, Grafana
SNMP, Mailhog
Taiga
Redes: SDN sobre Dell VEP4600 (opcional)


# Despliegue de Taiga con Podman (SRE Lab)

## ¿Qué es esto?
Este repositorio muestra mi trabajo como **Site Reliability Engineer** en la implementación de [Taiga.io](https://taiga.io) (plataforma de gestión de proyectos) usando **Podman** y **podman-compose**, sin Docker.

## Tecnologías utilizadas
- Podman (rootless)
- podman-compose
- PostgreSQL, RabbitMQ, Nginx
- Contenedores para: taiga-back, taiga-front, taiga-events, taiga-protected, mailhog, etc.
- Scripts de automatización (bash)
- Backup y recovery de datos persistentes

## ¿Qué demuestra este proyecto?

### 1. Automatización de infraestructura
- `docker-compose.yml`: definición de 10+ servicios con healthchecks, dependencias, redes y volúmenes.
- `launch-taiga.sh`: script para despliegue rápido.

### 2. Observabilidad y monitoreo (preparado)
- Integración con Prometheus/Grafana (no incluido aquí, pero lo he hecho en otros proyectos).

### 3. Gestión de backups y disaster recovery
- `taiga-backup.sh`: respaldo programado de base de datos (`pg_dump`) y archivos media.
- `taigaRestaura.md`: **documentación real de una recuperación tras caída**, incluyendo errores de restauración y soluciones paso a paso.

### 4. Resolución de problemas (troubleshooting)
- En `taigaRestaura.md` se detalla cómo resolví errores como:
  - `cannot drop the currently open database`
  - `multiple primary keys for table ...`
  - Uso de `pg_terminate_backend` y restauración desde base de datos `postgres`.

### 5. Integración de servicios
- `taiga.conf`: configuración de Nginx como reverse proxy, sirviendo API, admin, websockets y archivos protegidos.

## Cómo usar este repositorio (para quien lo clone)
1. Copiar `.env.example` a `.env` y ajustar variables.
2. Ejecutar `./launch-taiga.sh`
3. Crear superusuario: `./taiga-manage.sh createsuperuser`

## Lecciones aprendidas
- Podman rootless requiere mapeo de puertos > 1024 (usé 9201, 9210, etc.).
- La restauración de PostgreSQL falla si no se dropea la BD correctamente desde la base `postgres`.
- Los volúmenes de Podman persisten en `~/.local/share/containers/storage/volumes`.

## Autor
Jesraael Ramses González González  
SRE con 20 años de experiencia | CCNA, CCNP (en curso)  
[LinkedIn](url-de-linkedin) | [GitHub](url-de-github)