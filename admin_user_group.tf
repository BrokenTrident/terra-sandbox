resource "aws_iam_group" "administrators" {
  name = "Administrators"
  path = "/"
}

data "aws_iam_policy" "administrator_access" {
  name = "AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "administrators" {
  group      = aws_iam_group.administrators.name
  policy_arn = data.aws_iam_policy.administrator_access.arn
}

resource "aws_iam_user" "admin" {
  # checkov:skip=CKV2_AWS_22: ADD REASON
  name = "admin-user"
}

resource "aws_iam_user_group_membership" "devstream" {
  user   = aws_iam_user.admin.name
  groups = [aws_iam_group.administrators.name]
}

resource "aws_iam_user_login_profile" "administrator" {
  user                    = aws_iam_user.admin.name
  password_reset_required = true
}

output "password" {
  value     = aws_iam_user_login_profile.administrator.password
  sensitive = true
}
