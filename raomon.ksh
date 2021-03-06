#!/bin/ksh
set +x
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
#ORACLE_HOME=/opt/oracle/app/product/9.2.0.5/CRM_PROD; export ORACLE_HOME
ORACLE_HOME=/local/home/oracle/product/10.2.0; export ORACLE_HOME
#STRLIB=/opt/oracle/home/DBA/scripts/Lib/StrLib01.sh
#. $STRLIB
#PWORKDIR=/opt/oracle/home/DBA/scripts/raomon
PWORKDIR=/raid/home/psoftd/raomon
RAOMLOGDIR=/raid/home/psoftd/log/raomon
ADMINEMAIL=rajesh.arora@blueshieldca.com
EMAILSENDER=rajesh.arora@blueshieldca.com
#PRESCRIPT2=/export/home/oracle/scripts/raomon/prescript2

TMPDIR=/tmp/
#ORATAB=/var/opt/oracle/oratab
#ETCHOSTS=/etc/hosts
#UCBPS=/usr/ucb/ps
SQLPLUS="sqlplus -s"
FREQ1D="0856"
##Following Linese have hard values ############################### End   ###############

############## Set Variables for Oracle Client ########################## Start ##############
LD_LIBRARY_PATH=$ORACLE_HOME/lib32:$ORACLE_HOME/lib;export LD_LIBRARY_PATH
PATH=$PATH:$ORACLE_HOME/bin ; export PATH
############## Set Variables for Oracle Client ########################## End   ##############

HHN="`hostname`"
HN="RAOMON"

RAOMONCFG="config/raomoncfg"
#ENVCFG="config/envcfg"
RAOMONALERTS="$PWORKDIR/raomonalerts"

#RAOMSCRIPTS="config/omscripts"
#RAOMRUNEVENT="config/omrunevent"
#RAOMENVDETAIL="config/omenvdetail"
#RAOMUPLOADDB="config/omuploaddb"
#RAOMDATASTOR="datastor/omdatastor"

RAOMMAINT="config/raommaint."$HN

BEGDT="`date +%Y%m%d`"
#RAOMLOG="${RAOMLOGDIR}/raomon.log"
RAOMLOG="${RAOMLOGDIR}/raomon.log.${BEGDT}"
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
   > $TEMPEMAILBODY
   echo "$3@$BEGDATE" > $TEMPEMAILBODY
   #echo "     $HHN     " >> $TEMPEMAILBODY
   echo "     " >> $TEMPEMAILBODY
   #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
   #echo "$3@$BEGDATE" | mailx -r "$EMAILSENDER" -s  "$2@$BEGDATE" "$1"
   cat "$TEMPEMAILBODY" | mailx -r "$EMAILSENDER" -s "$2@$BEGDATE" "$1"
   #echo "$3@$BEGDATE" | mailx -s "$2@$BEGDATE" "$1"
   #echo "here it is" | mailx -s "test" "rajesh.arora@blueshieldca.com"
   echo "****** RAOMON  Email Sent Address:$1 Subject:$2" >> $RAOMLOG
   #mailx -r ndrarora@yahoo.com -s "test" rajesh.arora@blueshieldca.com
