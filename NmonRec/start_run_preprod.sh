#!/bin/sh

. ./run_variables_preprod

#################################################

function check_lock() {
	ls $DIR_LOCKFILE/.lock > /dev/null 2>&1
}

function test_ping() {
	ping -c1 -q -w1 $1 > /dev/null
	if [ ! $? -eq 0 ]; then
		echo 
		echo "#####################"
		echo "# !! PING FAILED !! #"
		echo "#####################"
		exit 1
	fi
}

function check_environment() {
	for HOST in `cat $MACHINES_FILES`
	do
		if [ "${USE_NMON}" == "Y" ] ; then
		 nmon_check=`$REMOTE_COMMANDE ${HOST} "nmon -V"`
		 if [ `echo ${nmon_check} | grep -c "nmon"` -ne 1 ] ; then
				echo "NMON is missing on host ${HOST}. Exiting !"
				exit 1
			fi
		fi	
		if [ "${USE_SYSSTAT}" == "Y" ] ; then
		 rpm_sysstat_check=`$REMOTE_COMMANDE ${HOST} "rpm -qa | grep sysstat"`
		 if [ `echo ${rpm_sysstat_check} | grep -c "8.0.4"` -ne 1 ] ; then
 		 iostat_check=`$REMOTE_COMMANDE ${HOST} "which iostat"`
 		 vmstat_check=`$REMOTE_COMMANDE ${HOST} "which vmstat"`
 		 pidstat_check=`$REMOTE_COMMANDE ${HOST} "which pidstat"`
 		 if [ -z "${iostat_check}" ] || [ -z "${vmstat_check}" ] || [ -z "${pidstat_check}" ] ; then
 			 echo "SYSSTAT package is missing or is a non supported version (other than 8.0.4) on host ${HOST}. Exiting !"
 			 exit 1
 			fi
			fi
		fi

 	$REMOTE_COMMANDE ${HOST} "[ ! -d /tmp/NmonRec ] && mkdir -p /tmp/NmonRec"
	done
}

