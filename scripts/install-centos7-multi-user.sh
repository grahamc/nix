#!/bin/bash

set -eu
set -o pipefail

readonly SERVICE_SRC=/lib/systemd/system/nix-daemon.service
readonly SERVICE_DEST=/etc/systemd/system/nix-daemon.service

readonly SOCKET_SRC=/lib/systemd/system/nix-daemon.socket
readonly SOCKET_DEST=/etc/systemd/system/nix-daemon.socket

poly_validate_assumptions() {
    if [ "$(uname -s)" != "Linux" ]; then
        failure "This script is for use with Linux!"
    fi
}

poly_service_installed_check() {
    # !!! TODO: check use systemd is-linked / is-installed maybe?
    [ -e "$SERVICE_DEST" ] || [ -e "$SOCKET_DEST" ]
}

poly_service_uninstall_directions() {
        cat <<EOF
$1. Delete $SERVICE_DEST and $SOCKET_DEST

  !!! TODO Don't rm, use disable and unlink???
  sudo systemctl stop nix-daemon.service
  sudo systemctl stop nix-daemon.socket
  sudo systemctl daemon-reload
  sudo rm $SERVICE_DEST $SOCKET_DEST
EOF
}

poly_service_setup_note() {
    cat <<EOF
 - load and start a service (at $SERVICE_DEST
   and $SOCKET_DEST) for nix-daemon

EOF
}

polxy_configure_nix_daemon_service() {
    _sudo "to set up the nix-daemon service" \
          systemctl link "/nix/var/nix/profiles/default$SERVICE_SRC"

    _sudo "to set up the nix-daemon socket service" \
          systemctl enable "/nix/var/nix/profiles/default$SOCKET_SRC"

    _sudo "to load the systemd unit for nix-daemon" \
          systemctl daemon-reload

    _sudo "to start the nix-daemon.socket" \
          systemctl start nix-daemon.socket

    _sudo "to start the nix-daemon.service" \
          systemctl start nix-daemon.service

}

poly_group_exists() {
    getent group "$1" > /dev/null 2>&1
}

poly_group_id_get() {
    getent group "$1" | cut -d: -f3
}

poly_create_build_group() {
    _sudo "Create the Nix build group, $NIX_BUILD_GROUP_NAME" \
          groupadd -g "$NIX_BUILD_GROUP_ID" --system \
          "$NIX_BUILD_GROUP_NAME" >&2
}

poly_user_exists() {
    getent passwd "$1" > /dev/null 2>&1
}

poly_user_id_get() {
    getent passwd "$1" | cut -d: -f3
}

poly_user_hidden_get() {
    1
}

poly_user_hidden_set() {
    true
}

poly_user_home_get() {
    getent passwd "$1" | cut -d: -f6
}

poly_user_home_set() {
    _sudo "in order to give $1 a safe home directory" \
          usermod --home "$2" "$1"
}

poly_user_note_get() {
    getent passwd "$1" | cut -d: -f5
}

poly_user_note_set() {
    _sudo "in order to give $1 a useful comment" \
          usermod --comment "$2" "$1"
}

poly_user_shell_get() {
    getent passwd "$1" | cut -d: -f7
}

poly_user_shell_set() {
    _sudo "in order to prevent $1 from logging in" \
          usermod --shell "$2" "$1"
}

poly_user_in_group_check() {
    groups "$1" | grep -q "$2" > /dev/null 2>&1
}

poly_user_in_group_set() {
    _sudo "Add $1 to the $2 group"\
          usermod --append --groups "$2" "$1"
}

poly_user_primary_group_get() {
    getent passwd "$1" | cut -d: -f4
}

poly_user_primary_group_set() {
    _sudo "to let the nix daemon use this user for builds (this might seem redundant, but there are two concepts of group membership)" \
          usermod --gid "$2" "$1"

}

poly_create_build_user() {
    username=$1
    uid=$2
    builder_num=$3

    _sudo "Creating the Nix build user, $username" \
          useradd \
          --home-dir /var/empty \
          --comment "Nix build user $builder_num" \
          --gid "$NIX_BUILD_GROUP_ID" \
          --groups "$NIX_BUILD_GROUP_NAME" \
          --no-user-group \
          --system \
          --shell /sbin/nologin \
          --uid "$uid" \
          --password "!" \
          "$username"
}
