# https://www.terraform.io/downloads.html

provider "aws" {
    region = "eu-west-2"
}

resource "aws_lambda_function" "lambdae86dd11" {
    filename = "CHANGEME.zip"
    function_name = "ChaosTransformer"
    handler = "index.handler"
    memory_size = 128
    role = "arn:aws:iam::776347453069:role/service-role/ChaosTransformer-role-2m51zlnm"
    runtime = "nodejs12.x"
    timeout = 3
    dead_letter_config {
        
    }

    tracing_config {
        mode = "PassThrough"
    }

}
