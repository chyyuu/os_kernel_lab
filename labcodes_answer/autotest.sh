#!/bin/bash

# change working dir to where this script resides in
pushd `dirname "$0"` > /dev/null

if [ -n "$1" ]; then
    RESULT_SAVETO=""
fi
BASE_COMMIT=1d8c85670d03ce745e32bbc57147835b210fe560
if [ -n "$2" ] && git log $2 > /dev/null 2>&1; then
    BASE_COMMIT=$2
elif ! git log $BASE_COMMIT > /dev/null 2>&1; then
    echo "No valid base commit found."
    exit 0
fi
LABS=`git diff $BASE_COMMIT --stat | grep -o "lab[1-8]" | sort | uniq`
COMMIT=`git rev-parse HEAD`

if [ "$LABS" = "" ]; then
    echo "No updated lab found. Skip."
    exit 0
fi

failed=0

pwd=`pwd`
summary=$pwd/.score_summary

echo -n > $summary
for lab in $LABS; do
    pushd $lab > /dev/null
    if ! make grade > .score 2>&1; then
        failed=`echo $lab | grep -o [0-9]`
    fi
    if [ -n "$RESULT_SAVETO" ]; then
	mkdir -p $RESULT_SAVETO/$COMMIT/$lab
	mv .score .score_orig
	../tools/split_score_log.py .score_orig > .score
	for i in .*.log .*.error; do
	    cp $i $RESULT_SAVETO/$COMMIT/$lab/${i#.}
	done
    fi
    score=`egrep -o "Score: [0-9]+/[0-9]+" .score`
    echo "$lab $score" >> $summary
    make clean > /dev/null
    popd > /dev/null
done

echo "Labs with changes detected: " $LABS
echo
echo "============================== Summary =============================="
cat $summary
rm $summary
echo

for lab in $LABS; do
    echo "================================ $lab ==============================="
    cat $lab/.score
done

find . -name '.*' -delete

popd > /dev/null

exit $failed
