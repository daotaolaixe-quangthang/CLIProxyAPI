#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT="${CLIPROXYAPI_INSTALL_ROOT:-$HOME/.local/share/cliproxyapi}"
BIN_DIR="${CLIPROXYAPI_BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${CLIPROXYAPI_CONFIG_DIR:-$HOME/.cli-proxy-api}"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_NAME="cliproxyapi.service"
PURGE_CONFIG="${CLIPROXYAPI_PURGE_CONFIG:-0}"

log() {
  printf '[uninstall] %s\n' "$*"
}

remove_if_exists() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    rm -rf "$path"
    log "Removed $path"
  fi
}

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now "$SERVICE_NAME" >/dev/null 2>&1 || true
  log "Stopped/disabled $SERVICE_NAME if it existed"
fi

remove_if_exists "$SYSTEMD_USER_DIR/$SERVICE_NAME"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

for cmd in \
  cliproxyapi \
  cliproxyapi-start \
  cliproxyapi-codex-login \
  cliproxyapi-claude-login \
  cliproxyapi-antigravity-login \
  cliproxyapi-gemini-login \
  cpaq \
  cliproxyapi-service-install \
  cliproxyapi-service-uninstall \
  cliproxyapi-service-start \
  cliproxyapi-service-stop \
  cliproxyapi-service-restart \
  cliproxyapi-service-status \
  cliproxyapi-service-logs
do
  remove_if_exists "$BIN_DIR/$cmd"
done

remove_if_exists "$INSTALL_ROOT"

if [ "$PURGE_CONFIG" = "1" ]; then
  remove_if_exists "$CONFIG_DIR"
else
  log "Kept $CONFIG_DIR"
  log "Set CLIPROXYAPI_PURGE_CONFIG=1 to remove OAuth/config data too"
fi
