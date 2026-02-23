FROM ubuntu:noble

LABEL maintainer="tsktp"

ARG SERVER_GAME_ARG="facepunch.walker"
ARG SERVER_MAP_ARG="garry.scenemap"
ARG SERVER_HOSTNAME_ARG="My Dedicated Server"
ARG SERVER_MOTD_ARG="Hello World!"

ENV SERVER_GAME_ARG=${SERVER_GAME_ARG}
ENV SERVER_MAP_ARG=${SERVER_MAP_ARG}
ENV SERVER_HOSTNAME_ARG=${SERVER_HOSTNAME_ARG}
ENV SERVER_MOTD_ARG=${SERVER_MOTD_ARG}
ENV WINEPREFIX=/wine/prefix
ENV WINEARCH=win64
ENV DISPLAY=:0
ENV STABLE=1

RUN dpkg --add-architecture i386

RUN sed -i 's|http://archive.ubuntu.com/ubuntu|http://mirror.yandex.ru/ubuntu|g; \
    s|http://security.ubuntu.com/ubuntu|http://mirror.yandex.ru/ubuntu|g' \
    /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update -qq && \
	echo steam steam/question select "I AGREE" | debconf-set-selections && \
	echo steam steam/license note '' | debconf-set-selections && \
	apt-get install -qq wine32:i386 wine64 xvfb lib32gcc-s1 curl wget winbind steamcmd && \
	apt-get clean -qq all

# Use bundled winetricks (newer version with dotnet10 support)
COPY images/latest/winetricks /usr/bin/winetricks
RUN chmod +x /usr/bin/winetricks

# Pre-populate winetricks cache with dotnet10 installer (root's cache)
RUN mkdir -p /root/.cache/winetricks/dotnet10 /wine/prefix /home/sboxserver/sbox
COPY cache/dotnet10/ /root/.cache/winetricks/dotnet10/

RUN DISPLAY=:0 xvfb-run -a -s "-screen 0 1024x768x24" winetricks -q dotnet10

RUN /usr/games/steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /home/sboxserver/sbox +login anonymous +app_update 1892930 validate +quit

RUN echo '#!/bin/sh' > /usr/local/bin/start_server.sh && \
	echo '/usr/games/steamcmd +@sSteamCmdForcePlatformType windows +force_install_dir /home/sboxserver/sbox +login anonymous +app_update 1892930 validate +quit' >> /usr/local/bin/start_server.sh && \
	echo 'wine /home/sboxserver/sbox/sbox-server.exe +game "${SERVER_GAME_ARG}" ${SERVER_MAP_ARG:+"${SERVER_MAP_ARG}"} +hostname "${SERVER_HOSTNAME_ARG}" +motd "${SERVER_MOTD_ARG}" ${SERVER_ADDITIONAL_ARGS}' >> /usr/local/bin/start_server.sh && \
	chmod +x /usr/local/bin/start_server.sh

ENTRYPOINT ["/usr/local/bin/start_server.sh"]

EXPOSE 27015
EXPOSE 27016

VOLUME /home/sboxserver
