


[DatosPersistentes](#método-de-recuperacion-de-datos-persistentes)
[BitacoraErrores](#bitacora)
































# Método de recuperacion de datos persistentes
### Pasos para Administrar los Datos sin Sudo:

1. **Verificar los volúmenes existentes**:
```bash
podman volume ls
```

2. **Localizar dónde Podman almacena los volúmenes** (esto varía por sistema):
```bash
# En la mayoría de sistemas
cd ~/.local/share/containers/storage/volumes

# O usando
podman volume inspect taiga-docker_taiga-db-data --format '{{.Mountpoint}}'
```

3. **Hacer backup de los datos importantes**:
```bash
# Backup de la base de datos (lo más crítico)
podman exec taiga-docker_taiga-db_1 pg_dump -U taiga taiga > taiga-db-backup.sql

# Backup de archivos subidos (si es necesario)
podman run --rm -v taiga-docker_taiga-media-data:/data -v $PWD:/backup busybox tar czf /backup/media-backup.tar.gz /data
```

### Para Recuperar Datos después de un Reinicio:

1. **Recrear los volúmenes** (se crearán automáticamente al hacer `podman-compose up`)

2. **Restaurar la base de datos**:

```bash

# Copiar el backup al contenedor
podman cp taiga-db-backup.sql taiga-docker_taiga-db_1:/tmp


# Restaurar
podman exec taiga-docker_taiga-db_1 psql -U taiga -d taiga -f /tmp/taiga-db-backup.sql

```

---

3. **Restaurar archivos media** (si es necesario):


```bash
podman run --rm -v taiga-docker_taiga-media-data:/data -v $PWD:/backup busybox tar xzf /backup/media-backup.tar.gz -C /data

```

### Ventajas de este Enfoque:

1. **Sin necesidad de sudo**: Todo se maneja dentro de los límites de tu usuario
2. **Persistencia mantenida**: Los volúmenes sobreviven a reinicios de contenedores
3. **Portabilidad**: Fácil de migrar a otro sistema
4. **Seguro**: No se requieren operaciones privilegiadas

---





# actualizacion por detencion de servicio bitacora 04/07/2025

# este archivo se ejecuta en el taiga backups el link se genera cuando se ejecuta el backup 

podman cp taiga-db-20250623.sql taiga-docker_taiga-db_1:/tmp

# este se ejecuta en el bash del proyecto en este caso taiga-docker

podman exec taiga-docker_taiga-db_1 psql -U taiga -d taiga -f /tmp/taiga-db-20250623.sql

---



# 3. **Restaurar archivos media** (si es necesario):
## se ejecuta en Backup

podman run --rm -v taiga-docker_taiga-media-data:/data -v $PWD:/backup busybox tar xzf /backup/media-20250623.tar.gz -C /data


```bash
podman run --rm \
  -v taiga-docker_taiga-media-data:/target_data \
  -v "$(pwd)":/backup \
  busybox sh -c "tar xzf /backup/media-20250623.tar.gz -O | tar xzf - -C /target_data"

```


---


```




# Metodo para descomprimir los archivos generados por el backup


¡Claro que sí\! Tienes una mezcla de archivos comprimidos y uno ya listo para usar. Aquí te explico cómo descomprimir cada tipo:

-----

## Descomprimir tus Archivos

Tienes dos tipos de archivos comprimidos: **`.tar.gz`** y **`.sql.gz`**. También hay un archivo **`.sql`** que no necesita descompresión.

  * **Archivos `.tar.gz`** (por ejemplo, `media-20250704.tar.gz`): Estos son archivos `tar` que han sido comprimidos con `gzip`. Usarás el comando `tar` con las opciones `-zxvf`.

      * `z`: Le dice a `tar` que use `gzip` para descomprimir.
      * `x`: Extrae los archivos.
      * `v`: Muestra los archivos a medida que se extraen (modo "verbose").
      * `f`: Especifica el archivo de donde se extraerá la información.

    Para descomprimir `media-20250704.tar.gz`, ejecutarías:

    ```bash
    tar -zxvf media-20250704.tar.gz
    ```

    Esto extraerá el contenido del archivo `tar` en el directorio actual.

  * **Archivos `.sql.gz`** (por ejemplo, `taiga-db-20250623.sql.gz`): Estos son archivos individuales comprimidos con `gzip`. Usarás el comando `gunzip`.

    Para descomprimir `taiga-db-20250623.sql.gz`, ejecutarías:

    ```bash
    gunzip taiga-db-20250623.sql.gz
    ```

    Esto descomprimirá el archivo, dejándote con `taiga-db-20250623.sql` en el mismo directorio.

  * **Archivos `.sql`** (por ejemplo, `taiga-db-20250704.sql`): Estos son archivos de volcado de SQL estándar y no están comprimidos. No necesitas hacer nada con ellos; ya están listos para ser usados.

-----

**En resumen, aquí están los comandos específicos para tus archivos:**

```bash
tar -zxvf media-20250623.tar.gz
tar -zxvf media-20250704.tar.gz
gunzip taiga-db-20250623.sql.gz
# El archivo taiga-db-20250704.sql ya está descomprimido
```

¡Espero que esto te sea útil\! ¿Necesitas ayuda con algo más?



---

# Mejora de restauracion

### Entendiendo los Errores de Restauración de PostgreSQL

Los errores que estás viendo, como `ERROR: relation "..." already exists` y `ERROR: multiple primary keys for table "..." are not allowed`, indican que estás intentando **restaurar un backup de base de datos en una base de datos que ya contiene las tablas y estructuras que el backup intenta crear**.

Esto sucede porque `pg_dump` por defecto crea un archivo `.sql` que incluye no solo los datos, sino también los comandos para **crear las tablas, índices, claves primarias, etc.**

Cuando `podman-compose up` se ejecuta, generalmente inicializa una base de datos PostgreSQL con su esquema predeterminado o con un esquema básico de Taiga (si el contenedor lo hace en el primer arranque). Al intentar restaurar el backup sobre esta base de datos preexistente, PostgreSQL se queja porque las tablas ya existen.

-----


### Entendiendo los Nuevos Errores (en español)

Los errores que estás viendo:

  * `ERROR: cannot drop the currently open database`: Esto sucede porque cuando ejecutas `psql -U taiga -c "DROP DATABASE taiga;"`, `psql` está intentando conectarse por defecto a la base de datos `taiga`. No puedes eliminar una base de datos mientras estás conectado a ella. Es como intentar cortar la rama en la que estás sentado.
  * `ERROR: database "taiga" already exists`: Esto es esperado si el comando `DROP DATABASE` anterior falló. La base de datos sigue existiendo, por lo que no puedes crearla de nuevo.

-----

### El Procedimiento Corregido de Restauración de Base de Datos

Para poder eliminar una base de datos correctamente en PostgreSQL, necesitas conectarte a una **base de datos diferente** (como la base de datos predeterminada `postgres`) antes de intentar eliminar la base de datos objetivo (`taiga`).

Aquí está el procedimiento refinado:

1.  **Asegúrate de que solo el contenedor `taiga-db` esté corriendo:**

    ```bash
    podman-compose stop # Detén todos los servicios si están corriendo
    podman-compose up -d taiga-db # Inicia solo el contenedor de la base de datos
    ```

    Espera unos segundos para que se inicialice completamente.

2.  **Desconecta todas las sesiones activas de la base de datos `taiga`, mientras estás conectado a `postgres`:**
    Este es el paso crucial. Debes indicarle a `psql` que se conecte primero a la base de datos `postgres`.

    ```bash
    podman exec taiga-docker_taiga-db_1 psql -U taiga -d postgres -c \
    "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = 'taiga' AND pid <> pg_backend_pid();"
    ```

    **Fíjate en el `-d postgres`**: Esto le dice a `psql` que se conecte a la base de datos `postgres`.

3.  **Elimina la base de datos `taiga`, mientras estás conectado a `postgres`:**
    Ahora que todas las demás conexiones están terminadas, y estás conectado a `postgres`, puedes eliminar la base de datos `taiga`.

    ```bash
    podman exec taiga-docker_taiga-db_1 psql -U taiga -d postgres -c "DROP DATABASE taiga;"
    ```

    **De nuevo, fíjate en el `-d postgres`**. Si sigues obteniendo un error aquí, significa que hay otra conexión persistente. Podrías necesitar ejecutar el paso 2 varias veces, o incluso reiniciar el contenedor `taiga-db` si las conexiones persisten.

4.  **Vuelve a crear la base de datos `taiga` vacía, mientras estás conectado a `postgres`:**

    ```bash
    podman exec taiga-docker_taiga-db_1 psql -U taiga -d postgres -c "CREATE DATABASE taiga WITH OWNER taiga ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C' TEMPLATE template0;"
    ```

    **Todavía con `-d postgres` aquí.**

5.  **Copia el archivo de backup SQL dentro del contenedor:**
    Asegúrate de ejecutar esto desde el directorio donde guardaste tu backup (`~/taiga-backups/`).

    ```bash
    podman cp taiga-db-20250623.sql taiga-docker_taiga-db_1:/tmp/taiga-db-20250623.sql
    ```

6.  **Restaura el backup de la base de datos (ahora conectado a `taiga`):**
    Una vez que la base de datos ha sido eliminada y recreada, finalmente puedes conectarte directamente a la base de datos `taiga` para restaurar los datos.

    ```bash
    podman exec taiga-docker_taiga-db_1 psql -U taiga -d taiga -f /tmp/taiga-db-20250623.sql
    ```

    Esto debería importar tus datos sin errores de "ya existe".

-----

7.  **Restaurar archivos media (si es necesario):**
    Ejecuta esto desde tu directorio `~/taiga-backups/`. Recuerda el comando corregido para evitar la carpeta `data` duplicada:
    ```bash
    podman run --rm \
      -v taiga-docker_taiga-media-data:/target_data \
      -v "$(pwd)":/backup \
      busybox sh -c "tar xzf /backup/media-20250623.tar.gz -O | tar xzf - -C /target_data"
    ```

-----

8.  **Inicia todos los servicios de Taiga:**
    ```bash
    podman-compose up -d
    ```

La clave para el éxito es siempre **conectarse a una base de datos diferente** (como `postgres`) cuando quieras eliminar o crear otra base de datos. Una vez que la base de datos objetivo existe y está lista, puedes conectarte directamente a ella para operaciones de datos como la importación con `psql -f`.

¿Hay algún otro paso o error que necesitemos revisar?


































# Historico de Errores al restaurar 



















































































# Bitacora

## Bitacora caida de servicio 04/07/2025
### Error por duplicidad de tablas es necesario 
### eliminar la base de datos para agregar el back
---

 setval 
--------
      1
(1 row)

 setval 
--------
      8
(1 row)

 setval 
--------
    522
(1 row)

 setval 
--------
    529
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      6
(1 row)

 setval 
--------
      8
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

 setval 
--------
      1
(1 row)

psql:/tmp/taiga-db-20250623.sql:6468: ERROR:  multiple primary keys for table "attachments_attachment" are not allowed
psql:/tmp/taiga-db-20250623.sql:6476: ERROR:  relation "auth_group_name_key" already exists
psql:/tmp/taiga-db-20250623.sql:6484: ERROR:  relation "auth_group_permissions_group_id_permission_id_0cd325b0_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6492: ERROR:  multiple primary keys for table "auth_group_permissions" are not allowed
psql:/tmp/taiga-db-20250623.sql:6500: ERROR:  multiple primary keys for table "auth_group" are not allowed
psql:/tmp/taiga-db-20250623.sql:6508: ERROR:  relation "auth_permission_content_type_id_codename_01ab375a_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6516: ERROR:  multiple primary keys for table "auth_permission" are not allowed
psql:/tmp/taiga-db-20250623.sql:6524: ERROR:  multiple primary keys for table "contact_contactentry" are not allowed
psql:/tmp/taiga-db-20250623.sql:6532: ERROR:  relation "custom_attributes_epiccu_project_id_name_3850c31d_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6540: ERROR:  multiple primary keys for table "custom_attributes_epiccustomattribute" are not allowed
psql:/tmp/taiga-db-20250623.sql:6548: ERROR:  relation "custom_attributes_epiccustomattributesvalues_epic_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:6556: ERROR:  multiple primary keys for table "custom_attributes_epiccustomattributesvalues" are not allowed
psql:/tmp/taiga-db-20250623.sql:6564: ERROR:  relation "custom_attributes_issuec_project_id_name_6f71f010_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6572: ERROR:  multiple primary keys for table "custom_attributes_issuecustomattribute" are not allowed
psql:/tmp/taiga-db-20250623.sql:6580: ERROR:  relation "custom_attributes_issuecustomattributesvalues_issue_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:6588: ERROR:  multiple primary keys for table "custom_attributes_issuecustomattributesvalues" are not allowed
psql:/tmp/taiga-db-20250623.sql:6596: ERROR:  relation "custom_attributes_taskcu_project_id_name_c1c55ac2_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6604: ERROR:  multiple primary keys for table "custom_attributes_taskcustomattribute" are not allowed
psql:/tmp/taiga-db-20250623.sql:6612: ERROR:  multiple primary keys for table "custom_attributes_taskcustomattributesvalues" are not allowed
psql:/tmp/taiga-db-20250623.sql:6620: ERROR:  relation "custom_attributes_taskcustomattributesvalues_task_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:6628: ERROR:  relation "custom_attributes_userst_project_id_name_86c6b502_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6636: ERROR:  multiple primary keys for table "custom_attributes_userstorycustomattribute" are not allowed
psql:/tmp/taiga-db-20250623.sql:6644: ERROR:  relation "custom_attributes_userstorycustomattributesva_user_story_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:6652: ERROR:  multiple primary keys for table "custom_attributes_userstorycustomattributesvalues" are not allowed
psql:/tmp/taiga-db-20250623.sql:6660: ERROR:  multiple primary keys for table "django_admin_log" are not allowed
psql:/tmp/taiga-db-20250623.sql:6668: ERROR:  relation "django_content_type_app_label_model_76bd3d3b_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6676: ERROR:  multiple primary keys for table "django_content_type" are not allowed
psql:/tmp/taiga-db-20250623.sql:6684: ERROR:  multiple primary keys for table "django_migrations" are not allowed
psql:/tmp/taiga-db-20250623.sql:6692: ERROR:  multiple primary keys for table "django_session" are not allowed
psql:/tmp/taiga-db-20250623.sql:6700: ERROR:  multiple primary keys for table "djmail_message" are not allowed
psql:/tmp/taiga-db-20250623.sql:6708: ERROR:  multiple primary keys for table "easy_thumbnails_source" are not allowed
psql:/tmp/taiga-db-20250623.sql:6716: ERROR:  relation "easy_thumbnails_source_storage_hash_name_481ce32d_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6724: ERROR:  relation "easy_thumbnails_thumbnai_storage_hash_name_source_fb375270_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6732: ERROR:  multiple primary keys for table "easy_thumbnails_thumbnail" are not allowed
psql:/tmp/taiga-db-20250623.sql:6740: ERROR:  multiple primary keys for table "easy_thumbnails_thumbnaildimensions" are not allowed
psql:/tmp/taiga-db-20250623.sql:6748: ERROR:  relation "easy_thumbnails_thumbnaildimensions_thumbnail_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:6756: ERROR:  multiple primary keys for table "epics_epic" are not allowed
psql:/tmp/taiga-db-20250623.sql:6764: ERROR:  multiple primary keys for table "epics_relateduserstory" are not allowed
psql:/tmp/taiga-db-20250623.sql:6772: ERROR:  relation "epics_relateduserstory_user_story_id_epic_id_ad704d40_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6780: ERROR:  relation "external_apps_applicatio_application_id_user_id_b6a9e9a8_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6788: ERROR:  multiple primary keys for table "external_apps_application" are not allowed
psql:/tmp/taiga-db-20250623.sql:6796: ERROR:  multiple primary keys for table "external_apps_applicationtoken" are not allowed
psql:/tmp/taiga-db-20250623.sql:6804: ERROR:  multiple primary keys for table "feedback_feedbackentry" are not allowed
psql:/tmp/taiga-db-20250623.sql:6812: ERROR:  multiple primary keys for table "history_historyentry" are not allowed
psql:/tmp/taiga-db-20250623.sql:6820: ERROR:  multiple primary keys for table "issues_issue" are not allowed
psql:/tmp/taiga-db-20250623.sql:6828: ERROR:  relation "likes_like_content_type_id_object_id_user_id_e20903f0_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6836: ERROR:  multiple primary keys for table "likes_like" are not allowed
psql:/tmp/taiga-db-20250623.sql:6844: ERROR:  relation "milestones_milestone_name_project_id_fe19fd36_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6852: ERROR:  multiple primary keys for table "milestones_milestone" are not allowed
psql:/tmp/taiga-db-20250623.sql:6860: ERROR:  relation "milestones_milestone_slug_project_id_e59bac6a_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6868: ERROR:  relation "notifications_historycha_historychangenotificatio_3b0f323b_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6876: ERROR:  relation "notifications_historycha_historychangenotificatio_8fb55cdd_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6884: ERROR:  relation "notifications_historycha_key_owner_id_project_id__869f948f_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6892: ERROR:  multiple primary keys for table "notifications_historychangenotification_history_entries" are not allowed
psql:/tmp/taiga-db-20250623.sql:6900: ERROR:  multiple primary keys for table "notifications_historychangenotification_notify_users" are not allowed
psql:/tmp/taiga-db-20250623.sql:6908: ERROR:  multiple primary keys for table "notifications_historychangenotification" are not allowed
psql:/tmp/taiga-db-20250623.sql:6916: ERROR:  multiple primary keys for table "notifications_notifypolicy" are not allowed
psql:/tmp/taiga-db-20250623.sql:6924: ERROR:  relation "notifications_notifypolicy_project_id_user_id_e7aa5cf2_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6932: ERROR:  relation "notifications_watched_content_type_id_object_i_e7c27769_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6940: ERROR:  multiple primary keys for table "notifications_watched" are not allowed
psql:/tmp/taiga-db-20250623.sql:6948: ERROR:  multiple primary keys for table "notifications_webnotification" are not allowed
psql:/tmp/taiga-db-20250623.sql:6956: ERROR:  multiple primary keys for table "projects_epicstatus" are not allowed
psql:/tmp/taiga-db-20250623.sql:6964: ERROR:  relation "projects_epicstatus_project_id_name_b71c417e_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6972: ERROR:  relation "projects_epicstatus_project_id_slug_f67857e5_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6980: ERROR:  multiple primary keys for table "projects_issueduedate" are not allowed
psql:/tmp/taiga-db-20250623.sql:6988: ERROR:  relation "projects_issueduedate_project_id_name_cba303bc_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:6996: ERROR:  multiple primary keys for table "projects_issuestatus" are not allowed
psql:/tmp/taiga-db-20250623.sql:7004: ERROR:  relation "projects_issuestatus_project_id_name_a88dd6c0_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:7012: ERROR:  relation "projects_issuestatus_project_id_slug_ca3e758d_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:7020: ERROR:  multiple primary keys for table "projects_issuetype" are not allowed
psql:/tmp/taiga-db-20250623.sql:7028: ERROR:  relation "projects_issuetype_project_id_name_41b47d87_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:7036: ERROR:  multiple primary keys for table "projects_membership" are not allowed
psql:/tmp/taiga-db-20250623.sql:7044: ERROR:  relation "projects_membership_user_id_project_id_a2829f61_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:7052: ERROR:  multiple primary keys for table "projects_points" are not allowed
psql:/tmp/taiga-db-20250623.sql:7060: ERROR:  relation "projects_points_project_id_name_900c69f4_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:7068: ERROR:  multiple primary keys for table "projects_priority" are not allowed
psql:/tmp/taiga-db-20250623.sql:7076: ERROR:  relation "projects_priority_project_id_name_ca316bb1_uniq" already exists
psql:/tmp/taiga-db-20250623.sql:7084: ERROR:  relation "projects_project_default_epic_status_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7092: ERROR:  relation "projects_project_default_issue_status_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7100: ERROR:  relation "projects_project_default_issue_type_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7108: ERROR:  relation "projects_project_default_points_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7116: ERROR:  relation "projects_project_default_priority_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7124: ERROR:  relation "projects_project_default_severity_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7132: ERROR:  relation "projects_project_default_swimlane_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7140: ERROR:  relation "projects_project_default_task_status_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7148: ERROR:  relation "projects_project_default_us_status_id_key" already exists
psql:/tmp/taiga-db-20250623.sql:7156: ERROR:  multiple primary keys for table "projects_project" are not allowed
psql:/tmp/taiga-db-20250623.sql:7164: ERROR:  relation "projects_project_slug_key" already exists
psql:/tmp/taiga-db-20250623.sql:7172: ERROR:  multiple primary keys for table "projects_projectmodulesconfig" are not allowed
psql:/tmp/taiga-db-20250623.sql:7180: ERROR:  relation "projects_projectmodulesconfig_project_id_key" already exists




---