FROM ubuntu:noble

LABEL maintainer="tsktp"

ARG SERVER_GAME_ARG="facepunch.sandbox"
ARG SERVER_MAP_ARG=""
ARG SERVER_HOSTNAME_ARG="My Dedicated Server"
ARG SERVER_MOTD_ARG="Hello World!"

ENV SERVER_GAME_ARG=${SERVER_GAME_ARG}
ENV SERVER_MAP_ARG=${SERVER_MAP_ARG}
ENV SERVER_HOSTNAME_ARG=${SERVER_HOSTNAME_ARG}
ENV SERVER_MOTD_ARG=${SERVER_MOTD_ARG}
ENV SBOX_AUTO_UPDATE=1
ENV STEAMCMD_DIR=/opt/steamcmd
ENV SBOX_DIR=/home/sboxserver/sbox
ENV DEBIAN_FRONTEND=noninteractive

RUN dpkg --add-architecture i386

# Native Linux runtime deps for the s&box dedicated server + SteamCMD.
# No Wine, no Xvfb — the Linux server is a native .NET 10 application.
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget apt-transport-https tini \
        lib32gcc-s1 lib32stdc++6 libgdiplus libicu74 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# .NET 10 Runtime (the s&box server ships as sbox-server.dll)
RUN wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh && \
    chmod +x /tmp/dotnet-install.sh && \
    /tmp/dotnet-install.sh --runtime dotnet --channel 10.0 --install-dir /usr/share/dotnet && \
    ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet && \
    rm /tmp/dotnet-install.sh

# OpenSSL: cap at TLS 1.2 — Ubuntu 24.04's openssl.cnf has no ssl_conf section
# by default. .NET's async OpenSSL interop fails with SSL_ERROR_SSL on TLS 1.3
# post-handshake session tickets under OpenSSL 3.0.x. curl is unaffected.
RUN sed -i '/^\[openssl_init\]/a ssl_conf = ssl_sect' /etc/ssl/openssl.cnf && \
    printf '\n[ssl_sect]\nsystem_default = ssl_default_sect\n\n[ssl_default_sect]\nMinProtocol = TLSv1.2\nMaxProtocol = TLSv1.2\nCipherString = DEFAULT@SECLEVEL=1\n' >> /etc/ssl/openssl.cnf

# SteamCMD (native Linux client)
RUN mkdir -p "${STEAMCMD_DIR}" /home/sboxserver/sbox && \
    curl -sqL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
        | tar -xzvf - -C "${STEAMCMD_DIR}" && \
    chmod -R 755 "${STEAMCMD_DIR}"

# Pre-download the native Linux server into the image (anonymous, App ID 1892930).
# Note: NO +@sSteamCmdForcePlatformType windows — we want the Linux build.
RUN "${STEAMCMD_DIR}/steamcmd.sh" \
        +force_install_dir "${SBOX_DIR}" \
        +login anonymous \
        +app_update 1892930 validate \
        +quit

COPY images/latest/entrypoint.sh /usr/local/bin/start_server.sh
RUN chmod +x /usr/local/bin/start_server.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/usr/local/bin/start_server.sh"]

EXPOSE 27015
EXPOSE 27016

VOLUME /home/sboxserver
