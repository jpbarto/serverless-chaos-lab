#########################################
#
# Chaos-prepared DynamoDB database
#
#########################################

resource "aws_dynamodb_table" "chaos_data_table" {
  name           = "chaos-data-${random_id.chaos_stack.hex}"
  billing_mode   = "PAY_PER_REQUEST"
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
