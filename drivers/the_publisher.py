#!/usr/bin/env python

import boto3
from time import time
import sys
from datetime import datetime as dt
import json
from random import random, shuffle
from itertools import product
from string import ascii_uppercase
from ratelimiter import RateLimiter

from aws_resource_names import S3_BUCKET_NAME

# Method 2: Client.put_object()
s3 = boto3.client('s3')

run_flag = True

obj_count = 0
iter_obj_count = 0
obj_limit = 2 # number of objects per second to put
err_rate = 0.01 # what percentage of messages should be flawed, 0.1 == 10% of messages will have syntax errors
start_time = time ()
last_print_time = time ()
symbols = [''.join(i) for i in product (ascii_uppercase, repeat=4)]
shuffle (symbols)
print ("Publishing messages for {} symbols".format (len (symbols)))

message_id = 0
rate_limiter = RateLimiter(max_calls=obj_limit)

try:
    while run_flag:
        with rate_limiter:
            symbol = symbols.pop ()
            message_id += 1
            obj_name = 'data_object_msg-{}.json'.format (message_id)
            data = {'symbol': symbol, 'messageId': message_id, 'value': 10, 'objectName': obj_name, 'submissionDate': dt.now().strftime ('%d-%b-%Y %H:%M:%S'), 'author': 'the_publisher.py', 'version': 1.1}
            body = json.dumps (data)
            if random () < err_rate:
                body = body.replace ('"','',1) # if we should inject an erroneous message send malformed JSON with a syntax error
            s3.put_object(Body=body, Bucket=S3_BUCKET_NAME, Key='input/{}'.format (obj_name))
            obj_count += 1
            iter_obj_count += 1

        if iter_obj_count % (obj_limit * 10) == 0:
            print ("{}: Pushed {} objects for a total of {} objects".format (dt.now ().strftime ('%Y-%b-%d %H:%M:%S'), iter_obj_count, obj_count))
            last_print_time = time ()
            iter_obj_count = 0
except KeyboardInterrupt:
    print ("Pushed a total of {} objects; exiting...".format (obj_count))
    sys.exit (0)
