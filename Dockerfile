ARG BASE_IMAGE=openjdk:11-slim
FROM ${BASE_IMAGE}
ARG GHIDRA_SHA256=1ce9bdf2d7f6bdfe5dccd06da828af31bc74acfd800f71ade021d5211e820d5e

#Use tini to get rid of zombies from https://github.com/krallin/tini#using-tini
ARG TINI_VERSION=v0.18.0
ARG TINI_SHA256=12d20136605531b09a2c2dac02ccee85e1b874eb322ef6baf7561cd93f93c855
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN echo "${TINI_SHA256} *tini" | sha256sum -c
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

RUN useradd -m ghidra && \
    mkdir -p /srv/repositories && \
    chown -R ghidra: /srv/repositories
COPY --chown=ghidra:ghidra launch.sh.patch /tmp/

WORKDIR /opt
RUN apt-get update && apt-get install -y unzip wget gettext-base patch fontconfig && \
    wget -q -O ghidra.zip https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_10.0.4_build/ghidra_10.0.4_PUBLIC_20210928.zip && \
    echo "${GHIDRA_SHA256} *ghidra.zip" | sha256sum -c && \
    unzip ghidra.zip && \
    rm ghidra.zip && \
    ln -s ghidra* ghidra && \
    cd ghidra && \
    patch -p0 < /tmp/launch.sh.patch && \ 
    rm -rf docs && \
    cd .. && \
    chown -R ghidra: ghidra*
USER ghidra
VOLUME /srv/repositories
WORKDIR /opt/ghidra
ENV ghidra_home=/opt/ghidra
COPY --chown=ghidra:ghidra server.sh /opt/ghidra/
EXPOSE 13100
EXPOSE 13101
EXPOSE 13102
CMD ["/opt/ghidra/server.sh"]
