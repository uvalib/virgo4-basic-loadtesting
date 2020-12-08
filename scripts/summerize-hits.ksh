if [ $# -ne 1 ]; then
   echo "use: $(basename $0) <input file>"
   exit 1
fi

INFILE=$1

if [ ! -f $INFILE ]; then
   echo "$INFILE does not exist or is not readable"
   exit 1
fi

echo "Times in miliseconds"
echo "min,	max,	mean,		midian"
cat $INFILE | grep "==> hits" | awk '{print $7}' | tr -d "," | sort | datamash min 1 max 1 mean 1 median 1

exit 0
