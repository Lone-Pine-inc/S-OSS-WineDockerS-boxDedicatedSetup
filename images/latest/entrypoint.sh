#!/bin/bash
# ============================================================
#  s&box Dedicated Server — native Linux entrypoint
#  Runs sbox-server.dll under the .NET 10 runtime. No Wine.
# ============================================================
set -e

SBOX_DIR="${SBOX_DIR:-/home/sboxserver/sbox}"
STEAMCMD_DIR="${STEAMCMD_DIR:-/opt/steamcmd}"

mkdir -p "${SBOX_DIR}"
cd "${SBOX_DIR}"

# Give .NET a sane console size; s&box throws ArgumentOutOfRangeException if
# Console.WindowWidth returns -1 (happens on a PTY with no dimensions set).
export TERM="${TERM:-xterm-256color}"
stty cols 120 rows 30 2>/dev/null || true

# SteamCMD permissions can be reset by a volume mount.
chmod +x "${STEAMCMD_DIR}/steamcmd.sh" 2>/dev/null || true
chmod +x "${STEAMCMD_DIR}/linux32/steamcmd" 2>/dev/null || true

# Validate / update the native Linux server on every start (anonymous login).
if [ "${SBOX_AUTO_UPDATE:-1}" = "1" ]; then
    "${STEAMCMD_DIR}/steamcmd.sh" \
        +force_install_dir "${SBOX_DIR}" \
        +login anonymous \
        +app_update 1892930 validate \
        +quit
fi

# The native server bundles its own libraries here.
export LD_LIBRARY_PATH="${SBOX_DIR}/bin/linuxsteamrt64:${LD_LIBRARY_PATH}"

# Build the argument list; only include the map if one was provided.
set -- +game "${SERVER_GAME_ARG}"
if [ -n "${SERVER_MAP_ARG}" ]; then
    set -- "$@" "${SERVER_MAP_ARG}"
fi
set -- "$@" +hostname "${SERVER_HOSTNAME_ARG}" +motd "${SERVER_MOTD_ARG}"

# SERVER_ADDITIONAL_ARGS is intentionally unquoted so multiple args split.
# shellcheck disable=SC2086
exec dotnet "${SBOX_DIR}/sbox-server.dll" "$@" ${SERVER_ADDITIONAL_ARGS}