function start_nmon() {
	echo
	echo "##########################################"
	echo "> STARTING RUN ${RUN_ID} "
	echo "##########################################"
	echo 
	if [ "${USE_SYSSTAT}" == "Y" ] || [ "${USE_NMON}" == "Y" ] ; then
  echo "Checking software version..."
  check_environment
		for HOST in `cat $MACHINES_FILES`
		do
			echo 
			echo "----------[ $HOST ]----------"
			echo
			test_ping $HOST
			##############################################################################
			####### integration of the sys-anal tool to monitor the PID activity #########
			##############################################################################
			if [ "${USE_SYSSTAT}" == "Y" ] ; then
				pidflag="0"
				echo "You can choose to monitor the activity per PID: this is an additionnal measurement !"
				echo "In any case, iostat and vmstat will be used to record the information."
				echo
				echo "Monitor PID activity ? (y/n) [n]"
				read monitorPID
				[ -z ${monitorPID} ] && monitorPID="n"
				if [ "${monitorPID}" == "y" ] ; then
					if [ "${PIDFILE}" == "N" ] ; then
						echo 
						echo "Enter a list of PID to monitor for host '${HOST}' with sysstat (separated by space or colon):"
						read listPID
						if [ "${listPID}" != "" ] ; then
							listPID=`echo ${listPID} | sed "s/,/ /g"`
							listPID=`echo ${listPID} | sed "s/  */ /g"`
							PIDcount=`echo ${listPID} | wc -w`
							for PID in `echo ${listPID}`
							do
								$REMOTE_COMMANDE ${HOST} "ps -ef | grep -v grep | awk '{print \$2}' | grep -wc \"${PID}\"" > tmp
								present=`cat tmp`
								rm tmp
								[ ${present} -eq 1 ] && echo ${PID} >> ${RUN_NAME}_${HOST}_${NEW_NUM_RUN}.PID
							done
							if [ -f ${RUN_NAME}_${HOST}_${NEW_NUM_RUN}.PID ] ; then	
								if [ ${PIDcount} -eq `cat ${RUN_NAME}_${HOST}_${NEW_NUM_RUN}.PID | wc -l` ] ; then 
									entetePID=`pidstat -r -u -p ALL | sed -n "3{p;q}"`
									$REMOTE_COMMANDE ${HOST} "[ ! -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && mkdir -p $DIR_REMOTE_TMP/${NEW_NUM_RUN} ; echo \"${entetePID}\" >> $DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.pidstat"
									scp ${RUN_NAME}_${HOST}_${NEW_NUM_RUN}.PID root@${HOST}:$DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.PID
									pidflag="1"
									rm ${RUN_NAME}_${HOST}_${NEW_NUM_RUN}.PID
								else
									echo "One of the PID entered does NOT exist. Exiting..."
								fi
							else
								echo "None of the PIDs entered exist. Exiting..."
							fi	
						else
							echo "No PID to monitor. Exiting." 
						fi
					else
						if [ ! -f /opt/NmonRec/${RUN_NAME}/${HOST}.pid ] ; then
							echo "Enter a list of PID to monitor for host '${HOST}' with sysstat (separated by space or colon):"
							read listPID
							if [ "${listPID}" != "" ] ; then
								listPID=`echo ${listPID} | sed "s/,/ /g"`
								listPID=`echo ${listPID} | sed "s/  */ /g"`
								PIDcount=`echo ${listPID} | wc -w`
								for PID in `echo ${listPID}`
								do
									$REMOTE_COMMANDE ${HOST} "ps -ef | grep -v grep | awk '{print \$2}' | grep -wc \"${PID}\"" > tmp
									present=`cat tmp`
									rm tmp
									[ ${present} -eq 1 ] && echo ${PID} >> /opt/NmonRec/${RUN_NAME}/${HOST}.pid
								done
								if [ -f /opt/NmonRec/${RUN_NAME}/${HOST}.pid ] ; then
									if [ ${PIDcount} -eq `cat /opt/NmonRec/${RUN_NAME}/${HOST}.pid | wc -l` ] ; then
										entetePID=`pidstat -r -u -p ALL | sed -n "3{p;q}"`
										$REMOTE_COMMANDE ${HOST} "[ ! -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && mkdir -p $DIR_REMOTE_TMP/${NEW_NUM_RUN} ; echo \"${entetePID}\" >> $DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.pidstat"
										scp /opt/NmonRec/${RUN_NAME}/${HOST}.pid root@${HOST}:$DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.PID
										pidflag="1"
									else
										echo "One of the PID entered does NOT exist. Exiting..."
									fi
								else
									echo "None of the PIDs entered exist. Exiting..."
								fi
							else
								echo "No PID to monitor. Exiting."
							fi
						else
							nbElement=`cat /opt/NmonRec/${RUN_NAME}/${HOST}.pid | wc -l`
							if [ ${nbElement} -ne 0 ] ; then
								i=1
								while [ ${i} -le ${nbElement} ]
								do
									line=`sed -n "${i}{p;q}" /opt/NmonRec/${RUN_NAME}/${HOST}.pid`
									PID=`echo ${line}`
									$REMOTE_COMMANDE ${HOST} "ps -ef | grep -v grep | awk '{print \$2}' | grep -wc \"${PID}\"" > tmp
									present=`cat tmp`
									rm tmp
									[ ${present} -eq 1 ] && echo ${PID} >> /opt/NmonRec/${RUN_NAME}/tmp.pid

									i=`expr ${i} + 1`
								done

								if [ -f /opt/NmonRec/${RUN_NAME}/tmp.pid ] ; then
									if [ `cat /opt/NmonRec/${RUN_NAME}/tmp.pid | wc -l` -eq `cat /opt/NmonRec/${RUN_NAME}/${HOST}.pid | wc -l` ] ; then
										rm /opt/NmonRec/${RUN_NAME}/tmp.pid
										entetePID=`pidstat -r -u -p ALL | sed -n "3{p;q}"`
										$REMOTE_COMMANDE ${HOST} "[ ! -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && mkdir -p $DIR_REMOTE_TMP/${NEW_NUM_RUN} ; echo \"${entetePID}\" >> $DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.pidstat"
										scp /opt/NmonRec/${RUN_NAME}/${HOST}.pid root@${HOST}:$DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.PID
										pidflag="1"
									else
										rm /opt/NmonRec/${RUN_NAME}/tmp.pid
										echo "One of the PIDs to monitor in the /opt/NmonRec/${RUN_NAME}/${HOST}.pid file does not exist anymore on the ${HOST} machine. The PIDstat process won't be started"
									fi
								else
									echo "None of the PIDs to monitor in the /opt/NmonRec/${RUN_NAME}/${HOST}.pid file does exist anymore on the ${HOST} machine. The PIDstat process won't be started"
								fi	
							else
								echo "No PID to monitor in the /opt/NmonRec/${RUN_NAME}/${HOST}.pid file. Do you want to enter a list of PID to monitor for host '${HOST}' with sysstat ? [n]"
								read answerPID
								[ -z ${answerPID} ] && answerPID="n"
								if [ "${answerPID}" == "y" ] ; then
									echo "Enter a list of PID to monitor for host '${HOST}' with sysstat (separated by space or colon):"
									read listPID
									if [ "${listPID}" != "" ] ; then
										listPID=`echo ${listPID} | sed "s/,/ /g"`
										listPID=`echo ${listPID} | sed "s/  */ /g"`
										PIDcount=`echo ${listPID} | wc -w`
										for PID in `echo ${listPID}`
										do
											$REMOTE_COMMANDE ${HOST} "ps -ef | grep -v grep | awk '{print \$2}' | grep -wc \"${PID}\"" > tmp
											present=`cat tmp`
											rm tmp
											[ ${present} -eq 1 ] && echo ${PID} >> /opt/NmonRec/${RUN_NAME}/tmp.pid
										done
										if [ -f /opt/NmonRec/${RUN_NAME}/tmp.pid ] ; then
											if [ ${PIDcount} -eq `cat /opt/NmonRec/${RUN_NAME}/tmp.pid | wc -l` ] ; then
												cp --copy-contents /opt/NmonRec/${RUN_NAME}/tmp.pid /opt/NmonRec/${RUN_NAME}/${HOST}.pid												   
												rm /opt/NmonRec/${RUN_NAME}/tmp.pid       
												entetePID=`pidstat -r -u -p ALL | sed -n "3{p;q}"`
												$REMOTE_COMMANDE ${HOST} "[ ! -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && mkdir -p $DIR_REMOTE_TMP/${NEW_NUM_RUN} ; echo \"${entetePID}\" >> $DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.pidstat"
												scp /opt/NmonRec/${RUN_NAME}/${HOST}.pid root@${HOST}:$DIR_REMOTE_TMP/${NEW_NUM_RUN}/${RUN_NAME}_${NEW_NUM_RUN}.PID
												pidflag="1"
											else
												rm /opt/NmonRec/${RUN_NAME}/tmp.pid 
												echo "One of the PIDs entered does NOT exist. The PIDstat process won't be started"
											fi
										else
											echo "None of the PID entered exist. The PIDstat process won't be started"
										fi					
									else
										echo "No PID to monitor. The PIDstat process won't be started"
									fi	
								else
									echo "PID monitoring for host '${HOST}' won't be started..."
								fi	
							fi	
						fi	
					fi
				fi
				$REMOTE_COMMANDE ${HOST} "[ ! -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && mkdir -p $DIR_REMOTE_TMP/${NEW_NUM_RUN}"
				echo "Starting Sysstat..." && $REMOTE_COMMANDE ${HOST} "echo \"/tmp/NmonRec/scriptSysstat ${DELAY} ${COUNT} $DIR_REMOTE_TMP/${RUN_ID} ${pidflag}\" | at now"
			fi
			##### End of the PID monitor program ###########
			if [ "${USE_NMON}" == "Y" ] ; then
				echo "Starting Nmon..." && $REMOTE_COMMANDE ${HOST} "[ ! -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && mkdir -p $DIR_REMOTE_TMP/${NEW_NUM_RUN}; echo \"$NMON_CMD\" | at now "
				echo $REMOTE_COMMANDE ${HOST} "[ ! -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && mkdir -p $DIR_REMOTE_TMP/${NEW_NUM_RUN}; echo \"$NMON_CMD\" | at now "
				echo "----------[ $HOST ]----------" | sed "s/./-/g"
				echo
			fi
		done
	fi
	if [ "${USE_PERFKIT}" == "Y" ] ; then
		[ `lsmod | grep -wc vmcp` -eq 0 ] && modprobe vmcp
	#	[ `lsmod | grep -wc vmcp` -eq 0 ]
	 echo
		echo "-----------------------------"
		echo
		echo "Starting Performance Toolkit..."
		vmcp "force PERFSVM" 2>/dev/null 1>&2
		while [ `vmcp q PERFSVM 2>/dev/null | grep -ic "not logged on"` -eq 0 ]
                do
                        sleep 2
                done
		[ -f "FCONX.\$PROFILE" ] && rm -rf "FCONX.\$PROFILE"
		filename=`date '+%Y%m%d'`
		./robot delete PERFSVM "${filename}.HISTLOG"
		while [ `./robot ls PERFSVM "${filename}.HISTLOG"` -ne 0 ]
                do
                        sleep 2
                done
		echo "Retrieving FCONX \$PROFILE..."
	 ./robot get PERFSVM "FCONX.\$PROFILE" 
 	while [ `ls | grep "FCONX.\$PROFILE" | wc -l` -ne 1 ]
                do
                        sleep 2
                done
		startHour="${TIME:0:2}"
		startMinute="${TIME:2:2}"
		duration=`expr ${DELAY} \* ${COUNT}`
		hourDuration=`expr ${duration} / 3600`
		minuteDuration=`expr ${duration} % 3600 / 60`
		endMinute=`expr ${startMinute} + ${minuteDuration}`
		additionalHour=`expr ${endMinute} / 60`
		endMinute=`expr ${endMinute} % 60`
		[ ${endMinute} -lt 10 ] && endMinute="0${endMinute}"
		endHour=`expr ${startHour} + ${hourDuration} + ${additionalHour}`
		endHour=`expr ${endHour} % 24`
		[ ${endHour} -lt 10 ] && endHour="0${endHour}"
		cat FCONX.\$PROFILE | sed "s/^.*FC MONCOLL PERFLOG.*$/FC MONCOLL PERFLOG ON ${startHour}:${startMinute} ${endHour}:${endMinute} ALL/g" > FCONX.\$PROFILE.tmp
		echo "Sending FCONX \$PROFILE..."
		mv FCONX.\$PROFILE.tmp FCONX.\$PROFILE
#		./robot delete PERFSVM "FCONX.\$PROFILE"		
# 	while [ `./robot ls PERFSVM "FCONX.\$PROFILE"` -ne 0 ]
#                 do
#                         sleep 2
#                 done
		./robot put PERFSVM "FCONX.\$PROFILE"
 	while [ `./robot ls PERFSVM "FCONX.\$PROFILE"` -eq 0 ]
                 do
                         sleep 2
                 done
		echo "Starting PERFSVM..."
		vmcp "xautolog PERFSVM" 2>/dev/null 1>&2
  while [ `vmcp q PERFSVM 2>/dev/null | grep -ic "not logged on"` -ne 0 ]
                 do
                         sleep 2
                 done
 		[ -f "FCONX.\$PROFILE" ] && rm -rf "FCONX.\$PROFILE"
	fi

#ORACLE BEGIN

if [ "${USE_ORACLE}" == "Y" ] ; then
 for HOST in `cat $ORA_MACHINES_FILES`
 do
        echo "Taking start snapshot on '${HOST}'..."
        echo "Remote Command = "$REMOTE_COMMANDE ${HOST}
        $REMOTE_COMMANDE -t ${HOST} "sh /home/oracle/scripts/oracle_scripts/pre_run.sh"
 done
fi
#ORACLE END

}

