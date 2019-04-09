
. ./run_variables_preprod

#################################################

#################################################
#### special function for the sys-anal tool #####
#################################################
function killPIDbyName() {
	name=$1
	hostname=$2
	$REMOTE_COMMANDE ${hostname} "ps -eaf | grep -e \"${name}\" | grep -v grep | awk '{ print \$2 }' | xargs -n1 kill"
}

function getPIDbyName() {
	PID=-1
	name=$1
	hostname=$2
	path=`which ${name}`
	PID=`$REMOTE_COMMANDE ${hostname} "pidof -s ${path}"`
	echo ${PID}
}
#################################################

function check_lock() {
 ls $DIR_LOCKFILE/.lock > /dev/null 2>&1
}

function test_ping (){
	ping -c1 -q -w1 $1 > /dev/null
	if [ ! $? -eq 0 ] ; then
		echo 
		echo "#####################"
		echo "# !! PING FAILED !! #"
		echo "#####################"
		exit 1
	fi
}

function stop_nmon() {
 echo 
	echo "####################################"
	echo " STOPPING RUN ${RUN_ID}"
	echo "####################################"
	if [ "${USE_SYSSTAT}" == "Y" ] || [ "${USE_NMON}" == "Y" ] ; then
		for HOST in `cat $MACHINES_FILES`
		do
			echo 
			echo "----------[ $HOST ]----------"
			echo 
			test_ping $HOST
			if [ "${USE_NMON}" == "Y" ] ; then
				echo "Stopping Nmon..."
				killPIDbyName "${NMON_CMD}" ${HOST}
				echo
				echo "Retrieve NMON file ..."
				#scp root@${HOST}:${DIR_REMOTE_TMP}/${NUM_RUN}/${RUN_NAME}_${NUM_RUN} ${DIR_RUN}/${RUN_ID}_${HOST}.nmon
				scp root@${HOST}:${DIR_REMOTE_TMP}/${RUN_ID} ${DIR_RUN}/${RUN_ID}_${HOST}.nmon
			fi
			if [ "${USE_SYSSTAT}" == "Y" ] ; then
				killPIDbyName "iostat" ${HOST}
				echo "Retrieve IOstat file ..."
				#scp root@${HOST}:${DIR_REMOTE_TMP}/${NUM_RUN}/${RUN_NAME}_${NUM_RUN}.iostat ${DIR_RUN}/${RUN_ID}_${HOST}.iostat
				scp root@${HOST}:${DIR_REMOTE_TMP}/${RUN_ID}.iostat ${DIR_RUN}/${RUN_ID}_${HOST}.iostat
				killPIDbyName "vmstat" ${HOST}
				echo "Retrieve VMstat file ..."
				#scp root@${HOST}:${DIR_REMOTE_TMP}/${NUM_RUN}/${RUN_NAME}_${NUM_RUN}.vmstat ${DIR_RUN}/${RUN_ID}_${HOST}.vmstat
				scp root@${HOST}:${DIR_REMOTE_TMP}/${RUN_ID}.vmstat ${DIR_RUN}/${RUN_ID}_${HOST}.vmstat
				if $REMOTE_COMMANDE ${HOST} "[ -f ${DIR_REMOTE_TMP}/${NUM_RUN}/${RUN_NAME}_${NUM_RUN}.PID ]" ; then
					killPIDbyName "pidstat" ${HOST}
					echo "Retrieve PIDstat file ..."
					#scp root@${HOST}:${DIR_REMOTE_TMP}/${NUM_RUN}/${RUN_NAME}_${NUM_RUN}.pidstat ${DIR_RUN}/${RUN_ID}_${HOST}.pidstat
					scp root@${HOST}:${DIR_REMOTE_TMP}/${NUM_RUN}/${RUN_ID}.pidstat ${DIR_RUN}/${RUN_ID}_${HOST}.pidstat	
			fi 
			fi 
		done
	fi

	if [ "${USE_PERFKIT}" == "Y" ] ; then
		echo
		echo "-----------------------------"
		echo							
		echo "Stoping Performance Toolkit..."
		vmcp "force PERFSVM" 2>/dev/null 1>&2
 	while [ `vmcp q PERFSVM 2>/dev/null | grep -ic "not logged on"` -eq 0 ]
                 do
                         sleep 2
                 done
		vmcp "force CSVGEN" 2>/dev/null 1>&2
 	while [ `vmcp q CSVGEN 2>/dev/null | grep -ic "not logged on"` -eq 0 ]
                 do
                         sleep 2
                 done
		./robot get PERFSVM "FCONX.\$PROFILE"
 	while [ `ls | grep FCONX.$PROFILE | wc -l` -eq 0 ]
                 do
                         sleep 2
                 done
		cat FCONX.\$PROFILE | sed "s/^.*FC MONCOLL PERFLOG.*$/FC MONCOLL PERFLOG OFF/g" > FCONX.\$PROFILE.tmp
		mv FCONX.\$PROFILE.tmp FCONX.\$PROFILE
# ./robot mdelete PERFSVM "FCONX.\$PROFILE"
# 	while [ `./robot ls PERFSVM "FCONX.\$PROFILE"` -ne 0 ]
#                 do
#                         sleep 2
#                 done
		echo "Sending FCONX \$PROFILE..."
		./robot put PERFSVM "FCONX.\$PROFILE"
 	while [ `./robot ls PERFSVM "FCONX.\$PROFILE"` -eq 0 ]
                 do
                         sleep 2
                 done
		vmcp "xautolog PERFSVM" 2>/dev/null 1>&2
 	while [ `vmcp q PERFSVM 2>/dev/null | grep -ic "not logged on"` -ne 0 ]
                 do
                      			sleep 2
                 done
		vmcp "force PERFSVM" 2>/dev/null 1>&2
		while [ `vmcp q PERFSVM 2>/dev/null | grep -ic "not logged on"` -eq 0 ]
                 do
                         sleep 2
                 done
		filename=`date '+%Y%m%d'`
	#	./robot mdelete CSVGEN "*.HISTLOG"
	#	./robot mdelete CSVGEN "*.HISTLOG1"
	 ./robot mdelete CSVGEN "*HIST.CSV"
 	while [ `./robot ls CSVGEN "*HIST.CSV"` -ne 0 ]
                 do
                         sleep 2
                 done
		./robot mdelete CSVGEN "*HST2.CSV"
 	while [ `./robot ls CSVGEN "*HST2.CSV"` -ne 0 ]
                 do
                         sleep 2
                 done
		echo "/* PROCESSING CSVGEN */" > PROFILE.EXEC
		echo "'LINK PERFSVM 191 1191 RR'" >> PROFILE.EXEC
		echo "'ACCESS 1191 W'" >> PROFILE.EXEC
		today=$(date '+%d-%m-%Y')
		if [ "${today}" != "${RUN_DAY}" ] ; then
		 YD=`echo ${RUN_DAY} | cut -d"-" -f1`
		 YM=`echo ${RUN_DAY} | cut -d"-" -f2`
		 YY=`echo ${RUN_DAY} | cut -d"-" -f3`
		 OLD_DATE=${YY}${YM}${YD}
		 echo "'COPY ${filename} HISTLOG W ${filename} HISTLOG A'" >> PROFILE.EXEC
		 echo "'COPY ${OLD_DATE} HISTLOG1 W ${OLD_DATE} HISTLOG1 A'" >> PROFILE.EXEC	
		 echo "'pipe < ${filename} HISTLOG A | >> ${OLD_DATE} HISTLOG1 A'" >> PROFILE.EXEC
		 echo "'CSVGEN H ${OLD_DATE} HISTLOG1 A A ${NUM_RUN:0:3} (SPLIT FIN'" >> PROFILE.EXEC
	 else
			echo "'CSVGEN H ${filename} HISTLOG W A ${NUM_RUN:0:3} (SPLIT FIN'" >> PROFILE.EXEC
		fi
		echo "'rel 1191 (det'" >> PROFILE.EXEC
		echo "'CP LOGOFF'" >> PROFILE.EXEC
# ./robot mdelete CSVGEN "PROFILE.EXEC"
#  while [ `./robot ls CSVGEN "PROFILE.EXEC"` -ne 0 ]
#                 do
#                         sleep 2
#                 done
	 ./robot put CSVGEN "PROFILE.EXEC"
	 	while [ `./robot ls CSVGEN "PROFILE.EXEC"` -eq 0 ]
                 do
                         sleep 2
                 done
		echo "Starting CSVGEN..."
		vmcp "xautolog CSVGEN" 2>/dev/null 1>&2
#		./robot mget CSVGEN "${NUM_RUN:0:3}_*.CSV"
  while [ `./robot ls CSVGEN "${NUM_RUN:0:3}_HIST.CSV"` -eq 0 ]
			              do
																					    sleep 2
																	done
  ./robot get CSVGEN "${NUM_RUN:0:3}_HIST.CSV"
 	while [ `ls | grep "${NUM_RUN:0:3}_HIST.CSV" | wc -l` -ne 1 ]
                 do
                         sleep 2
                 done
		mv ${NUM_RUN:0:3}_HIST.CSV ${DIR_RUN}/${RUN_ID}_perfkit.CSV
#  mv ${NUM_RUN:0:3}_HST2.CSV ${DIR_RESULTS}/${RUN_DAY}/${RUN_NAME}_${NUM_RUN}/${RUN_NAME}_${NUM_RUN:0:3}_${RUN_TIME}_perfkit2.CSV
		[ -f "FCONX.\$PROFILE" ] && rm -rf "FCONX.\$PROFILE"
		[ -f "PROFILE.EXEC" ] && rm -rf "PROFILE.EXEC"
	fi

        #ORACLE BEGIN
        if [ "${USE_ORACLE}" == "Y" ] ; then
        echo
        echo "-----------------------------"
        echo
        echo "Stopping Oracle Monitoring..."
	echo
	 for HOST in `cat $ORA_MACHINES_FILES`
           do
                echo "Taking end snapshot on '${HOST}'..."
 $REMOTE_COMMANDE -t ${HOST} "sh /home/oracle/scripts/oracle_scripts/post_run.sh"
                sleep 10
                scp root@${HOST}:/tmp/*AWR_report*.html ${DIR_RUN}
          done
        fi
        #ORACLE END

}

#################################################

check_lock
if [ $? -ne 0 ] ; then 
	echo 
	echo "There are no run to stop."
	echo 
	exit 0
else
	if [ -z "$RUN_ID" ] ;
	then
        	echo
        	echo " ###############################################################"
        	echo " # Please provide a RUN_ID with the following syntax:          #"
        	echo " #         1st caracter is the 1st RUN_NAME letter             #"
        	echo " #         2nd caracter is the last digit of the year          #"
        	echo " #         3rd and 4th caracters are for the month             #"
        	echo " #         5th and 6th caracters are for the day               #"
        	echo " #         7th caracter is R for Run                           #"
        	echo " #         8th caracter is the run number for the current day  #"
        	echo " #                                                             #"
        	echo " # For instance, the 1st run of the day for TEMENOS benchmark  #"
        	echo " # on 21/11/2018 would be : T81121R1                           #"
        	echo " ###############################################################"
        	echo
	else

		read RUN_DAY RUN_TIME NUM_RUN NMON_CMD < $DIR_LOCKFILE/.lock

		stop_nmon
		rm run_in_progress
		rm -rf $DIR_LOCKFILE/.lock

		echo "--------------------------------------------------------------"
		echo "All the Data are in ${DIR_RUN}/ ..."
		echo 
		echo "You can start a new RUN."
	fi
fi 
