#!/bin/bash

# El contexto de este archivo es el poder recuperar la informnación mas importante 
# ya que debe ser persistente la información trabajada 
# 


# Backup de base de datos
podman exec taiga-docker_taiga-db_1 pg_dump -U taiga taiga > ~/taiga-backups/taiga-db-$(date +%Y%m%d).sql

# Backup de media (opcional)
podman run --rm -v taiga-docker_taiga-media-data:/data -v ~/taiga-backups:/backup busybox tar czf /backup/media-$(date +%Y%m%d).tar.gz /data

echo "Backups guardados en ~/taiga-backups"