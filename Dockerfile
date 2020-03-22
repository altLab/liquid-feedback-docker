#
# Dockerfile for liquid-feedback
#

FROM debian:buster

MAINTAINER Pedro Ângelo <pangelo@void.io>

ENV LF_CORE_VERSION 3.2.1
ENV LF_FRONTEND_VERSION 3.2.1
ENV LF_WEBMCP_VERSION 2.1.0
ENV LF_MOONBRIDGE_VERSION 1.0.1

#
# install dependencies
#

RUN apt-get update && apt-get -y install \
        build-essential \
        exim4 \
        imagemagick \
        liblua5.2-dev \
        libpq-dev \
        lua5.2 \
        liblua5.2-0 \
        postgresql \
        postgresql-server-dev-11 \
        pmake \
        libbsd-dev \
        curl \
        discount

#
# prepare file tree
#


RUN mkdir -p /opt/lf/sources/patches \
             /opt/lf/sources/scripts \
             /opt/lf/bin

WORKDIR /opt/lf/sources

#
# Download sources
#

RUN curl https://www.public-software-group.org/pub/projects/liquid_feedback/backend/v${LF_CORE_VERSION}/liquid_feedback_core-v${LF_CORE_VERSION}.tar.gz | tar -xvzf - \
 && curl https://www.public-software-group.org/pub/projects/liquid_feedback/frontend/v${LF_FRONTEND_VERSION}/liquid_feedback_frontend-v${LF_FRONTEND_VERSION}.tar.gz | tar -xvzf - \
 && curl https://www.public-software-group.org/pub/projects/webmcp/v${LF_WEBMCP_VERSION}/webmcp-v${LF_WEBMCP_VERSION}.tar.gz | tar -xvzf - \
 && curl https://www.public-software-group.org/pub/projects/moonbridge/v${LF_MOONBRIDGE_VERSION}/moonbridge-v${LF_MOONBRIDGE_VERSION}.tar.gz | tar -xvzf -

#
# Build moonbridge
#

RUN cd /opt/lf/sources/moonbridge-v${LF_MOONBRIDGE_VERSION} \
    && pmake MOONBR_LUA_PATH=/opt/lf/moonbridge/?.lua \
    && mkdir /opt/lf/moonbridge \
    && cp moonbridge /opt/lf/moonbridge/ \
    && cp moonbridge_http.lua /opt/lf/moonbridge/

#
# build core
#

WORKDIR /opt/lf/sources/liquid_feedback_core-v${LF_CORE_VERSION}

RUN make \
    && cp lf_update lf_update_issue_order lf_update_suggestion_order /opt/lf/bin

#
# build WebMCP
#

# COPY ./patches/webmcp_build.patch /opt/lf/sources/patches/

WORKDIR /opt/lf/sources/webmcp-v${LF_WEBMCP_VERSION}

# RUN patch -p1 -i /opt/lf/sources/patches/webmcp_build.patch \
#     && make \
#     && mkdir /opt/lf/webmcp \
#     && cp -RL framework/* /opt/lf/webmcp

RUN make \
    && mkdir /opt/lf/webmcp \
    && cp -RL framework/* /opt/lf/webmcp

WORKDIR /opt/lf/

RUN cd /opt/lf/sources/liquid_feedback_frontend-v${LF_FRONTEND_VERSION} \
    && cp -R . /opt/lf/frontend \
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
    && (su -l postgres -c "PGPASSWORD=liquid psql -U liquid_feedback -h 127.0.0.1 -f /opt/lf/sources/liquid_feedback_core-v${LF_CORE_VERSION}/core.sql liquid_feedback") \
    && (su -l postgres -c "PGPASSWORD=liquid psql -U liquid_feedback -h 127.0.0.1 -f /opt/lf/sources/scripts/config_db.sql liquid_feedback") \
    && service postgresql stop

#
# cleanup
#

RUN rm -rf /opt/lf/sources \
    && apt-get -y purge \
        build-essential \
        liblua5.2-dev \
        libpq-dev \
        postgresql-server-dev-11 \
    && apt-get -y autoremove \
    && apt-get clean

#
# configure everything
#

# TODO: configure mail system

# # webserver config
# COPY ./scripts/60-liquidfeedback.conf /etc/lighttpd/conf-available/

# RUN ln -s /etc/lighttpd/conf-available/60-liquidfeedback.conf /etc/lighttpd/conf-enabled/60-lighttpd.conf

# app config
COPY ./scripts/lfconfig.lua /opt/lf/frontend/config/

# update script
COPY ./scripts/lf_updated /opt/lf/bin/

# startup script
COPY ./scripts/start.sh /opt/lf/bin/

#
# ready to go
#

EXPOSE 8080

WORKDIR /opt/lf/frontend

ENTRYPOINT ["/opt/lf/bin/start.sh"]
