# Dorkcoin Docker Build Notes

This stack builds and runs Dorkcoin Core from the upstream Dorkcoin repository:

https://github.com/dorkcoinorg/dorkcoin

## What this build does

- Uses Debian 13 `trixie-slim`, pinned by image digest.
- Uses a Debian snapshot date so `apt` inputs stay immutable.
- Pins the upstream Dorkcoin source to tag `v13.2` and commit `a452ce5c9a4f0ba8eb699ede2b97d2b56f403d2d`.
- Pins Berkeley DB `6.2.32.NC` by checksum so wallet support stays enabled on modern Debian.
- Builds `dorkcoind`, `dorkcoin-cli`, and `dorkcoin-tx`.
- Disables UPnP at build time and also writes `upnp=0` into the generated config.
- Skips tests and benchmarks.

## Files in this stack

- `Dockerfile`: multi-stage reproducible build.
- `docker-compose.yml`: compose service and runtime wiring.
- `docker-entrypoint.sh`: config generation and daemon startup.
- `.env`: runtime settings.

## Build

Preferred build command:

```bash
docker compose --progress=plain build --build-arg MAKE_JOBS=$(nproc)
```

That keeps parallel builds enabled unless you later discover a real compatibility reason to force `MAKE_JOBS=1`.

To rebuild from scratch:

```bash
docker compose --progress=plain build --no-cache --build-arg MAKE_JOBS=$(nproc)
```

## Start

```bash
docker compose up -d
```

Logs:

```bash
docker compose logs -f dorkcoin
```

Stop:

```bash
docker compose down
```

## Runtime defaults

- Service name: `dorkcoin`
- Container name: `dorkcoind`
- Container user: `dorkcoin`
- Datadir: `/home/dorkcoin/.dorkcoin`
- Config file: `/home/dorkcoin/.dorkcoin/dorkcoin.conf`
- Host bind mount: `./dot-dorkcoin`

Mainnet ports:

- P2P: `25516`
- RPC: `25515`

RPC stays internal by default. If host RPC access is needed later, uncomment the RPC port mapping in `docker-compose.yml`.

## Environment

Set a strong RPC password in `.env` before first start.

Important variables:

- `DORKCOIN_RPC_USER`
- `DORKCOIN_RPC_PASSWORD`
- `DORKCOIN_P2P_PORT`
- `DORKCOIN_RPC_PORT`
- `DORKCOIN_RPC_BIND`
- `DORKCOIN_RPC_ALLOW_IP`
- `DORKCOIN_TXINDEX`
- `DORKCOIN_PRUNE`
- `DORKCOIN_MAXCONNECTIONS`
- `DORKCOIN_BOOTSTRAP_NODES`
- `DORKCOIN_EXTRA_ARGS`

The entrypoint writes a config automatically on first boot if one does not already exist.

## CLI usage

Get blockchain info:

```bash
docker compose exec -u dorkcoin dorkcoin dorkcoin-cli \
  -datadir=/home/dorkcoin/.dorkcoin \
  -conf=/home/dorkcoin/.dorkcoin/dorkcoin.conf \
  getblockchaininfo
```

Check wallet balance:

```bash
docker compose exec -u dorkcoin dorkcoin dorkcoin-cli \
  -datadir=/home/dorkcoin/.dorkcoin \
  -conf=/home/dorkcoin/.dorkcoin/dorkcoin.conf \
  getbalance
```

Generate a new address:

```bash
docker compose exec -u dorkcoin dorkcoin dorkcoin-cli \
  -datadir=/home/dorkcoin/.dorkcoin \
  -conf=/home/dorkcoin/.dorkcoin/dorkcoin.conf \
  getnewaddress
```

List commands:

```bash
docker compose exec -u dorkcoin dorkcoin dorkcoin-cli help
```

## Notes worth remembering

- Wallet support is enabled in the build.
- Tests are intentionally not compiled.
- UPnP is disabled both in `configure` and in the generated runtime config.
- The compose file seeds one bootstrap peer by default: `170.75.161.131:25516`.
- If you already have an existing config under `./dot-dorkcoin`, the entrypoint will not overwrite it.