else
   echo "SCRIPT2 is found"
   > $TEMPEMAILBODY
   echo "$3@$BEGDATE" > $TEMPEMAILBODY
   runscr2
   #echo "     $HHN     " >> $TEMPEMAILBODY
   echo "     " >> $TEMPEMAILBODY
   cat "$TEMPSCRIPT2.lst"  >> $TEMPEMAILBODY
   #cat "$TEMPEMAILBODY" | mailx -s "$2@$BEGDATE" "$1"
   cat "$TEMPEMAILBODY" | mailx -r "$EMAILSENDER" -s "$2@$BEGDATE" "$1"
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
set head on
set feed off
set pagesize 0
set linesize 500
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
DAYOFWEEK="`date +%a`"
#echo $BEGHRMIN
echo "Begin Hour is $BEGHR, Begin Min is $BEGMIN" >> $RAOMLOG
##### Main Logic Starts here ###########################################################
egrep ^omrunevent $RAOMONCFG    | while read LINE1
do
   RUNFREQ1="`echo ${LINE1} | awk -F: '{print $10}'`"
   RUNIT="NO"
   echo $LINE1 >> $RAOMLOG
   ############### Decide if needs to be run based on Frequency ### Start #####
   # Frequency could be 2M   -> Two minute
   #                    3M   -> Three minute
   #                    4M   -> Four minute
   #                    6M   -> Six minutes
   #                    9M   -> Nine minutes
   #                    10M  -> Ten minutes
   #                    60M  -> Sixty minutes
   #                     1D  -> One day   


   if [ "$RUNFREQ1" = "" ]; then RUNFREQ1="1D"; fi

   if [ $RUNFREQ1 = "2M" ]; then
      a=`expr $BEGMIN % 2`
      if [ $a = 0 ];
          then
          RUNIT="YES"
      fi
   fi

   if [ $RUNFREQ1 = "3M" ]; then
      a=`expr $BEGMIN % 3`
      if [ $a = 0 ];
          then
          RUNIT="YES"
      fi
   fi

   if [ $RUNFREQ1 = "4M" ]; then
      a=`expr $BEGMIN % 4`
      if [ $a = 0 ];
          then
          RUNIT="YES"
      fi
   fi

   if [ $RUNFREQ1 = "5M" ]; then
      a=`expr $BEGMIN % 5`
      if [ $a = 0 ];
          then
          RUNIT="YES"
      fi
   fi

   if [ "$RUNFREQ1" = "6M" ]; then
      a=`expr $BEGMIN % 6`
      if [ $a = 0 ];
         then
           RUNIT="YES"
      fi
   fi

   if [ "$RUNFREQ1" = "9M" ]; then
      a=`expr $BEGMIN % 9`
      if [ $a = 0 ];
         then
           RUNIT="YES"
      fi
   fi

   if [ "$RUNFREQ1" = "10M" ]; then
      a=`expr $BEGMIN % 10`
      if [ $a = 0 ];
         then
           RUNIT="YES"
      fi
   fi

   if [ "$RUNFREQ1" = "60M" ] && [ "$BEGMIN" = "00" ]; 
      then 
       RUNIT="YES" 
   fi

   if [ "$RUNFREQ1" = "1D" ] && [ "$BEGHRMIN" = "$FREQ1D" ];
      then 
       RUNIT="YES"
   fi

   if [ "$RUNFREQ1" = "1W" ] && [ "$BEGHRMIN" = "$FREQ1D" ] && [ "$DAYOFWEEK" = "Mon"] ;
      then 
       RUNIT="YES"
   fi

   #if [ $RUNIT = "NO" ]; 
   #    then 
   #      break 
   #      #skip
   #fi
   echo "Run it -> $RUNIT" >> $RAOMLOG
   if [ "${RUNIT:-NO}" = "YES" ]; then

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
#echo "1" >> $RAOMLOG
   egrep ^omscripts $RAOMONCFG   | while read LINE2
   do
#echo "1.0" >> $RAOMLOG
      SN2=`echo ${LINE2} | awk -F: '{print $2}'`
      if [ "$SN1" = "$SN2" ]; then 

#echo "1.1" >> $RAOMLOG
         SCRIPT="`echo ${LINE2} | awk -F: '{print $3}'`"
         ##### Default output type is Character (C)
         OUTPUTTYPE="C"
         OUTPUTTYPE="`echo ${LINE2} | awk -F: '{print $4}'`"
#echo "1.2" >> $RAOMLOG
#echo "Line2 is $LINE" >> $RAOMLOG
         SCRIPT2="NOT FOUND"
         SCRIPT2="`echo ${LINE2} | awk -F: '{print $5}'`"
#echo "SCRIPT2 found and is $SCRIPT2" >> $RAOMLOG
#echo "1.3" >> $RAOMLOG
         egrep ^omenvdetail $RAOMONCFG     | while read LINE3
         do
            ENVIR2=`echo ${LINE3} | awk -F: '{print $2}'`
            if [ "$ENVIR1" = "$ENVIR2" ]; then 
               HOSTNAME="`echo ${LINE3} | awk -F: '{print $3}'`"
               PORT="`echo ${LINE3} | awk -F: '{print $4}'`"
               ENVSID="`echo ${LINE3} | awk -F: '{print $5}'`"
               USER="`echo ${LINE3} | awk -F: '{print $6}'`"
               PASS="`echo ${LINE3} | awk -F: '{print $7}'`"
               break
            fi
         done
         break
      fi
   done
#echo "1.4" >> $RAOMLOG
   ###### run the script ################################### Start  ############################
   XXX=1
   SCROUTPUT="ERROR:"
   CONNSTR="(DESCRIPTION= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOSTNAME) (PORT=$PORT))(CONNECT_DATA= (SID=$ENVSID)))"
   SCR="select * from ($SCRIPT) where rownum<2"
   RUNDATE="`date +%Y%m%d%H%M`"
   SCROUTPUT0="`runscr`"
   XXX=$?
echo "XXX is $XXX"
   #if [ $SCROUTPUTO = "" ]; then SCROUTPUTO=" "; fi
echo "Scr Out put is $SCROUTPUTO"
   SCROUTPUT=`echo $SCROUTPUT0 | awk -F' ' '{print $1}'`
   #if [ $SCROUTPUT = "" ]; then SCROUTPUT="NOERROR"; fi
