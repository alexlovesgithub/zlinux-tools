#!/bin/bash

. ./run_variables

#DIR_REMOTE_TMP=/tmp/m2/${RUN_NAME}/${NEW_NUM_RUN}

#################################################

check_lock () {
	ls $LAST_RUN/.lock > /dev/null 2>&1
}

test_ping () {
        ping -c1 -q -w1 $1 > /dev/null
	#if [ ! $? -eq 0 ]; then
	#	echo ''
	#	echo '#####################'
	#	echo '# !! PING FAILED !! #'
	#	echo '#####################'

}

check_nmon () {
		echo ""
		echo "##########################################"
		echo "> STARTING RUN ${RUN_NAME}_${NEW_NUM_RUN} "
		echo "##########################################"
		echo ""
	
	for HOSTNAME in `awk '$1 !~/^$/ && $1 !~/^#/ { print $1 }' $MACHINES_FILES `; do
        	echo ''
        	echo "----------[ $HOSTNAME ]----------"
        	echo "# $NMON_CMD"
        	echo ''

        	test_ping $HOSTNAME
        	if [ ! $? -eq 0 ]; then
                	echo ''
                	echo '#####################'
                	echo "# !! PING FAILED !! #"
                	echo '#####################'
        	else
                	#ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no root@${HOSTNAME} "
			$REMOTE_COMMANDE ${HOSTNAME} "ps -eaf | grep \"$NMON_CMD\" | grep -v grep "
			
        	fi
        	echo ''
        	echo ''
	done
}

#################################################

check_nmon

touch ${DIR_RESULTS}/${RUN_NAME}_$NEW_NUM_RUN/.lock
