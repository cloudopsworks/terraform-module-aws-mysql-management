##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

module "db" {
  source    = "git::https://github.com/cloudopsworks/terraform-module-mysql-management.git?ref=v2.3.0"
  providers = { mysql = mysql }

  org        = var.org
  is_hub     = var.is_hub
  spoke_def  = var.spoke_def
  extra_tags = var.extra_tags

  databases   = local.mysql_databases
  owner_users = local.owner_users
  users       = local.mysql_users

  # AWS Secrets Manager and the existing random/time resources retain password
  # lifecycle ownership. Every child user receives an external password.
  password_rotation_period = 0
  force_reset              = false
}
