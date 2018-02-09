#!/usr/bin/env bash
set -euo pipefail

cron
cat /tmp/crontab | crontab -

/usr/local/bin/apache2-foreground