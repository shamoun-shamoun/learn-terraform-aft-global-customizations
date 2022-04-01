resource "aws_ssm_parameter" "foo" {
  name  = "foo"
  type  = "String"
  value = "${data.aws_caller_identity.current.account_id}"
}