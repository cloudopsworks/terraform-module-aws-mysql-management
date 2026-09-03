##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Generation and time-based rotation of user passwords belong to module.db; see
# module-db.tf. Only the rotation-lambda seed remains here, because under a lambda the
# password of record lives in Secrets Manager and this resource just supplies the first one.
# Not created for accounts whose auth_plugin authenticates without a stored password — the
# seed would be as unusable as any other password for them.
resource "random_password" "user_initial" {
  for_each         = local.user_rotation_managed
  length           = 25
  special          = var.specials_in_password
  override_special = "=_-+@~#"
  min_upper        = 2
  min_special      = var.specials_in_password ? 2 : 0
  min_numeric      = 2
  min_lower        = 2
}
