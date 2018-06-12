BEGDATE="`date +%Y%m%d%H%M`"
BEGDAY="`date +%d`"
BEGHR="`date +%H`"
BEGMIN="`date +%M`"
BEGHRMIN="`date +%H%M`"

echo "BEGDATE,BEGDAY,BEGHR,BEGMIN,BEGHRMIN"
echo "$BEGDATE,$BEGDAY,$BEGHR,$BEGMIN,$BEGHRMIN"

echo $BEGMIN

X="2M"

a=`expr $BEGMIN % 6`
if [ $a = 0 ]
 then
    echo "YES"
 else
    echo "NO"
fi
