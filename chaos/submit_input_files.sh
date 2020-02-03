#!/bin/bash

for i in `seq 1 $1`;
do
    aws s3 cp ../sample_data.json s3://chaos-bucket-23e0fcb0737fba73/input/sample_data_$i.json
done
