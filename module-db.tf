##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

module "db" {
  source    = "git::https://github.com/cloudopsworks/terraform-module-mysql-management.git?ref=v2.3.1-alpha.3"
  providers = { mysql = mysql }

  org        = var.org
  is_hub     = var.is_hub
  spoke_def  = var.spoke_def
  extra_tags = var.extra_tags

  databases   = local.mysql_databases
  owner_users = local.owner_users
  users       = local.mysql_users

  # Password generation, time-based rotation and force_reset live in the child module.
  # This module keeps only the Secrets Manager side: it reads the generated values out of
  # `owner_passwords` / `user_passwords` and stores them.
  #
  # The exception is `rotation_lambda_name`: when a rotation lambda is configured the
  # password of record is the one in Secrets Manager, so `local.owner_users` /
  # `local.mysql_users` hand the stored value over with `generate_password = false` and the
  # child generates nothing. Rotation days are then the lambda's schedule, not the child's.
  password_rotation_period = var.rotation_lambda_name == "" ? var.password_rotation_period : 0
  force_reset              = var.force_reset
  specials_in_password     = var.specials_in_password
}
