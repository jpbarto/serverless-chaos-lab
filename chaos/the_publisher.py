#!/usr/bin/env python

import boto3
from time import time
from datetime import datetime as dt
import json
import os

S3_BUCKET_NAME = os.environ['S3_BUCKET']

# Method 2: Client.put_object()
s3 = boto3.client('s3')

run_flag = True

obj_count = 0
iter_obj_count = 0
obj_limit = 2 # number of objects per second to put
start_time = time ()
last_print_time = time ()
while run_flag:
    obj_name = 'data_object_{}_{}.json'.format (dt.now ().strftime ('%d%b%Y'), int(time ()*1000))
    data = {'objectName': obj_name, 'submissionDate': dt.now().strftime ('%d-%b-%Y %H:%M:%S'), 'author': 'the_publisher.py', 'version': 1.1}

    if iter_obj_count <= obj_limit * 10:
        s3.put_object(Body=json.dumps (data), Bucket=S3_BUCKET_NAME, Key='input/{}'.format (obj_name))
        obj_count += 1
        iter_obj_count += 1

    if (int(time () - start_time) % 10) == 0 and (time () - last_print_time) > 10:
        print ("{}: Pushed {} objects for a total of {} objects".format (dt.now ().strftime ('%Y-%b-%d %H:%M:%S'), iter_obj_count, obj_count))
        last_print_time = time ()
        iter_obj_count = 0
