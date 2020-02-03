#!/bin/bash

rm -fr tmp_data
mkdir tmp_data

for i in `seq 1 $1`;
do
    cp sample_data.json tmp_data/sample_data_$i.json
done

aws s3 sync tmp_data s3://chaos-bucket-23e0fcb0737fba73/input/ 1>/dev/null