echo "****** RAOMON  Event:$SN1 Env:$ENVIR1:$ENVSID:Script:$SCRIPT ScriptOutput:$SCROUTPUTO *" >> $RAOMLOG
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
      EMAILSUB1="$HN:$ENVIR1:$ENVSID:$SN1:$EMAILSUB1"
      EMAILBODY1="$HN:$ENVIR1:$ENVSID:DB On->$HOSTNAME:$SN1:Freq $RUNFREQ1 $EMAILBODY1"
      #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
      send_email "$EMAILADD1" "$EMAILSUB1" "$EMAILBODY1"
      EMAILSENT="Y"
      echo "****** RAOMON  Email Sent Address:$EMAILADD1 Subject:$EMAILSUB1 *" >> $RAOMLOG
   fi
   if [ $CONDITION = "Succ" ] && [ $RUNSTATUS = "S" ]; then
      EMAILSUB1="$HN:$ENVIR1:$ENVSID:$SN1:$EMAILSUB1"
      EMAILBODY1="$HN:$ENVIR1:$ENVSID:DB On->$HOSTNAME:$SN1:Freq $RUNFREQ1 $EMAILBODY1"
      #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
      send_email "$EMAILADD1" "$EMAILSUB1" "$EMAILBODY1"
      EMAILSENT="Y"
      echo "****** RAOMON  Email Sent Address:$EMAILADD1 Subject:$EMAILSUB1 *" >> $RAOMLOG
   fi
         
   if [ $RUNSTATUS = "S" ] 
      then 
         # the following condition makes sure that CONDITION is not null and also is not = "Fail"
         if [ "${CONDITION:-Fail}" <> "Fail" ] && [ "${CONDITION:-Fail}" <> "Succ" ] && [ "${COMPAREVALUE:-NuLL}" <> "NuLL" ]; then  
            echo "Reached JUNK"
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
                  EMAILSUB1="$HN:$ENVIR1:$ENVSID:$SN1:$EMAILSUB1"
                  EMAILBODY1="$HN:$ENVIR1:$ENVSID:DB On->$HOSTNAME:$SN1:Freq $RUNFREQ1 $EMAILBODY1"
                  #echo "$EMAILBODY1" | mailx -s "$EMAILSUB1" "$EMAILADD1"
                  echo "sending email"
                  send_email "$EMAILADD1" "$EMAILSUB1" "$EMAILBODY1"
                  echo "here 1"
                  EMAILSENT="Y"
                  echo "****** RAOMON  Email Sent Address:$EMAILADD1 Subject:$EMAILSUB1 *" >> $RAOMLOG
            fi
        fi
    fi

   #LOGLINE="Beg Date->$BEGDATE,Run Date->$RUNDATE,Freq->$RUNFREQ1,Env->$ENVIR1,$ENVSID,SN->$SN1,EmailAdd->$EMAILADD1,Email Subject->$EMAILSUB1,Email Body->$EMAILBODY1,Script->$SCRIPT,Output type->$OUTPUTTYPE,Condition->$CONDITION,Compare value->$COMPAREVALUE,Hostname->$HOSTNAME,Port->$PORT,$USER,$PASS,OutPut->$SCROUTPUT,Status(S-Success/F-Fail)->$RUNSTATUS,Email Sent for event->$EMAILSENT"
   LOGLINE="Beg Date->$BEGDATE,Run Date->$RUNDATE,Freq->$RUNFREQ1,Env->$ENVIR1,$ENVSID,SN->$SN1,EmailAdd->$EMAILADD1,Email Subject->$EMAILSUB1,Email Body->$EMAILBODY1,Script->$SCRIPT,Output type->$OUTPUTTYPE,Condition->$CONDITION,Compare value->$COMPAREVALUE,Hostname->$HOSTNAME,Port->$PORT,$USER,OutPut->$SCROUTPUT,Status(S-Success/F-Fail)->$RUNSTATUS,Email Sent for event->$EMAILSENT"
echo "****** RAOMON  $LOGLINE" >> $RAOMLOG
   if [ $RUNSTATUS = "F" ] && [ ${CONDITION:-Fail} <> "Fail" ]  ; then
        SCRIPT2="NOT FOUND"
        #echo "$LOGLINE" | mailx -s "RAOMON Invalid Event" "$ADMINEMAIL"
        EMAILSUB1="$HN:$ENVIR1:$ENVSID:$SN1:Invalid Event"
        EMAILBODY1="$HN:$ENVIR1:$ENVSID:DB On->$HOSTNAME:$SN1:Invalid Event"
        #send_email "$ADMINEMAIL" "RAOMON Invalid Event" "$LOGLINE"
        send_email "$ADMINEMAIL" "$EMAILSUB1" "$EMAILBODY1"
   fi

   #LOGHDR=???

   echo $LOGLINE >> $RAOMDATASTOR

   ###### run the script ####################################################################################################
   fi;
done
finish_now
exit
############################################ End of Script #################################################################
###
###
########## Limitations 
#1. If the sql output is "no rows selected", it is treated as successful & no comparison is made to # given values
#   except if the condition is "Succ", this is because the output of the sql is not take, only the#  output of
#   the sqlplus command execution is taken
#2.
############################################
#Improvements
#1. Add frequency as 3M,4M,8M,9M
#2. Move BEGMIN etc variable assignment on the top
#3. 


