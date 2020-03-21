#! /bin/bash
set -e

if [ -z $1 ] ; then
        #service exim4 start
        service postgresql start

        /opt/lf/bin/lf_updated &

        su -s /bin/bash www-data -c "
/opt/lf/moonbridge/moonbridge \
    /opt/lf/webmcp/bin/mcp.lua \
    /opt/lf/webmcp/ \
    /opt/lf/frontend/ \
    main lfconfig
"

else
        exec "$@"
fi

