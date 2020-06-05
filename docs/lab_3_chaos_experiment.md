# Lab 3: Your first Chaos Experiment

## Objective

In this lab you will learn about [Chaos-Toolkit](https://chaostoolkit.org/) and script it to test your serverless architecture.  You will cover how to design a chaos experiment and then put it into practice to improve your ETL pipeline.

## Chaos-Toolkit

The [Chaos Toolkit](https://chaostoolkit.org/) aims to be the simplest and easiest way to explore building your own Chaos Engineering Experiments. It also aims to define a vendor and technology independent way of specifying Chaos Engineering experiments by providing an Open API.

It uses a declaritive and extensible format for specifying and scripting chaos experiments.  This allows you to automate chaos engineering and incorporate experiments into your CI/CD pipelines.

The toolkit also has been [extended](https://chaostoolkit.org/extensions) to allow it to support, out of the box, the ability to interact with major cloud computing providers, Kubernetes, Spring and Spring Boot, and many others.  

To get started learning more about Chaos Toolkit please visit their [documentation](https://docs.chaostoolkit.org/).

During this lab you will define your first chaos experiment to improve your serverless architecture.  As part of this you will define a *steady state hypothesis* which defines how the system will measure whether the ETL pipeline is behaving normally.  You will also define a *method* to inject failures into the architecture.  Chaos Toolkit will begin by evaluating the steady state of your architecture, provided that the architecture passes, the toolkit will then execute your method.  After the chaos has been injected the toolkit will re-evaluate the steady state and report whether the system performed as expected or if an error was detected.

## Failure modes

Take a moment and consider the many ways that your ETL architecture could go wrong.  What sort of adverse conditions can you imagine that may affect the pipeline?  What effect would they have?  How would you measure the impact of these effects and how would you define whether your pipeline was still successful even if impaired?

## Your first experiment

> Note: Ensure that the drivers are still running and applying a load to your application.  The chaos experiments will rely on the drivers to demonstrate the ETL pipeline's ability to perform in turbulent conditions.

1. Prepare for your first experiment

    The Chaos Toolkit will need to interact with your architecture and so you will need to give it the names of components such as your Lambda function and SQS queues.  These have been exported by Terraform from the first lab and can be found in the `chaos/aws_resource_names.sh` file.  If you inspect the file you will see that it defines a number of environment variables.  Let's change into the `chaos` directory and source the environment variables to get started.

    ```bash
    $ cd chaos
    $ source aws_resource_names.sh
    ```

## Define the experiement

1. Create your experiment's skeleton

    Chaos Toolkit experiments are defined as JSON files.  A detailed breakdown is available [online](https://docs.chaostoolkit.org/reference/api/experiment/) but for now create the beginnings of your experiment by creating a file named `exp_1-minor_delay.json` with the following contents:

    ```json
    {
        "version": "1.0.0",
        "title": "Minor delay should not impact processing",
        "description": "Inject latency into Lambda function execution and ensure files are still processed.",
        "tags": [
            "serverless",
            "cloudnative",
            "etl"
        ],
        "configuration": {
            "s3_bucket": {
                "type": "env",
                "key": "S3_BUCKET_NAME"
            },
            "sns_topic": {
                "type": "env",
                "key": "SNS_TOPIC_NAME"
            },
            "lambda_function": {
                "type": "env",
                "key": "LAMBDA_FUNCTION_NAME"
            }
        },
        "steady-state-hypothesis": {
            "title": "System operating within norms",
            "probes": [
            ]
        },
        "method": [
        ],
        "rollbacks": [
        ]
    }
    ```

    A lot of the above is boiler plate and placeholders which will soon be completed in the steps to follow.  One comment regarding the `configuration` section, it pulls in the environment variables defined in step 1 so they can be referenced in the rest of the experiment definition.  For more about the `configuration` section please see the [documentation](https://docs.chaostoolkit.org/reference/api/experiment/#configuration).

1. Define a steady state

    Take a moment and consider what you think would be good, measurable indicators that demonstrate the ETL pipeline is executing as expected.  Would you measure the number of errors produced?  How many errors would you accept before notifying someone and considering the system to be in an error state?

    Would you measure how many messages are processed per second?  If the system encountered a slowdown and files were processed in 5 minutes rather than 5 seconds, is this breaching any SLAs you maintain with your clients?

    What defines a steady state for any given application is very specific to the application itself.  But for our purpose today we will measure three aspects of the architecture:

    1. The number of errors experienced by SNS
    1. The % of how many messages are currently being processed by the pipeline
    1. The % of how many messages have experienced an error and are in the dead letter queue

    To mesaure the number of SNS errors we can simply create a probe which queries AWS CloudWatch.

    To measure the other two we will still use CloudWatch as our data source but we will need some simple mathematics to calculate the percentages that demonstrate steady state.  There should be two files in your chaos folder, one for the in flight message calculation and one for the error rate calculation.  Have a look at their source but we will pass them to the AWS CLI as another probe to be used by Chaos Toolkit to evaluate our steady state.

    All three probes are defined below.  Update the `exp_1-minor_delay.json` file by adding this `probes` definition to the `steady-state-hypothesis` of your experiment.

    ```json
    "probes": [
        {
            "type": "probe",
            "name": "zero-sns-errors",
            "tolerance": 0,
            "provider": {
                "type": "python",
                "module": "chaosaws.cloudwatch.probes",
                "func": "get_metric_statistics",
                "arguments": {
                    "namespace": "AWS/SNS",
                    "metric_name": "NumberOfNotificationsFailed",
                    "dimension_name": "TopicName",
                    "dimension_value": "${sns_topic}",
                    "statistic": "Sum",
                    "duration": 900
                }
            }
        },
        {
            "type": "probe",
            "name": "messages-in-flight",
            "tolerance": {
                "type": "range",
                "range": [0.0, 80.0],
                "target": "stdout"
            },
            "provider": {
                "type": "process",
                "path": "aws",
                "arguments": "cloudwatch get-metric-data --metric-data-queries file://steadyStateFlight.json --start-time `date --date '5 min ago' '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
            }
        },
        {
            "type": "probe",
            "name": "normal-error-rates",
            "tolerance": {
                "type": "range",
                "range": [0.0, 5.0],
                "target": "stdout"
            },
            "provider": {
                "type": "process",
                "path": "aws",
                "arguments": "cloudwatch get-metric-data --metric-data-queries file://steadyStateError.json --start-time `date --date '5 min ago' '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
            }
        }
    ]
    ```

1. Evaluate the steady state

    You now have the beginnings of your experiment.  Execute Chaos Toolkit with your definition and watch its output as it assesses the steady state of your application.

    ```bash
    $ chaos run exp_1-minor_delay.json
    ```

    You will notice that the Chaos Toolkit evaluates all 3 of the probes and reports whether they fail or succeed.  With the steady state satisfied it then moves on to the actions defined.  Finding none defined it re-evaluates steady state, reports that all is well and then exits.

    Let's change that.

## Execute your experiment

1. Introduce some chaos

    The [method section](https://docs.chaostoolkit.org/reference/api/experiment/#method) of an experiment defines the step(s) to take in order to introduce turbulence into the system.  The method section is a list of actions and probes which you define.  

    Lets now introduce a minor latency of 3 to 5 seconds to the Lambda function.

    Update your experiment definition with the following action.  It will modify the configuration parameter for the failure-lambda library causing the Lambda function to, 50% of the time, take 3 to 5 seconds longer to execute.  After modifying the Lambda functions configuration the system will pause for 5 min before re-evaluating the steady state of the application.

   ```json
   "method": [
       {
           "type": "action",
           "name": "Enable Lambda failure: LATENCY",
           "provider": {
               "type": "process",
               "path": "aws",
               "arguments": "ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": true, \"failureMode\": \"latency\", \"rate\": 0.5, \"minLatency\": 3000, \"maxLatency\": 5000}'"
           },
           "pauses": {
               "after": 360
           }
       }
   ],
   ``` 

1. Experiment responsibly

    When the experiment has completed you will want to remove the turbulence you introduced into the system so that your application can resume normal operation. The [rollbacks section](https://docs.chaostoolkit.org/reference/api/experiment/#rollbacks) is designed to return the application to its initial state after the experiment has completed.

    Enter the following rollback section in order to disable the failure-lambda package:

    ```json
    "rollbacks": [
        {
            "type": "action",
            "name": "Disable Lambda failures",
            "provider": {
                "type": "process",
                "path": "aws",
                "arguments": "ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": false}'"
            }
        }
    ]
    ```

1. Re-run your experiment

    So at this point you have configured an experiment which defines your steady state, the actions needed to introduce chaos, and the actions needed to rollback and revert to the initial state.  Now re-run your experiment and observe the results.

    ```bash
    $ chaos run exp_1-minor_delay.json
    ```

    After updating the failure-lambda configuration the Chaos Toolkit will wait 5 min to allow the system time to respond to the disruption.  It should fail citing too high an error rate, rolling back the changes to resume normal operations.

## What has been learned?

1. Enhance the system

    The simple introduction of 3 to 5 seconds of latency caused a huge spike in the error rate of the application.  Why would such a small latency cause such a huge issue?  How can we make the system more resilient to this latency?

    Use [CloudWatch Logs Insights](https://console.aws.amazon.com/cloudwatch/home?#logs-insights:queryDetail=~(end~0~start~-3600~timeType~'RELATIVE~unit~'seconds~editorString~'filter*20*40type*20*3d*20*22REPORT*22*20*7c*0afields*20*40requestId*2c*20*40billedDuration*20*7c*0asort*20by*20*40billedDuration*20desc~isLiveTail~false~queryId~'363f4d7c-5725-4efd-9f64-99d93da45f1f~source~)) and the `Monitoring` tab of your function on the [AWS Lambda console](https://console.aws.amazon.com/lambda/home?#/functions) to dive into the logs and metrics data regarding your Lambda function.  What do you notice about the Lambda function that may explain the error rate?  How is the increased latency reflected in the data you have about the function's performance?

    You should notice that the average function duration is less thatn 500 milliseconds but then peaks at 3000 milliseconds.  But if the latency was as much as 5 seconds, why is that not reflected?  A closer look at the function's configuration will reveal a `Timeout` of 3 seconds, hence the function was being terminated after 3 seconds of execution, hence the increased error rate.

    To correct this, update the Terraform `application.tf` and set the `timeout` value for the `aws_lambda_function` resource to have a value of 120 seconds.  With this file changed, reapply the Terraform code to push the change.

    ```bash
    $ cd ../terraform
    $ terraform apply
    ```

    The `Timeout` of the Lambda function should now have a value of 2 minutes.

1. Re-re-run your experiment

    With the runtime of the Lambda function updated re-run your chaos experiment to ensure that the system is now able to cope with the minor latency.

    ```bash
    $ cd ../chaos
    $ chaos run exp_1-minor_delay.json
    ```

## Summary

In this lab you created your first chaos experiment using the Chaos Toolkit.  You injected latency into the Lambda function which processes incoming JSON file which uncovered an inability of the Lambda's configuration to cope with a minor latency.  To fix the issue you extended the Lambda's runtime to allow for 2 minutes of execution.

Let's now [define another experiment](lab_4_chaos_experiment_2.md) to continue testing the application.
