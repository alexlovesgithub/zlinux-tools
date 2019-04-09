#!/bin/sh
snap_begin=$2
snap_end=$3
rep=$1
sqlplus -S "/ as sysdba" << END
set head off
set feedback off
set termout off
@?/rdbms/admin/awrrpt
html
2
$snap_begin
$snap_end
${rep}/${ORACLE_SID}_AWR_report_${snap_begin}_${snap_end}.html
exit
END

