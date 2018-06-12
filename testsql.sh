#!/bin/ksh
#set -x
runscr()
{
$SQLPLUS $USER/$PASS@"$CONNSTR" << EOF
set head off;
set echo off;
set feed off;
whenever not_data_found exit 3
whenever sqlerror exit 1
$SCR;
exit 0
EOF
}
ORACLE_HOME=/opt/oracle/app/product/9.2.0.5/CRM_PROD; export ORACLE_HOME
LD_LIBRARY_PATH=$ORACLE_HOME/lib32:$ORACLE_HOME/lib;export LD_LIBRARY_PATH
PATH=$PATH:$ORACLE_HOME/bin ; export PATH
SQLPLUS=sqlplus
SCR="select * from (select serveraction from sysadm.psserverstat where servername='PSNT9') where rownum<2"
#SCR="select * from (select name from v\$database) where rownum<2"
USER="omon"
PASS="xxomonyy"
CONNSTR="(DESCRIPTION= (ADDRESS= (PROTOCOL=TCP) (HOST=p8crm-dev.8x8.com) (PORT=1532))(CONNECT_DATA= (SID=CRMUAT)))"
X="`runscr`"
Y="start"
echo "Y is $Y"
Y="$Y$X"
echo "Y is $Y"
Y="$Yend"
echo "Y is $Y"
echo "X is $X"
echo "Y is $Y"
if [ "$X" = "    " ]; then 
  echo "X is null"
fi
