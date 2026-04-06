#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${DORKCOIN_DATA_DIR:-/home/dorkcoin/.dorkcoin}"
CONF_FILE="${DORKCOIN_CONF:-$DATA_DIR/dorkcoin.conf}"

RPC_USER="${DORKCOIN_RPC_USER:-dorkcoinrpc}"
RPC_PASSWORD="${DORKCOIN_RPC_PASSWORD:-changeme}"
P2P_PORT="${DORKCOIN_P2P_PORT:-25516}"
RPC_PORT="${DORKCOIN_RPC_PORT:-25515}"
RPC_BIND="${DORKCOIN_RPC_BIND:-0.0.0.0}"
RPC_ALLOW_IP="${DORKCOIN_RPC_ALLOW_IP:-172.16.0.0/12}"
TXINDEX="${DORKCOIN_TXINDEX:-1}"
PRUNE="${DORKCOIN_PRUNE:-0}"
MAXCONNECTIONS="${DORKCOIN_MAXCONNECTIONS:-64}"
EXTRA_ARGS="${DORKCOIN_EXTRA_ARGS:-}"

DEFAULT_BOOTSTRAP_NODES=(
  "170.75.161.131:25516"
)

BOOTSTRAP_NODES=()
if [[ -n "${DORKCOIN_BOOTSTRAP_NODES:-}" ]]; then
  IFS=',' read -r -a BOOTSTRAP_NODES <<< "${DORKCOIN_BOOTSTRAP_NODES}"
else
  BOOTSTRAP_NODES=("${DEFAULT_BOOTSTRAP_NODES[@]}")
fi

mkdir -p "${DATA_DIR}"
chown -R dorkcoin:dorkcoin /home/dorkcoin

if [[ ! -f "${CONF_FILE}" ]]; then
  cat > "${CONF_FILE}" <<EOF
server=1
daemon=0
listen=1
printtoconsole=1
upnp=0

rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcbind=${RPC_BIND}
rpcallowip=${RPC_ALLOW_IP}
rpcport=${RPC_PORT}

port=${P2P_PORT}
txindex=${TXINDEX}
prune=${PRUNE}
maxconnections=${MAXCONNECTIONS}
wallet=wallet.dat
EOF
fi

for node in "${BOOTSTRAP_NODES[@]}"; do
  node="${node//[[:space:]]/}"
  [[ -z "${node}" ]] && continue
  line="addnode=${node}"
  if ! grep -Fxq "${line}" "${CONF_FILE}"; then
    echo "${line}" >> "${CONF_FILE}"
  fi
done

chown dorkcoin:dorkcoin "${CONF_FILE}"

chmod 600 "${CONF_FILE}"

extra_args=()
if [[ -n "${EXTRA_ARGS}" ]]; then
  read -r -a extra_args <<< "${EXTRA_ARGS}"
fi

if [[ "${1:-}" == "dorkcoind" ]]; then
  exec gosu dorkcoin dorkcoind \
    -datadir="${DATA_DIR}" \
    -conf="${CONF_FILE}" \
    "${extra_args[@]}"
fi

exec "$@"