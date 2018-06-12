#!/bin/ksh
EMAILBODY1="Test body 1"
EMAILSUB1="Email sub 1"
EMAILADD1="r.x.arora@accenture.com"
EMAILSENDER="ndrarora@yahoo.com"
set -x
echo "entering send_email"
echo "$EMAILBODY1" > xyz
cat xyz | mailx -r "$EMAILSENDER" -s "$EMAILSUB1" "$EMAILADD1"
#cat config/envcfg | mailx -r "$EMAILSENDER" -s "$EMAILSUB1" "$EMAILADD1"

