##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

output "owners" {
  description = "Map of database refs to their generated owner user, keyed by the `databases` map key. Each entry exposes the owner username, the AWS Secrets Manager secret holding its credentials, and whether that secret carries a password. Only databases with `create_owner = true` are present."
  value = {
    for key, db in var.databases : key => {
      username               = local.owner_list[key]
      credentials_secret     = aws_secretsmanager_secret.owner[key].name
      credentials_secret_arn = aws_secretsmanager_secret.owner[key].arn
      has_password           = module.db.owner_password_managed[key]
    }
    if try(db.create_owner, false)
  }
}

output "users" {
  description = "Map of user refs to their managed MySQL user, keyed by the `users` map key. Each entry exposes the username, the AWS Secrets Manager secret holding its credentials, and whether that secret carries a password."
  value = {
    for key, user in var.users : key => {
      username               = user.name
      credentials_secret     = aws_secretsmanager_secret.user[key].name
      credentials_secret_arn = aws_secretsmanager_secret.user[key].arn
      has_password           = module.db.user_password_managed[key]
    }
  }
}