#!/bin/ksh
set -x
#sqlplus -s sysadm/crmuat@"(DESCRIPTION= (ADDRESS= (PROTOCOL=TCP) (HOST=p8crm-dev) (PORT=1532))(CONNECT_DATA= (SID=CRMUAT)))" << EOF
SQLPLUS="sqlplus -s"
USER=sysadm
PASS=crmuat
CONNSTR="(DESCRIPTION= (ADDRESS= (PROTOCOL=TCP) (HOST=p8crm-dev) (PORT=1532))(CONNECT_DATA= (SID=CRMUAT)))"
SCR="select * from (select name from v\$database) where rownum<2"
#$SQLPLUS $USER/$PASS@$CONNSTR
test1()
{
$SQLPLUS $USER/$PASS@"$CONNSTR" << EOF
set head off;
set echo off;
set feed off;
$SCR;
exit;
EOF
}
XX="`test1`"
YY=`echo $XX | awk -F' ' '{print $1}'`

echo "Value for YY is $YY"
