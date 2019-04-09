#!/bin/sh
# Etre logge Oracle
. ~/.profile

sqlplus -S "/as sysdba" << FIN
variable snap_current number;
begin :snap_current:=DBMS_WORKLOAD_REPOSITORY.create_snapshot;
end;
/
set feedback off
set termout off
set head off
print snap_current;
exit
FIN

