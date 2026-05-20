#!/bin/bash
# Version 0.1
# For Debian/Ubuntu Distros
# Change The '--dont-skip-package' to '--skip-packages' for Non-Debian Based Distros

/usr/local/scripts/backup/backup-sys-cfg.sh --create-cron --create-link --dont-skip-copy --dont-skip-package --show-random