#################################################

check_lock
if [ $? -eq 0 ] ; then 
	echo "Run $NUM_RUN is currently running... Please stop it before starting a NEW RUN (stop_run)."
	exit 0
fi 


if [ "${USE_SYSSTAT}" == "Y" ] ; then
 for HOST in `cat $MACHINES_FILES`
 do
 	echo "Sending sysstat scripts on '${HOST}'..."
 	$REMOTE_COMMANDE ${HOST} "[ -f /tmp/NmonRec/scriptSysstat ] && rm /tmp/NmonRec/scriptSysstat"
 	scp scriptSysstat root@${HOST}:/tmp/NmonRec/scriptSysstat 2>/dev/null 1>&2
 	$REMOTE_COMMANDE ${HOST} "chmod 755 /tmp/NmonRec/scriptSysstat"
 	$REMOTE_COMMANDE ${HOST} "[ -d $DIR_REMOTE_TMP/${NEW_NUM_RUN} ] && rm $DIR_REMOTE_TMP/${NEW_NUM_RUN} 2>/dev/null"
 done
fi


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
	#mkdir -p ${DIR_RESULTS}/${DAY}/${RUN_NAME}_$NEW_NUM_RUN
	mkdir -p ${DIR_RUN}
	[ $? -eq 0 ] && start_nmon
	echo $RUN_ID > run_in_progress
	echo "$DAY $TIME $NEW_NUM_RUN $NMON_CMD" > $DIR_LOCKFILE/.lock
fi
