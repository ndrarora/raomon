#!/bin/ksh
set -x
####################################################################
#  File Name         : raommon.ksh
#  Purpose           : Monitoring Oracle Databases with given sql & 
#                    : related details
#  Date Created      : Apr 21, 2006
#  Author            : Rajesh Arora  (ndrarora@yahoo.com)
#  Comments          : 
####################################################################

############## Following parameters should be changee to implement this script on a new server

##Following Linese have hard values ############################### Start ###############
ORACLE_HOME=/opt/oracle/app/product/9.2.0.5/CRM_PROD; export ORACLE_HOME
STRLIB=/opt/oracle/home/DBA/scripts/Lib/StrLib01.sh
. $STRLIB
PWORKDIR=/opt/oracle/home/DBA/scripts/raomon
RAOMLOGDIR=/opt/oracle/home/DBA/logs/raomon
ADMINEMAIL=rarora@8x8.com

TMPDIR=/tmp/
#ORATAB=/var/opt/oracle/oratab
#ETCHOSTS=/etc/hosts
#UCBPS=/usr/ucb/ps
SQLPLUS="sqlplus -s"
##Following Linese have hard values ############################### End   ###############

############## Set Variables for Oracle Client ########################## Start ##############
LD_LIBRARY_PATH=$ORACLE_HOME/lib32:$ORACLE_HOME/lib;export LD_LIBRARY_PATH
PATH=$PATH:$ORACLE_HOME/bin ; export PATH
############## Set Variables for Oracle Client ########################## End   ##############

HN="`hostname`"

RAOMONCFG="config/raomoncfg.dev"

#RAOMSCRIPTS="config/omscripts"
#RAOMRUNEVENT="config/omrunevent"
#RAOMENVDETAIL="config/omenvdetail"
#RAOMUPLOADDB="config/omuploaddb"
#RAOMDATASTOR="datastor/omdatastor"

RAOMMAINT="config/raommaint."$HN
RAOMLOG="${RAOMLOGDIR}/raomon.log"
#########################################################################

####### garbrem -- Garbage removal function ######## Start #######
garbrem()
{
  FILENAME=raom_*
  rm $TMPDIR$FILENAME
}
####### garbrem -- Garbage removal function ######## End   #######


