#!/usr/bin/env python

import sys
from datetime import datetime as dt
from time import time

import boto3
from ratelimiter import RateLimiter

from aws_resource_names import SQS_QUEUE_NAME

sqs = boto3.client("sqs")
queue_url = sqs.get_queue_url(QueueName=SQS_QUEUE_NAME)
queue_url = queue_url["QueueUrl"]

run_flag = True

obj_count = 0
iter_obj_count = 0
obj_limit = 2  # number of objects per second to get
start_time = time()
rate_limiter = RateLimiter(max_calls=obj_limit)
while run_flag:
    try:
        with rate_limiter:
            resp = sqs.receive_message(
                QueueUrl=queue_url, WaitTimeSeconds=1, MaxNumberOfMessages=obj_limit
            )
            if "Messages" in resp:
                for msg in resp["Messages"]:
                    sqs.delete_message(
                        QueueUrl=queue_url, ReceiptHandle=msg["ReceiptHandle"]
                    )
                    obj_count += 1
                    iter_obj_count += 1

        if obj_count % (obj_limit * 10) == 0:
            print(
                "{}: Retrieved {} objects for a total of {} objects".format(
                    dt.now().strftime("%Y-%b-%d %H:%M:%S"), iter_obj_count, obj_count
                )
            )
            iter_obj_count = 0
    except KeyboardInterrupt:
        print("Retrieved a total of {} objects; exiting...".format(obj_count))
        sys.exit(0)
