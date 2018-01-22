#!/bin/sh

log() {
    echo "$(date) $*" >> /unifi/cert/unifi-cert-update.log
}

if $(md5sum -c "/unifi/cert/cert.pem.md5" &>/dev/null); then
    log "no changes"
    exit 0
fi

log "restarting..."
docker service update --force unifi_controller &>/dev/null
