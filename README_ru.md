# s&box Dedicated Server — Docker (Wine/Linux)

Run an [s&box](https://sbox.game) dedicated server on Linux using Docker and Wine. The server binary is a native Windows executable distributed by Facepunch via Steam; this setup wraps it in a Wine environment so it runs on any Linux host without a Windows machine.

---

## Overview

[s&box](https://sbox.game) is a game creation platform developed by Facepunch Studios. It allows developers to build and publish entirely custom games — with their own rules, assets, and UX — using C# and a built-in scene editor. Players can hop between community-made games without ever leaving the platform. Dedicated servers are hosted per-game and are used to run persistent multiplayer sessions.

- **Engine:**
- **Scripting:** C# (.NET 10)
- **Server binary:** `sbox-server.exe` (Windows PE, Steam App ID `1892930`)
- **Default ports:** `27015` (game), `27016` (RCON/query)

---

## How It Works

| Layer | Technology |
|---|---|
| Base image | `ubuntu:noble` |
| Windows compatibility | Wine 64-bit + Wine 32-bit (i386) |
| Virtual display | Xvfb (required by Wine) |
| .NET runtime | .NET 10 via `winetricks` (bundled offline) |
| Server download | SteamCMD (anonymous login, App ID `1892930`) |
| Server launch | `wine sbox-server.exe` with env-supplied arguments |

On every container start, SteamCMD verifies and updates the server installation before Wine launches the executable. This ensures the server is always up to date.

---

## Requirements

- **Docker** ≥ 24
- **Docker Compose** ≥ 2
- A Linux host with at least **4 GB RAM** and **10 GB free disk** (for the server files)
- A Steam-published s&box game (org + gamemode identifier)

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/Lone-Pine-inc/S-OSS-WineDockerS-boxDedicatedSetup.git
cd S-OSS-WineDockerS-boxDedicatedSetup-main
```

### 2. Create your environment file

```bash
cp .env.example .env
```

Open `.env` and fill in your values:

```env
SERVER_GAME_ARG=orgname.gamemodename
SERVER_MAP_ARG=orgname.mapname
SERVER_HOSTNAME_ARG=My Dedicated Server
SERVER_MOTD_ARG=Welcome!
SERVER_ADDITIONAL_ARGS=
```

| Variable | Description | Example |
|---|---|---|
| `SERVER_GAME_ARG` | The game to run — required | `facepunch.walker` |
| `SERVER_MAP_ARG` | Starting map — optional | `garry.scenemap` |
| `SERVER_HOSTNAME_ARG` | Server name shown in the browser | `My Dedicated Server` |
| `SERVER_MOTD_ARG` | Message of the Day shown on join | `Welcome!` |
| `SERVER_ADDITIONAL_ARGS` | Any extra launch arguments | `+maxplayers 32` |

> Game and map identifiers follow s&box's package naming convention: `<org>.<package>`. You can find these on the [s&box asset library](https://asset.party).

### 3. Configure the data volume

The compose file mounts `/media/sbox-linux-server` on the host as the server's home directory. Create it (or change the path to suit your setup):

```bash
sudo mkdir -p /media/sbox-linux-server
sudo chmod 777 /media/sbox-linux-server
```

### 4. Build and run

```bash
docker compose up --build
```

Add `-d` to run in detached (background) mode:

```bash
docker compose up --build -d
```

---

## Ports

| Port | Protocol | Purpose |
|---|---|---|
| `27015` | UDP/TCP | Game traffic |
| `27016` | UDP/TCP | Query / RCON |

Open both ports in your firewall/security group if you want the server to be publicly accessible.

---

## Updating the Server

SteamCMD validates and pulls the latest server build on every container restart. To force a full rebuild of the image (e.g., after a Dockerfile change):

```bash
docker compose down
docker compose up --build
```

---

## Project Structure

```
.
├── cache/
│   └── dotnet10/                  # Offline .NET 10 installer (winetricks cache)
├── images/
│   └── latest/
│       ├── Dockerfile             # Main image definition
│       └── winetricks             # Patched winetricks with .NET 10 support
├── .env.example                   # Environment variable template
├── docker-compose.yml             # Compose service definition
└── README.md
```

---

## Troubleshooting

**The server crashes on first boot**
Steam may time out while downloading large server files. Restart the container — SteamCMD will resume the download:
```bash
docker compose restart
```

**Wine errors in the log**
Wine occasionally prints non-fatal fixme/err messages. As long as the server process stays alive and players can connect, these can be ignored.

**Port already in use**
Change the host-side port mappings in `docker-compose.yml`:
```yaml
ports:
  - "27020:27015"
  - "27021:27016"
```

---

---

## 📜 License

do with this whatever you want. who cares about MIT actually lol

---

### 💬 Connect with us. Comment and chat!

[![YouTube](https://img.shields.io/badge/YouTube-%23FF0000.svg?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@LonePine-c9n) [![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/yjMVxTf7kr)

**LonePine** develops game modes and content for s&box. Our server is open to the whole s&box community.
