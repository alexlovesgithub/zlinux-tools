#!/bin/bash

DIR_RESULTS=$1
ORACLE_SCRIPTS=./oracle_scripts

for i in 1  ; do

	su - oracle -c "
		. ~/.profile
		export ORACLE_SID=T24DB$i
		echo
		echo "Taking snapshot and generate AWR report for \${ORACLE_SID}"
		./${ORACLE_SCRIPTS}/take_snapshot.sh | awk '\$0!~/^\[/ && \$0!~/SQL/ && \$0!~/^\$/ { print \$1}' | while read SNAP_AFTER ; do
			cat ${DIR_RESULTS}/\${ORACLE_SID}_snap_before | while read SNAP_BEFORE ; do 
				echo \$SNAP_BEFORE \$SNAP_AFTER
				./${ORACLE_SCRIPTS}/generate_AWR.sh $1 \$SNAP_BEFORE \$SNAP_AFTER
			done
		done		
"
	
done

