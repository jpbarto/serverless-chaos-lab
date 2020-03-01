#########################################
#
# Chaos-prepared DynamoDB database
#
#########################################

resource "aws_dynamodb_table" "chaos_data_table" {
  name           = "chaos-data-${random_id.chaos_stack.hex}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "symbol"
  range_key       = "entryType"

  attribute {
    name = "symbol"
    type = "S"
  }

  attribute {
    name = "entryType"
    type = "S"
  }
}