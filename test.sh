#!/bin/bash

make nuke

make assembly

make

# Now we shall compare the two writeback files. 
if cmp -s writeback.out ./ground_truths/mult_no_lsq/writeback.out
then
    :
else
    echo "The new design has failed on the test script $file"
    echo "@@@Failed"
    echo "Aborting."
    exit
fi
## Now we shall compare the program outputs. First we need to extract the lines starting
## with @@@ from the file
grep "@@@" program.out > program_extracted.out
grep "@@@" ./ground_truths/mult_no_lsq/program.out > ground_truth_extracted.out
## COMPARISON

# Now we shall compare the two writeback files. 
if cmp -s program_extracted.out ground_truth_extracted.out
then
    :
else
    echo "The new design has failed on the test script $file"
    echo "@@@Failed"
    echo "Aborting."
    exit
fi

echo "@@@Passed"
