#!/bin/bash

DIR_RESULTS=$1
ORACLE_SCRIPTS=./oracle_scripts

for i in 1 ; do

	su - oracle -c "
		. ~/.profile
		export ORACLE_SID=T24DB$i
		echo
		echo "Taking snapshot for \${ORACLE_SID} DB"
		./${ORACLE_SCRIPTS}/take_snapshot.sh | awk '\$0!~/^\[/ && \$0!~/SQL/ && \$0!~/^\$/ { print \$1}' > /tmp/\${ORACLE_SID}_snap_before"

	mv /tmp/${i}_snap_before ${DIR_RESULTS}/${i}_snap_before

done
echo

