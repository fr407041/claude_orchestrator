#!/usr/bin/env bash
set -euo pipefail

: "${RPI_HOST:=}"
: "${RPI_USER:=pi}"
: "${RPI_PORT:=22}"
: "${RPI_PASSWORD:=}"
: "${RPI_SSH_KEY_PATH:=}"
: "${RPI_REMOTE_BASE_DIR:=/home/${RPI_USER}/claude-router-node}"

rpi_require_connection_env() {
  if [[ -z "$RPI_HOST" ]]; then
    echo "RPI_HOST is required." >&2
    exit 2
  fi

  if [[ -n "$RPI_PASSWORD" && -n "$RPI_SSH_KEY_PATH" ]]; then
    echo "Set only one of RPI_PASSWORD or RPI_SSH_KEY_PATH." >&2
    exit 2
  fi

  if [[ -z "$RPI_PASSWORD" && -z "$RPI_SSH_KEY_PATH" ]]; then
    echo "One of RPI_PASSWORD or RPI_SSH_KEY_PATH is required." >&2
    exit 2
  fi

  if [[ -n "$RPI_SSH_KEY_PATH" && ! -f "$RPI_SSH_KEY_PATH" ]]; then
    echo "RPI_SSH_KEY_PATH does not exist: $RPI_SSH_KEY_PATH" >&2
    exit 2
  fi
}

rpi_target() {
  printf '%s\n' "${RPI_USER}@${RPI_HOST}"
}

rpi_ssh_base_cmd() {
  local -a cmd
  cmd=(
    ssh
    -p "$RPI_PORT"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
    -o ServerAliveInterval=15
    -o ServerAliveCountMax=3
  )
  if [[ -n "$RPI_SSH_KEY_PATH" ]]; then
    cmd+=(-i "$RPI_SSH_KEY_PATH")
  fi
  printf '%s\n' "${cmd[@]}"
}

rpi_scp_base_cmd() {
  local -a cmd
  cmd=(
    scp
    -P "$RPI_PORT"
    -o StrictHostKeyChecking=no
    -o UserKnownHostsFile=/dev/null
  )
  if [[ -n "$RPI_SSH_KEY_PATH" ]]; then
    cmd+=(-i "$RPI_SSH_KEY_PATH")
  fi
  printf '%s\n' "${cmd[@]}"
}

rpi_require_sshpass_if_needed() {
  if [[ -n "$RPI_PASSWORD" ]] && ! command -v sshpass >/dev/null 2>&1; then
    echo "sshpass is required when using RPI_PASSWORD." >&2
    exit 2
  fi
}

rpi_ssh() {
  rpi_require_connection_env
  rpi_require_sshpass_if_needed
  local target
  target="$(rpi_target)"
  local -a cmd
  readarray -t cmd < <(rpi_ssh_base_cmd)
  if [[ -n "$RPI_PASSWORD" ]]; then
    sshpass -p "$RPI_PASSWORD" "${cmd[@]}" "$target" "$@"
  else
    "${cmd[@]}" "$target" "$@"
  fi
}

rpi_scp_to() {
  rpi_require_connection_env
  rpi_require_sshpass_if_needed
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  local target
  target="$(rpi_target)"
  local -a cmd
  readarray -t cmd < <(rpi_scp_base_cmd)
  if [[ -n "$RPI_PASSWORD" ]]; then
    sshpass -p "$RPI_PASSWORD" "${cmd[@]}" "$src" "${target}:${dst}"
  else
    "${cmd[@]}" "$src" "${target}:${dst}"
  fi
}

rpi_scp_from() {
  rpi_require_connection_env
  rpi_require_sshpass_if_needed
  local src="${1:?src required}"
  local dst="${2:?dst required}"
  local target
  target="$(rpi_target)"
  local -a cmd
  readarray -t cmd < <(rpi_scp_base_cmd)
  if [[ -n "$RPI_PASSWORD" ]]; then
    sshpass -p "$RPI_PASSWORD" "${cmd[@]}" "${target}:${src}" "$dst"
  else
    "${cmd[@]}" "${target}:${src}" "$dst"
  fi
}
