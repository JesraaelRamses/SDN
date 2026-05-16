#!/usr/bin/env sh

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2021-present Kaleidos INC

set -x
exec podman-compose -f docker-compose.yml up -d $@         # ejecucion normal
#exec podman-compose -f docker-compose.yml up $@           # para ver logs 
#exec podman-compose -f docker-compose.yml up > taiga-logs/taiga_logs_completo.md 2>&1 $@   # para ejecutar creando archivo con logs de arranque se guarda en carpeta taiga-logs 
#exec podman-compose -f docker-compose.yml up > taiga-logs/taiga_logs_healthys.md 2>&1 $@   # para ejecutar