#
# Dockerfile for liquid-feedback
#

FROM debian:jessie

MAINTAINER Pedro Ângelo <pangelo@void.io>

ENV LF_CORE_VERSION 3.0.4
ENV LF_FEND_VERSION 3.0.4
ENV LF_WMCP_VERSION 1.2.6

#
# install dependencies
#

RUN apt-get update && apt-get -y install \
        build-essential \
        exim4 \
        imagemagick \
        liblua5.1-0-dev \
        libpq-dev \
        lighttpd \
        lua5.1 \
        mercurial \
        postgresql \
        postgresql-server-dev-9.4 \
        python-pip \
    && pip install markdown2
    
#
# prepare file tree
#


RUN mkdir -p /opt/lf/sources/patches \
             /opt/lf/sources/scripts \
             /opt/lf/bin

WORKDIR /opt/lf/sources

RUN hg clone -r v${LF_CORE_VERSION} http://www.public-software-group.org/mercurial/liquid_feedback_core/ ./core \
    && hg clone -r v${LF_FEND_VERSION} http://www.public-software-group.org/mercurial/liquid_feedback_frontend/ ./frontend \
    && hg clone -r v${LF_WMCP_VERSION} http://www.public-software-group.org/mercurial/webmcp ./webmcp

#
# build core
#

WORKDIR /opt/lf/sources/core

RUN make \
    && cp lf_update lf_update_issue_order lf_update_suggestion_order /opt/lf/bin

#
# build WebMCP
#

COPY ./patches/webmcp_build.patch /opt/lf/sources/patches/

WORKDIR /opt/lf/sources/webmcp

RUN patch -p1 -i /opt/lf/sources/patches/webmcp_build.patch \
    && make \
    && mkdir /opt/lf/webmcp \
    && cp -RL framework/* /opt/lf/webmcp

#
# build frontend
#

WORKDIR /opt/lf/

RUN cd /opt/lf/sources/frontend \
    && hg archive -t files /opt/lf/frontend \
    && cd /opt/lf/frontend/fastpath \
    && make \
    && chown www-data /opt/lf/frontend/tmp

#
# setup db
#

COPY ./scripts/setup_db.sql /opt/lf/sources/scripts/
COPY ./scripts/config_db.sql /opt/lf/sources/scripts/

RUN addgroup --system lf \
    && adduser --system --ingroup lf --no-create-home --disabled-password lf \
    && service postgresql start \
    && (su -l postgres -c "psql -f /opt/lf/sources/scripts/setup_db.sql") \
    && (su -l postgres -c "psql -f /opt/lf/sources/core/core.sql liquid_feedback") \
    && (su -l postgres -c "psql -f /opt/lf/sources/scripts/config_db.sql liquid_feedback") \
    && service postgresql stop

#
# cleanup
#

RUN rm -rf /opt/lf/sources \
    && apt-get -y purge \
        build-essential \
        liblua5.1-0-dev \
        libpq-dev \
        mercurial \
        postgresql-server-dev-9.4 \
        python-pip \
    && apt-get -y autoremove \
    && apt-get clean

#
# configure everything
#

# TODO: configure mail system

# webserver config
COPY ./scripts/60-liquidfeedback.conf /etc/lighttpd/conf-available/

RUN ln -s /etc/lighttpd/conf-available/60-liquidfeedback.conf /etc/lighttpd/conf-enabled/60-lighttpd.conf

# app config
COPY ./scripts/lfconfig.lua /opt/lf/frontend/config/

# update script
COPY ./scripts/lf_updated /opt/lf/bin/

# startup script
COPY ./scripts/start.sh /opt/lf/bin/

#
# ready to go
#

EXPOSE 80

WORKDIR /opt/lf/frontend

ENTRYPOINT ["/opt/lf/bin/start.sh"]

