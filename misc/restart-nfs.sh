#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -a SERVICES=("nfs-server" "nfs-client.target" "rpc_pipefs.target" "remote-fs.target" "rpcbind.socket"		\
		     "rpc-svcgssd.service" "rpc-gssd.service" "rpc-statd-notify.service" "rpc-statd.service"		\
		     "rpcbind.service" "nfs-idmapd.service" "nfs-mountd.service" "autofs.service" "sssd.service"	);

unset APPEND
unset EXTRA_SERVICESS
unset EXTRA_OPTS

declare -a EXCLUDE=();
declare -a ENABLED_SERVICES=();
declare -a EXTRA_OPTS=();
declare -a EXTRA_SERVICES=();
declare -a APPEND_OPTS=()

declare -i EXCLUDE_INDEX=-1
declare -i ENABLED_SERVICES_INDEX=-1
declare -i EXTRA_OPTS_INDEX=-1
declare -i EXTRA_SERVICES_INDEX=-1
declare -i APPEND_OPTS_INDEX=-1
declare -i CMD_LINE_INDEX=-1

declare -x SCRIPT="/usr/local/sbin/restart"
INIT_COLOR_SHORTHAND

for OPTIONS in $@; do
    case $OPTIONS in
        --without-* | --exclude-* | --disable-*)
          ((EXCLUDE_INDEX++))
	  ((CMD_LINE_INDEX++))
          TEMP_EXCLUDE=${OPTIONS##*--without-}
	  TEMP_EXCLUDE=${TEMP_EXCLUDE##*--exclude-}
	  TEMP_EXCLUDE=${TEMP_EXCLUDE##*--disable-}
	  EXCLUDE[$((EXCLUDE_INDEX))]=$TEMP_EXCLUDE
	  if [ $CMD_LINE_INDEX -eq 0 ]; then
              printf "\n*-------------------------------------------------------------------------------------------------*\n"
          fi
	  INFO_MESSAGE "Excluding: ${EXCLUDE[$((EXCLUDE_INDEX))]}"
          ;;
        *)
	  ((APPEND_OPTS_INDEX++))
	  ((CMD_LINE_INDEX++))
          APPEND_OPTS[$((APPEND_OPTS_INDEX))]="$OPTIONS"
          if [ $CMD_LINE_INDEX -eq 0 ]; then
              printf "\n*-------------------------------------------------------------------------------------------------*\n"
          fi
	  INFO_MESSAGE "Appending options: ${APPEND_OPTS[$((APPEND_OPTS_INDEX))]}"
          ;;
    esac
done

for OPTIONS in ${APPEND_OPTS[@]}; do
    case $OPTIONS in
        --*)
          ((EXTRA_OPTS_INDEX++))
          EXTRA_OPTS[$((EXTRA_OPTS_INDEX))]="$OPTIONS"
          ;;
        *)
          ((EXTRA_SERVICES_INDEX++))
          EXTRA_SERVICES[$((EXTRA_SERVICES_INDEX))]="$OPTIONS"
          ;;
    esac
done

for SERVICE_DATA in ${SERVICES[@]} ${EXTRA_SERVICES[@]}; do
    declare -i BOL_ENABLE=$TRUE
    for EXCLUDE_DATA in ${EXCLUDE[@]}; do
        if [ "$SERVICE_DATA" == "$EXCLUDE_DATA" ] || [ "$SERVICE_DATA" == "$EXCLUDE_DATA.service" ]; then
            declare -i BOL_ENABLE=$FALSE
        fi
    done
    if [ $BOL_ENABLE -eq $TRUE ]; then
        ((ENABLED_SERVICES_INDEX++))
        ENABLED_SERVICES[$((ENABLED_SERVICES_INDEX))]=$SERVICE_DATA
    fi
done

printf "\n*-------------------------------------------------------------------------------------------------*\n"
for INFO in ${ENABLED_SERVICES[@]}; do INFO_MESSAGE "Service List:  $INFO"; done
for INFO in ${EXTRA_OPTS[@]}; do INFO_MESSAGE "Extra Options: $INFO"; done
printf "\n*-------------------------------------------------------------------------------------------------*\n\n"

$SCRIPT ${ENABLED_SERVICES[@]} ${EXTRA_OPTS[@]}
exit $?

