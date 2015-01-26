# Dockerfile for liquid-feedback

FROM debian:jessie

MAINTAINER Pedro Ângelo <pangelo@void.io>

# install dependencies
RUN apt-get update && apt-get install \
        build-essential \
        exim4 \
        ghc \
        imagemagick \
        libghc-parsec3-dev \
        liblua5.1-0-dev \
        libpq-dev \
        lighttpd \
        lua5.1 \
        postgresql \
        postgresql-server-dev-9.4 \
        python-pip

RUN pip install markdown2

# add source files
ADD ./core ./frontend ./webmcp ./docker /opt/lf/sources

# setup db
RUN service postgresql start
RUN su -l postgres -c "createuser liquid_feedback"
RUN su -l postgres -c "createdb -O liquid_feedback liquid_feedback"
RUN su -l postgres -c "psql -f /opt/lf/sources/docker/setup_db.sql"
RUN su -l postgres -c "psql -f /opt/lf/sources/core/core.sql liquid_feedback"
RUN su -l postgres -c "psql -f /opt/lf/sources/docker/config_db.sql liquid_feedback"
RUN service postgresql stop

# build and install core
WORKDIR /opt/lf/sources/core
RUN make
RUN mkdir /opt/lf/bin
RUN cp lf_update lf_update_issue_order lf_update_suggestion_order /opt/lf/bin

# build and install WebMCP
WORKDIR /opt/lf/sources/webmcp
RUN patch -p1 -i /opt/lf/sources/docker/webmcp_build.patch
RUN make
RUN mkdir /opt/lf/webmcp
RUN cp -RL framework/* /opt/lf/webmcp

# build and install frontend

# configure everything

# cleanup
RUN rm -rf /opt/lf/sources
RUN apt-get -y purge \
        build-essential \
        libghc-parsec3-dev \
        liblua5.1-0-dev \
        libpq-dev \
        postgresql-server-dev-9.4 \
        python-pip

CMD /opt/lf/bin/start.sh

