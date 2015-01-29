#! /bin/bash

#service start exim4
service start postgresql
service start lighttpd

/opt/lf/bin/lf_updated &

su - www-data
echo "Event:send_notifications_loop()" | /opt/lf/webmcp/bin/webmcp_shell lfconfig
OA
