#Base image
FROM debian:bookworm-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL="C.UTF-8" LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8"
ENV HTTP_PORT=9000

# Install packages
RUN apt-get update -qq  && \
	apt-get install --no-install-recommends -qy wget curl perl tzdata libcrypt-blowfish-perl libwww-perl libfont-freetype-perl liblinux-inotify2-perl \
	libdata-dump-perl libio-socket-ssl-perl libnet-ssleay-perl libcrypt-ssleay-perl libcrypt-openssl-rsa-perl libgomp1 libasound2 lame && \
	apt-get clean -qy && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add & configure user
RUN useradd -M -d /nonexistent -s /usr/sbin/nologin -G audio squeezeboxserver

# Add startup script
COPY start-container.sh /usr/bin/start-container
RUN chmod +x /usr/bin/start-container

# Volume and port setup
RUN mkdir -p /config /music /playlist /lms

COPY . /lms
COPY Slim-Utils-OS-Custom.pm /lms/Slim/Utils/OS/Custom.pm
RUN chown -R squeezeboxserver:nogroup /config /playlist && chmod -R a+rX /lms

# create symlinks to some crypto libraries, or the bridge plugins will fail
RUN if [ -f /usr/lib/aarch64-linux-gnu/libssl.so.3 ];      then ln -s /usr/lib/aarch64-linux-gnu/libssl.so.3 /usr/lib/aarch64-linux-gnu/libssl.so; fi
RUN if [ -f /usr/lib/aarch64-linux-gnu/libcrypto.so.3 ];   then ln -s /usr/lib/aarch64-linux-gnu/libcrypto.so.3 /usr/lib/aarch64-linux-gnu/libcrypto.so; fi
RUN if [ -f /usr/lib/x86_64-linux-gnu/libssl.so.3 ];       then ln -s  /usr/lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/x86_64-linux-gnu/libssl.so; fi
RUN if [ -f /usr/lib/x86_64-linux-gnu/libcrypto.so.3 ];    then ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so.3 /usr/lib/x86_64-linux-gnu/libcrypto.so; fi
RUN if [ -f /usr/lib/arm-linux-gnueabihf/libssl.so.3 ];    then ln -s /usr/lib/arm-linux-gnueabihf/libssl.so.3 /usr/lib/arm-linux-gnueabihf/libssl.so; fi
RUN if [ -f /usr/lib/arm-linux-gnueabihf/libcrypto.so.3 ]; then ln -s /usr/lib/arm-linux-gnueabihf/libcrypto.so.3 /usr/lib/arm-linux-gnueabihf/libcrypto.so; fi

VOLUME /config /music /playlist

EXPOSE 3483 3483/udp ${HTTP_PORT} 9090

#Startup setup
WORKDIR /config

ENTRYPOINT ["start-container"]
