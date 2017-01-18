/*
 * kore_preload.c
 *
 *  Created on: 23 nov 2016
 *      Author: Nicola 
 */

#include <webui.h>

 extern redisContext *log_redis;

void kore_preload() {
    WEBUI_DEBUG
    global_attributes = attrinit();
    int rv;

    log_redis = connect_redis(REDIS_HOST, REDIS_PORT, db_dynamic);
    if (!log_redis) {
        attributes_set_t att = attrinit();
        const char m[] = "Redis server is not running";
        webui_add_error_message(&global_attributes, m);
        err(m);

        rv = KORE_RESULT_ERROR;
    }

    WEBUI_DEBUG
    rv = load_global_attributes();


    if (rv == KORE_RESULT_ERROR) {
        /* La welcome page gestira' gli errori del kore_preload() */
    }

}

int check_if_reset_admin_device() {
    struct stat stat_buf;
    int rv;

    /* return if present RESET_ADMIN_FILE */
    rv = stat(RESET_ADMIN_FILE, &stat_buf);
    if (rv == 0) {

    }

    /* */
    return (rv == 0);
}

int reset_admin_device() {
    int rv = sqlexecute("UPDATE found set admin=null", &global_attributes);
    if (rv == KORE_RESULT_OK) {
        unlink(RESET_ADMIN_FILE);
    }
    return rv;
}

