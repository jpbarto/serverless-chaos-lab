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

1. Create your experiment's skeleton

    Chaos Toolkit experiments are defined as JSON files.  A detailed breakdown is available [online](https://docs.chaostoolkit.org/reference/api/experiment/) but for now create the beginnings of your experiment by creating a file named `experiment_1.json` with the following contents:

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

1. Define a steady state

    Take a moment and consider what you think would be good, measurable indicators that demonstrate the ETL pipeline is executing as expected.  Would you measure the number of errors produced?  How many errors would you accept before notifying someone and considering the system to be in an error state?

    Would you measure how many messages are processed per second?  If the system encountered a slowdown and files were processed in 5 minutes rather than 5 seconds, is this breaching any SLAs you maintain with your clients?

    What defines a steady state for any given application is very specific to the application itself.  But for our purpose today we will measure three aspects of the architecture:

    1. The number of errors experienced by SNS
    1. The % of how many messages are currently being processed by the pipeline
    1. The % of how many messages have experienced an error and are in the dead letter queue

    To mesaure the number of SNS errors we can simply create a probe which queries AWS CloudWatch.

    To measure the other two we will still use CloudWatch as our data source but we will use some simple mathematics to calculate the percentages we need to demonstrate steady state.  There should be two files in your chaos folder, one for the in flight message calculation and one for the error rate calculation.  Have a look at their source but we will pass them to the AWS CLI as another probe to be used by Chaos Toolkit to evaluate our steady state.

    All three probes are defined below.  Update the `experiment_1.json` file by adding this `probes` definition to the `steady-state-hypothesis` of your experiment.

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
                "range": [0.0, 50.0],
                "target": "stdout"
            },
            "provider": {
                "type": "process",
                "path": "aws",
                "arguments": "cloudwatch get-metric-data --metric-data-queries file://steadyStateFlight.json --start-time `date -v-5M '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
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
                "arguments": "cloudwatch get-metric-data --metric-data-queries file://steadyStateError.json --start-time `date -v-5M '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
            }
        }
    ]
    ```

Update the Terraform code to change the runtime to a value of 2 minutes.
reapply the terraform.

## Chaos Experiment

```json
{
  "version": "1.0.0",
  "title": "Delay should not impact processing",
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
      "title": "Services are all available and healthy",
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
                  "range": [1.0, 6.0],
                  "target": "stdout"
              },
              "provider": {
                  "type": "process",
                  "path": "aws",
                  "arguments": "cloudwatch get-metric-data --region eu-west-2 --metric-data-queries file://steadyStateFlight.json --start-time `date -v-5M '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
              }
          },
          {
              "type": "probe",
              "name": "normal-error-rates",
              "tolerance": {
                  "type": "range",
                  "range": [0.0, 2.0],
                  "target": "stdout"
              },
              "provider": {
                  "type": "process",
                  "path": "aws",
                  "arguments": "cloudwatch get-metric-data --region eu-west-2 --metric-data-queries file://steadyStateError.json --start-time `date -v-5M '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
              }
          }
      ]
  },
  "method": [
      {
          "type": "action",
          "name": "Enable Lambda failure: LATENCY",
          "provider": {
              "type": "process",
              "path": "aws",
              "arguments": "ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": true, \"failureMode\": \"latency\", \"rate\": 0.5, \"minLatency\": 3000, \"maxLatency\": 4000, \"exceptionMsg\": \"Exception message!\", \"statusCode\": 404, \"diskSpace\": 100}'"
          },
          "pauses": {
              "after": 360
          }
      }
  ],
  "rollbacks": [
      {
          "type": "action",
          "name": "Disable Lambda failures",
          "provider": {
              "type": "process",
              "path": "aws",
              "arguments": "ssm put-parameter --name failureLambdaConfig --type String --overwrite --value '{\"isEnabled\": false, \"failureMode\": \"latency\", \"rate\": 0.5, \"minLatency\": 30, \"maxLatency\": 40, \"exceptionMsg\": \"Exception message!\", \"statusCode\": 404, \"diskSpace\": 100}'"
          }
      }
  ]
}
```