### Function finish_now -------------------------------------- Start #
finish_now()
{
  garbrem
  echo "****** RAOMON Finished `date +%Y%m%d%H%M%S` *" >> $RAOMLOG
}
### Function finish_now -------------------------------------- End   #
##### rm_file - Remove File ------------------------ Start #####
rm_file()
{
   (( $# > 1 )) && return 1
   [ -f "$1" -a -n "$1" ] && rm $1
}
##### rm_file - Remove File ------------------------ End   #####

########### Function get_tempfile                    Start #####
get_tempfile()
{
  #DDD=`date +%m%d%H%M%S`
  RND1="$RANDOM"
  RND2="$RANDOM"
  CURRSESS="raom_$$"
  #CURRSESS="raom_"
  #TEMPFILE="$TMPDIR$CURRSESS$RNDM$DDD"
  TEMPFILE="$TMPDIR$CURRSESS$RND1$RND2"
  rm_file $TEMPFILE
  echo " " > $TEMPFILE
  chmod 777 $TEMPFILE   
}
########### Function get_tempfile                    End   #####

########### Function Send email   ------------- Start ##########
### $1 -> Email Address
### $2 -> Email Subject
### $3 -> Email Body
send_email()
{
#!/bin/ksh
set -x
echo "entering send_email"
if [ "${SCRIPT2:-NOT FOUND}" = "NOT FOUND" ]; then
   echo "SCRIPT2 is not found"
   #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
   echo "$3@$BEGDATE" | mailx -s "$2@$BEGDATE" "$1"
   #echo "here it is" | mailx -s "test" "rarora@8x8.com"
   echo "****** RAOMON  Email Sent Address:$1 Subject:$2" >> $RAOMLOG
else
   echo "SCRIPT2 is found"
   > $TEMPEMAILBODY
   echo "$3$BEGDATE" > $TEMPEMAILBODY
   runscr2
   echo "     " >> $TEMPEMAILBODY
   cat "$TEMPSCRIPT2.lst"  >> $TEMPEMAILBODY
   cat "$TEMPEMAILBODY" | mailx -s "$2@$BEGDATE" "$1"
   #uuencode $TEMPEMAILBODY | mailx -s "$2@$BEGDATE" "$1"
   echo "****** RAOMON  Email Sent Address:$1 Subject:$2 with output" >> $RAOMLOG
fi
}
########### Function Send email   ------------- End   ##########


##################### RUNSCR Function to Run Script ###################### Start ###############
runscr()
{
$SQLPLUS $USER/$PASS@"$CONNSTR" << EOF
set head off;
set echo off;
set feed off;
whenever sqlerror exit 1
$SCR;
exit 0
EOF
}
##################### RUNSCR Function to Run Script ###################### End   ###############

##################### RUNSCR2 Function to Run Script and send output ##### Start ###############
runscr2()
{
#!/bin/ksh
set -x
$SQLPLUS /nolog << EOF
set echo on
set echo on
set feed off
whenever sqlerror exit 1
connect $USER/$PASS@"$CONNSTR"
spool $TEMPSCRIPT2
$SCRIPT2;
spool off;
exit 0
EOF
}
##################### RUNSCR2 Function to Run Script and send output ##### End   ###############

############# The Program ############################# Start #########
cd ${PWORKDIR}
get_tempfile
TEMPSCRIPT2="$TEMPFILE"
get_tempfile
TEMPEMAILBODY="$TEMPFILE"

get_tempfile
TF2="$TEMPFILE"

### Checking for the correct data file on this unix host ## Start

echo "****** RAOMON Started `date +%Y%m%d%H%M%S` *" >> $RAOMLOG

#  Sets the monitoring data and log variables

BEGDATE="`date +%Y%m%d%H%M`"
BEGDAY="`date +%d`"
BEGHR="`date +%H`"
BEGMIN="`date +%M`"
BEGHRMIN="`date +%H%M`"
#echo $BEGHRMIN
echo "Begin Hour is $BEGHR, Begin Min is $BEGMIN" >> $RAOMLOG
##### Main Logic Starts here ###########################################################
egrep ^omrunevent $RAOMONCFG    | while read LINE1
do
   RUNFREQ1="`echo ${LINE1} | awk -F: '{print $10}'`"
   RUNIT="NO"
   echo $LINE1 >> $RAOMLOG
   ############### Decide if needs to be run based on Frequency ### Start #####
   # Frequency could be 2M   -> one minute
   #                    6M   -> five minutes
   #                    10M  -> ten minutes
   #                    60M  -> sixty minutes
   #                     1D  -> one day   


#   if [ "$RUNFREQ1" = "" ]; then RUNFREQ1="1D"; fi

#   if [ $RUNFREQ1 = "2M" ]; then
#      a=`expr $BEGMIN % 2`
#      if [ $a = 0 ];
#          then
#          RUNIT="YES"
#      fi
#   fi

#   if [ "$RUNFREQ1" = "6M" ]; then
#      a=`expr $BEGMIN % 6`
#      if [ $a = 0 ];
#         then
#           RUNIT="YES"
#      fi
#   fi
#   if [ "$RUNFREQ1" = "10M" ]; then
#      a=`expr $BEGMIN % 10`
#      if [ $a = 0 ];
#         then
#           RUNIT="YES"
#      fi
#   fi

#   if [ "$RUNFREQ1" = "60M" ] && [ "$BEGMIN" = "00" ]; 
#      then 
#       RUNIT="YES" 
#   fi
#
#   if [ "$RUNFREQ1" = "1D" ] && [ "$BEGHRMIN" = "1400" ];
#      then 
#       RUNIT="YES"
#   fi
#
#   #if [ $RUNIT = "NO" ]; 
#   #    then 
#   #      break 
#   #      #skip
#   #fi
#   echo "Run it -> $RUNIT" >> $RAOMLOG
#   if [ "${RUNIT:-NO}" = "YES" ]; then
#
   echo "Runing" >> $RAOMLOG
   ############### Decide if needs to be run based on Frequency ### End   #####

   ENVIR1="`echo ${LINE1} | awk -F: '{print $2}'`"
   SN1="`echo ${LINE1} | awk -F: '{print $3}'`"
   EMAILYN="`echo ${LINE1} | awk -F: '{print $4}'`"
   EMAILADD1="`echo ${LINE1} | awk -F: '{print $5}'`"
   EMAILSUB1="`echo ${LINE1} | awk -F: '{print $6}'`"
   EMAILBODY1="`echo ${LINE1} | awk -F: '{print $7}'`"
   CONDITION="`echo ${LINE1} | awk -F: '{print $8}'`"
   #CONDITION="`echo ${LINE2} | awk -F: '{print $8}'`"
   COMPAREVALUE="`echo ${LINE1} | awk -F: '{print $9}'`"
   #COMPAREVALUE="`echo ${LINE2} | awk -F: '{print $9}'`"
   #RUNSTATUS="S"
   RUNSTATUS="F"

   egrep ^omscripts $RAOMONCFG   | while read LINE2
   do
      SN2=`echo ${LINE2} | awk -F: '{print $2}'`
      if [ "$SN1" = "$SN2" ]; then 

         SCRIPT="`echo ${LINE2} | awk -F: '{print $3}'`"
         ##### Default output type is Character (C)
         OUTPUTTYPE="C"
         OUTPUTTYPE="`echo ${LINE2} | awk -F: '{print $4}'`"
         SCRIPT2="NOT FOUND"
         SCRIPT2="`echo ${LINE2} | awk -F: '{print $5}'`"
echo "Script2 is $SCRIPT2"
         egrep ^omenvdetail $RAOMONCFG     | while read LINE3
         do
            ENVIR2=`echo ${LINE3} | awk -F: '{print $2}'`
            if [ "$ENVIR1" = "$ENVIR2" ]; then 
               HOSTNAME="`echo ${LINE3} | awk -F: '{print $3}'`"
               PORT="`echo ${LINE3} | awk -F: '{print $4}'`"
               USER="`echo ${LINE3} | awk -F: '{print $5}'`"
               PASS="`echo ${LINE3} | awk -F: '{print $6}'`"
               break
            fi
         done
         break
      fi
   done

   ###### run the script ################################### Start  ############################
   XXX=1
   SCROUTPUT="ERROR:"
   CONNSTR="(DESCRIPTION= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOSTNAME) (PORT=$PORT))(CONNECT_DATA= (SID=$ENVIR1)))"
   SCR="select * from ($SCRIPT) where rownum<2"
   RUNDATE="`date +%Y%m%d%H%M`"
   SCROUTPUT0="`runscr`"
   XXX=$?
echo "XXX is $XXX"
   #if [ $SCROUTPUTO = "" ]; then SCROUTPUTO=" "; fi
echo "Scr Out put is $SCROUTPUTO"
   SCROUTPUT=`echo $SCROUTPUT0 | awk -F' ' '{print $1}'`
   #if [ $SCROUTPUT = "" ]; then SCROUTPUT="NOERROR"; fi
echo "****** RAOMON  Event:$SN1 Env:$ENVIR1 Script:$SCRIPT ScriptOutput:$SCROUTPUTO *" >> $RAOMLOG
   ###### run the script ################################### End    ############################

   #RUNSTATUS="S"
   RUNSTATUS="F"
   if [ "${SCROUTPUT:-NOERROR}" = "NOERROR" ]; then SCROUTPUT="NOERROR"; fi 
   if [ "$SCROUTPUT" = "ERROR:" ]; 
      then 
        RUNSTATUS="F"
   fi

   if [ $XXX = 0 ]; then RUNSTATUS="S"; fi
 
   echo "runstatus is $RUNSTATUS"

   CONDITIONTRUE="N"
   EMAILSENT="N"
   if [ $CONDITION = "<>" ]; then
      CONDITION="-ne"
   fi
   if [ $CONDITION = "<" ]; then
      CONDITION="-lt"
   fi
   if [ $CONDITION = ">" ]; then
      CONDITION="-gt"
   fi
   
   if [ $CONDITION = "Fail" ] && [ $RUNSTATUS = "F" ]; then
      EMAILSUB1="$HN:$ENVIR1:$SN1:$EMAILSUB1"
      EMAILBODY1="$HN:$ENVIR1:DB On->$HOSTNAME:$SN1:$EMAILBODY1"
      #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
      send_email "$EMAILADD1" "$EMAILSUB1" "$EMAILBODY1"
      EMAILSENT="Y"
      echo "****** RAOMON  Email Sent Address:$EMAILADD1 Subject:$EMAILSUB1 *" >> $RAOMLOG
   fi
   if [ $CONDITION = "Succ" ] && [ $RUNSTATUS = "S" ]; then
      EMAILSUB1="$HN:$ENVIR1:$SN1:$EMAILSUB1"
      EMAILBODY1="$HN:$ENVIR1:DB On->$HOSTNAME:$SN1:$EMAILBODY1"
      #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
      send_email "$EMAILADD1" "$EMAILSUB1" "$EMAILBODY1"
      EMAILSENT="Y"
      echo "****** RAOMON  Email Sent Address:$EMAILADD1 Subject:$EMAILSUB1 *" >> $RAOMLOG
   fi
         
   if [ $RUNSTATUS = "S" ] 
      then 
         # the following condition makes sure that CONDITION is not null and also is not = "Fail"
         if [ "${CONDITION:-Fail}" <> "Fail" ] && [ "${CONDITION:-Fail}" <> "Succ" ] && [ "${COMPAREVALUE:-NuLL}" <> "NuLL" ]; then  
            echo "condition is $SCROUTPUT $CONDITION $COMPAREVALUE"
            if [ $OUTPUTTYPE = "C" ];
               then
                  if [ $SCROUTPUT $CONDITION $COMPAREVALUE ];
                     then
                        CONDITIONTRUE="Y"
                  fi
               else
                  if [ `expr $SCROUTPUT` $CONDITION `expr $COMPAREVALUE` ];
                     then
                        echo "condition is true"
                        CONDITIONTRUE="Y"
                     else  
                        echo "condition is false"
                        CONDITIONTRUE="N"
                  fi
            fi
            if [ "$CONDITIONTRUE" = "Y" ]; 
               then
                  EMAILSUB1="$HN:$ENVIR1:$SN1:$EMAILSUB1"
                  EMAILBODY1="$HN:$ENVIR1:DB On->$HOSTNAME:$SN1:$EMAILBODY1"
                  #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
                  echo "sending email"
                  send_email "$EMAILADD1" "$EMAILSUB1" "$EMAILBODY1"
                  echo "here 1"
                  EMAILSENT="Y"
                  echo "****** RAOMON  Email Sent Address:$EMAILADD1 Subject:$EMAILSUB1 *" >> $RAOMLOG
            fi
        fi
    fi

   #LOGLINE="Beg Date->$BEGDATE,Run Date->$RUNDATE,Freq->$RUNFREQ1,Env->$ENVIR1,SN->$SN1,EmailAdd->$EMAILADD1,Email Subject->$EMAILSUB1,Email Body->$EMAILBODY1,Script->$SCRIPT,Output type->$OUTPUTTYPE,Condition->$CONDITION,Compare value->$COMPAREVALUE,Hostname->$HOSTNAME,Port->$PORT,$USER,$PASS,OutPut->$SCROUTPUT,Status(S-Success/F-Fail)->$RUNSTATUS,Email Sent for event->$EMAILSENT"
   LOGLINE="Beg Date->$BEGDATE,Run Date->$RUNDATE,Freq->$RUNFREQ1,Env->$ENVIR1,SN->$SN1,EmailAdd->$EMAILADD1,Email Subject->$EMAILSUB1,Email Body->$EMAILBODY1,Script->$SCRIPT,Output type->$OUTPUTTYPE,Condition->$CONDITION,Compare value->$COMPAREVALUE,Hostname->$HOSTNAME,Port->$PORT,$USER,OutPut->$SCROUTPUT,Status(S-Success/F-Fail)->$RUNSTATUS,Email Sent for event->$EMAILSENT"
#echo "****** RAOMON  $LOGLINE" >> $RAOMLOG
   if [ $RUNSTATUS = "F" ] && [ ${CONDITION:-Fail} <> "Fail" ]  ; then
        #echo "$LOGLINE" | mailx -s "RAOMON Invalid Event" "$ADMINEMAIL"
        EMAILSUB1="$HN:$ENVIR1:$SN1:Invalid Event"
        EMAILBODY1="$HN:$ENVIR1:DB On->$HOSTNAME:$SN1:Invalid Event"
        #send_email "$ADMINMAIL" "RAOMON Invalid Event" "$LOGLINE"
        send_email "$ADMINMAIL" "$EMAILSUB1" "$EMAILBODY1"
   fi

   #LOGHDR=???

   echo $LOGLINE >> $RAOMDATASTOR

   ###### run the script ####################################################################################################
#   fi;
done
finish_now
exit
############################################ End of Script #################################################################
###
###
########## Limitations 
#1. If the sql output is "no rows selected", it is treated as successful & no comparis is made to #     given values
#   except if the condition is "Succ", this is because the output of the sql is not take, only the#  output of
#   the sqlplus command execution is taken
#2.



