# Chaos Engineering for Serverless Technologies lab

## Overview

The following series of workshops will walk you through the process of creating a Chaos experiment to test the resiliency of your Serverless architecture.  You will establish the steady state of your application, perturb the application by injecting faults into the environment, and then observe how the application responds to the turbulence.  You will then apply corrections to your architecture to allow it to better perform in turbulent conditions.  

## Table of Contents

  1. [Getting Started](#getting-started)
  1. [Chaos Engineering](#chaos-engineering)
  1. [Prerequisites](#prerequisites)
  1. [Labs](#labs)
  1. [FAQ](#faq)

## Getting Started

Get started learning about chaos engineering by cloning this repository and following along in the reading material.  Please note that this repository is focused on learning-by-doing and so the amount of reading hosted here about chaos engineering is minimal.  However there are a numerous number of locations online to learn more about chaos engineering.  To find out more please visit:

- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [The Chaos Engineering Collection](https://medium.com/@adhorn/the-chaos-engineering-collection-5e188d6a90e2), by [Adrian Hornsby](https://medium.com/@adhorn)
 - [Chaos Engineering: why breaking things should be practiced](https://www.youtube.com/watch?v=4FuCTXgufQg), by Adrian Hornsby
 - [Performing Chaos in a Serverless World](https://www.youtube.com/watch?v=vbyjpMeYitA), by [Gunnar Grosch](https://grosch.se/)

 Now let's continue by starting with a brief overview of chaos engineering and then deploying your serverless application in Lab 1.

## Chaos Engineering

> "Chaos Engineering is the discipline of experimenting on a system in order to build confidence in the system's ability to withstand turbulent conditions in production."
>
> -- [Princple of Chaos Engineering](https://principlesofchaos.org/)

Chaos engineering as a concept was developed by Greg Orzell in 2011 during his time working with Netflix ([Wikipedia](https://en.wikipedia.org/wiki/Chaos_engineering)).  The practice is designed to test distributed, complex systems in order to assess how they cope under unusual operating conditions.  

Even when all of the individual services in a distributed system are functioning properly, the interactions between those services can cause unpredictable outcomes.  Unpredictable outcomes, compounded by rare but disruptive real-world events that affect production environments, make these distributed systems inherently chaotic.

Chaos engineering uses experiments to test the impact of potential failure modes on a distributed, complex application.  To start you must first establish the steady state for an application.  The steady state should be a quantifiable, measurable state of an application which is achieved when the application is delivering to your stated service level objectives.  Once the steady state is determined develop experiments to introduce chaos or perturbations into the system, with the hypothesis that this disruption will not affect the steady state of the application, that the system will cope with the disruption.  During the experiment's execution observe the application and, if the hypothesis is found to be false, use your observations to improve the system to better cope with the turbulent conditions created.

There are numerous tools and techniques for conducting chaos experiments on different types of architecture.  What follows are a set of labs to use two such tools to develop and execute chaos experiments on a serverless ETL application.  

Let's now download and deploy a serverless application that we can iterate on and improve through the process of chaos engineering.

## Prerequisites

> Note: If you are running this from an AWS Cloud9 IDE you will not have all of the permissions you need to deploy this architecture.  Disable the AWS managed temporary credentials and [configure an EC2 instance profile](https://docs.aws.amazon.com/cloud9/latest/user-guide/credentials.html#credentials-temporary) for your Cloud9 system.

1. Clone the repository locally.

    ```bash
    $ git clone https://github.com/jpbarto/serverless-chaos-lab.git
    $ cd serverless-chaos-lab
    ```

    ### Repository Contents
    ```shell
    ├── README.md                       # Introduction (this doc)
    ├── docs                            # Lab guides
    │   ├── images
    │   ├── lab_1_serverless_etl.md
    │   ├── lab_2_inject_fault.md
    │   ├── lab_3_chaos_experiment.md
    │   └── lab_4_chaos_experiment_2.md
    ├── drivers
    │   ├── the_publisher.py            # Publication driver for pipeline
    │   └── the_subscriber.py           # Subscription driver for pipeline
    └── src
    │   ├── lambda.js                   # NodeJS code for ETL Lambda
    │   └── package.json                # ETL dependencies
    └── terraform                       # Terraform templates for a Serverless ETL pipeline
        ├── application.tf              # deploys the Lambda function
        ├── database.tf                 # deploys a DynamoDB table
        ├── filestore.tf                # creates the S3 bucket
        ├── messaging.tf                # creates a collection of queues and topics
        ├── monitoring.tf               # creates a CloudWatch Dashboard
        ├── outputs.tf                  # creates identifier files for the drivers and chaos experiments
        └── template.tf                 # wrapper around the above
    ```

1. If Terraform is not already installed, [install HashiCorp Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) in your local environment.
   > Note: These labs require Terraform v12 or higher.
 
 
   If you are using an [AWS Cloud9 IDE](https://aws.amazon.com/cloud9/) instance the following should install Terraform for you:
    ```bash
    $ sudo yum install -y yum-utils
    $ sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    $ sudo yum -y install terraform
    ```

1. To package the Lambda function, Terraform will need to use NPM and NodeJS.  If NodeJS and NPM are not already installed please [install them](https://nodejs.org/en/download/) into your environment.

    On an AWS Cloud9 IDE use the following:
    ```bash
    $ sudo yum -y install npm
    ```

1. In these labs you will use the [ChaosToolkit](https://chaostoolkit.org/) to script your chaos experiments.  [Install the ChaosToolkit](https://docs.chaostoolkit.org/reference/usage/install/) using `pip3`:

    ```bash
    $ sudo pip3 install chaostoolkit chaostoolkit-aws
    ```

## Labs

With the above completed you're now ready to embark on a series of hands-on labs to learn about chaos engineering.  Let's get started!

1. [Deploy a serverless ETL pipeline](docs/lab_1_serverless_etl.md)
    
    Using Hashicorp Terraform deploy a serverless pipeline for converting JSON documents to CSV.  In this lab you will also provide a publisher of JSON documents to this pipeline and simulate a consumer of the pipeline in order to generate metrics data that is viewable using a CloudWatch metrics dashboard.
    
    (Key objective: observe the architecutre and observe how the pipeline performs during standard operation, review the Lambda function, define SLO)

1. [Inject fault into the pipeline](docs/lab_2_inject_fault.md)

    In this lab you will modify the Lambda function to incorporate the failure-lambda NodeJS package.  With the package enabled you will test the function to observe how it responds to changes in the package's configuration.

    (Key objective: modify Lambda function and inject failure, observe functions behavior during injected failures)

1. [Author a chaos experiment](docs/lab_3_chaos_experiment.md)
    
    In this lab you will learn how to create a chaos experiment and execute it using the open source Chaos Toolkit.  In executing the experiment you will uncover a flaw in the architecture's design.  After correcting the flaw you should be able to re-run the experiment and see that steady state is maintained.

    (Key objective: Using Chaos Toolkit define an experiment and execute to inject latency, fix the architecture to maintain SLO in the face of latency)

1. [Simulate a serverless service disruption](docs/lab_4_chaos_experiment_2.md)

    In this lab you will introduce a different type of fault to simulate a permissions issue or a service outtage.

    (Key objective: Using Chaos Toolkit define an experiment and execute it to simulate a service disruption.)

## FAQ
1. **When running the Chaos Toolkit the probes fail even without disrupting the system, what is happening?**

    Some of the probes depend upon your system's local `date` command in order to obtain a datetime stamp to query CloudWatch metrics.  The current command being used assumes a Linux-based environment.  However if you are on a BSD-based environment, such as OSX, you will need to alter the `date` commands in your experiment JSON.  Replace `date --date '5 min ago'` with `date -v -5M`.

    For example:

    ```json
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
                    "arguments": "cloudwatch get-metric-data --metric-data-queries file://steadyStateFlight.json --start-time `date --date '5 min ago' -u '+%Y-%m-%dT%H:%M:%SZ'` --end-time `date -u '+%Y-%m-%dT%H:%M:%SZ'` --query 'MetricDataResults[0].Values[0]'"
                }
            },
    ```
  
1. **My `date` command is correct but the Chaos Toolkit probes still fail without disruption, what is happening?**

    It's unclear why but some configurations of the Python ecosystem and AWS CLI seem to have a detrimental effect on the `get-metrics-data` call to AWS CloudWatch metrics.  When querying the API an empty data set is returned.  This has been known to be the case on OSX Catalina with AWS CLI v1 and v2.

1. **After a failed experiment, I fix the issue and rerun the experiment but it still fails, what is happening?**

    After a failed experiment the Chaos Toolkit will rollback changes to allow the system to resume its steady state.  However the system will not return to steady state instantaneously, it can take as much as 15 min for the system to return to its steady state and be ready for more testing.  You *may* be able to accelerate this time to recovery by purging the SQS queues.

1. **The Chaos Toolkit isn't executing properly but I don't know why, how do I troubleshoot?**

    The Chaos Toolkit will write detailed output to `chaostoolkit.log` and a summary of the metrics it tracks to `journal.json`.  You can look through these files for any clues as to what went wrong.  You can also specify the `--verbose` flag upon execution to get more detailed output to the console: `chaos --verbose run experiment.json`.
