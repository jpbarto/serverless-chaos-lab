#!/bin/bash

rm -fr tmp_data
mkdir tmp_data

for i in `seq 1 $2`;
do
    cp sample_data.json tmp_data/sample_data_$i.json
done

aws s3 sync tmp_data s3://$1/input/ 1>/dev/null
