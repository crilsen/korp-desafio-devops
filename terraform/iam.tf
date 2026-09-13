data "aws_iam_policy_document" "korp_runner_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "korp_runner" {
  name               = "${var.prefixo}-runner"
  assume_role_policy = data.aws_iam_policy_document.korp_runner_assume_role.json
}

data "aws_iam_policy_document" "korp_runner_token" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = [var.github_runner_token_parameter_arn]
  }
}

resource "aws_iam_role_policy" "korp_runner_token" {
  name   = "read-runner-token"
  role   = aws_iam_role.korp_runner.id
  policy = data.aws_iam_policy_document.korp_runner_token.json
}

data "aws_iam_policy_document" "korp_loki_storage" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.loki_s3_bucket}"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${var.loki_s3_bucket}/*"]
  }
}

resource "aws_iam_role_policy" "korp_loki_storage" {
  name   = "loki-s3-storage"
  role   = aws_iam_role.korp_runner.id
  policy = data.aws_iam_policy_document.korp_loki_storage.json
}

resource "aws_iam_instance_profile" "korp_runner" {
  name = "${var.prefixo}-runner"
  role = aws_iam_role.korp_runner.name
}
