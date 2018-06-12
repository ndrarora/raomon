set -x
X=">"
Y=4
T=C
V1=6

if ! [ `expr $V1` "$X" `expr $Y` ]; 
then
echo "Found"
else
echo " Not found"
fi
