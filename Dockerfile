# -*- mode: ruby -*-
# vi: set ft=ruby :

FROM aquabiota/openjdk-8-phusion-baseimage:16.04

LABEL maintainer "Aquabiota Solutions AB <mapcloud@aquabiota.se>"

ARG ORIENTDB_DOWNLOAD_SERVER

ENV ORIENTDB_VERSION 2.2.17
ENV ORIENTDB_DOWNLOAD_MD5 3be5c561fbee52ca6ba12f1637f206fc
ENV ORIENTDB_DOWNLOAD_SHA1 e43104e7dafb301a232212d2300922a086f7aedf

ENV ORIENTDB_DOWNLOAD_URL ${ORIENTDB_DOWNLOAD_SERVER:-http://central.maven.org/maven2/com/orientechnologies}/orientdb-community/$ORIENTDB_VERSION/orientdb-community-$ORIENTDB_VERSION.tar.gz
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl wget

#download distribution tar, untar and delete databases
RUN mkdir /orientdb && \
  wget  $ORIENTDB_DOWNLOAD_URL \
  && echo "$ORIENTDB_DOWNLOAD_MD5 *orientdb-community-$ORIENTDB_VERSION.tar.gz" | md5sum -c - \
  && echo "$ORIENTDB_DOWNLOAD_SHA1 *orientdb-community-$ORIENTDB_VERSION.tar.gz" | sha1sum -c - \
  && tar -xvzf orientdb-community-$ORIENTDB_VERSION.tar.gz -C /orientdb --strip-components=1 \
  && rm orientdb-community-$ORIENTDB_VERSION.tar.gz \
  && rm -rf /orientdb/databases/*

ENV PATH /orientdb/bin:$PATH

VOLUME ["/orientdb/backup", "/orientdb/databases", "/orientdb/config"]

WORKDIR /orientdb

# Adding Spatial support

ENV ORIENTDB_DOWNLOAD_SPATIAL_MD5 85455721c924fd76f5fe4b81ebd37e8b
ENV ORIENTDB_DOWNLOAD_SPATIAL_SHA1 3c2ccb4c1a368e8f8ab5ef2e417422dec3d26041

ENV ORIENTDB_DOWNLOAD_SPATIAL_URL ${ORIENTDB_DOWNLOAD_SERVER:-http://central.maven.org/maven2/com/orientechnologies}/orientdb-spatial/$ORIENTDB_VERSION/orientdb-spatial-$ORIENTDB_VERSION-dist.jar

RUN wget $ORIENTDB_DOWNLOAD_SPATIAL_URL \
    && echo "$ORIENTDB_DOWNLOAD_SPATIAL_MD5 *orientdb-spatial-$ORIENTDB_VERSION-dist.jar" | md5sum -c - \
    && echo "$ORIENTDB_DOWNLOAD_SPATIAL_SHA1 *orientdb-spatial-$ORIENTDB_VERSION-dist.jar" | sha1sum -c - \
    && mv orientdb-spatial-*-dist.jar /orientdb/lib/

#OrientDb binary
EXPOSE 2424

#OrientDb http
EXPOSE 2480

# Default command start the server
#CMD ["server.sh","-Ddistributed=true"]

# # Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Added a health check

## Adding orientdb daemon
RUN mkdir /etc/service/orientdb
ADD orientdb.sh /etc/service/orientdb/run


HEALTHCHECK CMD curl --fail http://localhost:2480/ || exit 1
