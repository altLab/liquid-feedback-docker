#! /bin/bash

set -e

if [ -z $1 ] ; then
        #service exim4 start
        service postgresql start
        service lighttpd start

        /opt/lf/bin/lf_updated &

        su -s /bin/sh -l www-data 
        echo "Event:send_notifications_loop()" | /opt/lf/webmcp/bin/webmcp_shell lfconfig

        while true; do sleep 60; done

else
        exec "$@"
fi

