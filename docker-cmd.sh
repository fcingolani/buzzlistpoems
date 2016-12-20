#!/bin/sh

env > /etc/environment

touch /var/log/cron.log

cat << EOF > /etc/cron.d/crontab
@reboot root /bin/bash -c '/usr/local/bin/ruby /usr/src/app/scrap.rb >> /var/log/cron.log 2>&1'
$CRON_SCRAP_SCHEDULE root /bin/bash -c '/usr/local/bin/ruby /usr/src/app/scrap.rb >> /var/log/cron.log 2>&1'
$CRON_TWEET_SCHEDULE root /bin/bash -c '/usr/local/bin/ruby /usr/src/app/tweet.rb >> /var/log/cron.log 2>&1'
# :)
EOF

chmod 0644 /etc/cron.d/crontab

cron

tail -q -F /var/log/cron.log
