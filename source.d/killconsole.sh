function killconsole()
{
  RV=1
  unset DATA
  while IFS= read LINE; do
       if [ ${#1} -eq 0 ]; then
	    RV=1
            break 2
       fi
       WC=-1
       for WORD in $LINE; do
          ((WC++))
	  if [ $WC -eq 1 ]; then
		DATA="$WORD $DATA"
	  fi
       done
  done < <(ps -auxfh | grep -v grep | grep console -B5 2>/dev/null | grep $1 -B3 2>/dev/null)
  for KILLPID in $DATA; do
	if [ ${#1} -eq 0 ] || [ ${#KILLPID} -eq 0 ]; then
		RV=1
        	break 2
	fi;
	printf "Kill: %-10s: " $KILLPID
	kill -SIGKILL $KILLPID
	if [ $? -eq 0 ]; then
		printf "Success\n"
		RV=0
	else
		printf "Failure\n"
		RV=1
	fi
  done
  return $RV
};

