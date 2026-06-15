# s&box Dedicated Server — Docker (Native Linux)

Run an [s&box](https://sbox.game) dedicated server on Linux using Docker. This setup runs the **native Linux** server build (`sbox-server.dll`) directly under the .NET 10 runtime — no Wine, no Xvfb, no Windows emulation. The server files are pulled anonymously from Steam with SteamCMD.

[На русском можно прочитать здесь](https://github.com/Lone-Pine-inc/S-OSS-WineDockerS-boxDedicatedSetup/blob/main/README_ru.md)

---

## Overview

[s&box](https://sbox.game) is a game creation platform developed by Facepunch Studios. It allows developers to build and publish entirely custom games — with their own rules, assets, and UX — using C# and a built-in scene editor. Players can hop between community-made games without ever leaving the platform. Dedicated servers are hosted per-game and are used to run persistent multiplayer sessions.

- **Scripting:** C# (.NET 10)
- **Server binary:** `sbox-server.dll` (native Linux, Steam App ID `1892930`)
- **Default ports:** `27015` (game), `27016` (query)

> Native Linux dedicated servers are **experimental** and not officially supported by Facepunch — they may break with any game update.

---

## How It Works

| Layer | Technology |
|---|---|
| Base image | `ubuntu:noble` |
| Runtime | .NET 10 Runtime (installed via `dotnet-install.sh`) |
| Native libs | `libgdiplus`, `lib32gcc-s1`, `lib32stdc++6`, `libicu74` |
| Server download | SteamCMD (anonymous login, App ID `1892930`, **Linux** build) |
| Server launch | `dotnet sbox-server.dll` with env-supplied arguments |
| Init / signals | `tini` (clean SIGINT/SIGTERM handling) |

On every container start, SteamCMD verifies and updates the server installation (unless `SBOX_AUTO_UPDATE=0`), then `dotnet` launches `sbox-server.dll`. The server's bundled libraries in `bin/linuxsteamrt64` are added to `LD_LIBRARY_PATH` automatically.

> Unlike the previous Wine-based setup, the server is **not** forced to the Windows platform in SteamCMD (`+@sSteamCmdForcePlatformType windows` is gone), so the native Linux build is downloaded.

---

## Requirements

- **Docker** ≥ 24
- **Docker Compose** ≥ 2
- A Linux host (x86-64) with at least **4 GB RAM** and **10 GB free disk** (for the server files)
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
SERVER_GAME_ARG=facepunch.sandbox
SERVER_MAP_ARG=
SERVER_HOSTNAME_ARG=My Dedicated Server
SERVER_MOTD_ARG=Welcome!
SERVER_ADDITIONAL_ARGS=
```

| Variable | Description | Example |
|---|---|---|
| `SERVER_GAME_ARG` | The game to run — required | `facepunch.sandbox` |
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
| `27016` | UDP/TCP | Query |

Open both ports in your firewall/security group if you want the server to be publicly accessible.

---

## Updating the Server

SteamCMD validates and pulls the latest server build on every container restart (controlled by `SBOX_AUTO_UPDATE`, default `1`). To force a full rebuild of the image (e.g., after a Dockerfile change):

```bash
docker compose down
docker compose up --build
```

---

## Project Structure

```
.
├── images/
│   └── latest/
│       ├── Dockerfile             # Native Linux image (.NET 10 + SteamCMD)
│       └── entrypoint.sh          # Update + launch script (dotnet sbox-server.dll)
├── .env.example                   # Environment variable template
├── docker-compose.yml             # Compose service definition
└── README.md
```

---

## Troubleshooting

**The server appears stuck on first boot**
Normal — assets are being downloaded. The initial startup can take a while; watch network activity to confirm progress.

**The server crashes on first boot**
Steam may time out while downloading large server files. Restart the container — SteamCMD will resume the download:
```bash
docker compose restart
```

**`ArgumentOutOfRangeException` / console width errors**
The entrypoint sets a TTY size and the compose file enables `tty: true` to avoid this. If you run the image manually, pass `-it`.

**Port already in use**
Change the host-side port mappings in `docker-compose.yml`:
```yaml
ports:
  - "27020:27015/udp"
  - "27020:27015/tcp"
  - "27021:27016/udp"
  - "27021:27016/tcp"
```

---

## 📜 License

do with this whatever you want. who cares about MIT actually lol

---

### 💬 Connect with us. Comment and chat!

[![YouTube](https://img.shields.io/badge/YouTube-%23FF0000.svg?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@LonePine-c9n) [![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/yjMVxTf7kr)

**LonePine** develops game modes and content for s&box. Our server is open to the whole s&box community.
