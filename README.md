# SDN
Este repositorio contiene la infraestructura como código y configuraciones para desplegar un stack de automatización y monitoreo en un entorno de Redes Definidas por Software (SDN) usando contenedores con Podman.

Incluye:
- AWX (Ansible Tower open source) para automatización
- Prometheus + Grafana para observabilidad
- Taiga con SNMP y Mailhog para gestión y pruebas
- Todo corriendo sobre RHEL con Podman

## Tecnologías
- Podman (contenedores rootless)
- Ansible AWX
- Prometheus, Grafana
- SNMP, Mailhog
- Taiga
- Redes: SDN sobre Dell VEP4600 (opcional)
