# s&box Dedicated Server — Docker (нативный Linux)

Запуск выделенного сервера [s&box](https://sbox.game) на Linux с помощью Docker. Эта сборка запускает **нативную Linux-версию** сервера (`sbox-server.dll`) напрямую под средой выполнения .NET 10 — без Wine, без Xvfb, без эмуляции Windows. Файлы сервера скачиваются анонимно из Steam через SteamCMD.

---

## Обзор

[s&box](https://sbox.game) — платформа для создания игр от Facepunch Studios. Она позволяет разработчикам создавать и публиковать полностью кастомные игры — со своими правилами, ассетами и интерфейсом — на C# и со встроенным редактором сцен. Игроки могут переходить между играми сообщества, не покидая платформу. Выделенные серверы хостятся под конкретную игру и используются для постоянных мультиплеерных сессий.

- **Скриптинг:** C# (.NET 10)
- **Бинарник сервера:** `sbox-server.dll` (нативный Linux, Steam App ID `1892930`)
- **Порты по умолчанию:** `27015` (игра), `27016` (запросы/query)

> Нативные Linux-серверы **экспериментальны** и официально не поддерживаются Facepunch — они могут сломаться при любом обновлении игры.

---

## Как это работает

| Слой | Технология |
|---|---|
| Базовый образ | `ubuntu:noble` |
| Среда выполнения | .NET 10 Runtime (через `dotnet-install.sh`) |
| Нативные библиотеки | `libgdiplus`, `lib32gcc-s1`, `lib32stdc++6`, `libicu74` |
| Скачивание сервера | SteamCMD (анонимный вход, App ID `1892930`, **Linux**-сборка) |
| Запуск сервера | `dotnet sbox-server.dll` с аргументами из переменных окружения |
| Init / сигналы | `tini` (корректная обработка SIGINT/SIGTERM) |

При каждом старте контейнера SteamCMD проверяет и обновляет установку сервера (если `SBOX_AUTO_UPDATE=0` — пропускает), затем `dotnet` запускает `sbox-server.dll`. Библиотеки сервера из `bin/linuxsteamrt64` автоматически добавляются в `LD_LIBRARY_PATH`.

> В отличие от прежней сборки на Wine, платформа в SteamCMD больше **не** форсируется на Windows (`+@sSteamCmdForcePlatformType windows` убран), поэтому скачивается нативная Linux-сборка.

---

## Требования

- **Docker** ≥ 24
- **Docker Compose** ≥ 2
- Linux-хост (x86-64) минимум с **4 ГБ RAM** и **10 ГБ свободного диска** (под файлы сервера)
- Опубликованная в Steam игра s&box (идентификатор org + gamemode)

---

## Быстрый старт

### 1. Клонируйте репозиторий

```bash
git clone https://github.com/Lone-Pine-inc/S-OSS-WineDockerS-boxDedicatedSetup.git
cd S-OSS-WineDockerS-boxDedicatedSetup-main
```

### 2. Создайте файл окружения

```bash
cp .env.example .env
```

Откройте `.env` и заполните свои значения:

```env
SERVER_GAME_ARG=facepunch.sandbox
SERVER_MAP_ARG=
SERVER_HOSTNAME_ARG=My Dedicated Server
SERVER_MOTD_ARG=Welcome!
SERVER_ADDITIONAL_ARGS=
```

| Переменная | Описание | Пример |
|---|---|---|
| `SERVER_GAME_ARG` | Игра для запуска — обязательно | `facepunch.sandbox` |
| `SERVER_MAP_ARG` | Стартовая карта — опционально | `garry.scenemap` |
| `SERVER_HOSTNAME_ARG` | Имя сервера в браузере серверов | `My Dedicated Server` |
| `SERVER_MOTD_ARG` | Сообщение дня при входе | `Welcome!` |
| `SERVER_ADDITIONAL_ARGS` | Любые дополнительные аргументы запуска | `+maxplayers 32` |

> Идентификаторы игры и карты следуют схеме имён пакетов s&box: `<org>.<package>`. Найти их можно в [библиотеке ассетов s&box](https://asset.party).

### 3. Настройте том с данными

Compose монтирует `/media/sbox-linux-server` на хосте как домашний каталог сервера. Создайте его (или измените путь под себя):

```bash
sudo mkdir -p /media/sbox-linux-server
sudo chmod 777 /media/sbox-linux-server
```

### 4. Сборка и запуск

```bash
docker compose up --build
```

Добавьте `-d` для запуска в фоновом (detached) режиме:

```bash
docker compose up --build -d
```

---

## Порты

| Порт | Протокол | Назначение |
|---|---|---|
| `27015` | UDP/TCP | Игровой трафик |
| `27016` | UDP/TCP | Query / запросы |

Откройте оба порта в брандмауэре/группе безопасности, если хотите сделать сервер публично доступным.

---

## Обновление сервера

SteamCMD проверяет и подтягивает последнюю сборку сервера при каждом перезапуске контейнера (управляется `SBOX_AUTO_UPDATE`, по умолчанию `1`). Чтобы принудительно пересобрать образ (например, после изменения Dockerfile):

```bash
docker compose down
docker compose up --build
```

---

## Структура проекта

```
.
├── images/
│   └── latest/
│       ├── Dockerfile             # Нативный Linux-образ (.NET 10 + SteamCMD)
│       └── entrypoint.sh          # Скрипт обновления и запуска (dotnet sbox-server.dll)
├── .env.example                   # Шаблон переменных окружения
├── docker-compose.yml             # Описание сервиса Compose
└── README.md
```

---

## Решение проблем

**Сервер словно «завис» при первом запуске**
Это нормально — идёт скачивание ассетов. Первый старт может занять время; следите за сетевой активностью, чтобы убедиться в прогрессе.

**Сервер падает при первом запуске**
Steam может отвалиться по таймауту при скачивании больших файлов. Перезапустите контейнер — SteamCMD продолжит загрузку:
```bash
docker compose restart
```

**`ArgumentOutOfRangeException` / ошибки ширины консоли**
Entrypoint задаёт размер TTY, а в compose включён `tty: true`, чтобы этого избежать. Если запускаете образ вручную — добавляйте `-it`.

**Порт уже занят**
Измените маппинг портов на стороне хоста в `docker-compose.yml`:
```yaml
ports:
  - "27020:27015/udp"
  - "27020:27015/tcp"
  - "27021:27016/udp"
  - "27021:27016/tcp"
```

---

## 📜 Лицензия

делайте с этим что хотите. кому вообще нужен MIT, lol

---

### 💬 Свяжитесь с нами. Комментируйте и общайтесь!

[![YouTube](https://img.shields.io/badge/YouTube-%23FF0000.svg?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/@LonePine-c9n) [![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/yjMVxTf7kr)

**LonePine** разрабатывает игровые режимы и контент для s&box. Наш сервер открыт для всего сообщества s&box.
