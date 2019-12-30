resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = "${aws_iam_role.vpc_flow_logs.arn}"
  log_destination = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.VPC.id}"
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name = "${var.modulename}_vpc_flow_logs"
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.modulename}_vpc_flow_logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.modulename}_vpc_flow_logs"
  role = "${aws_iam_role.vpc_flow_logs.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}