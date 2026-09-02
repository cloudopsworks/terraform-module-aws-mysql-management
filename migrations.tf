##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Retain these declarations permanently. They preserve all for_each instances
# because the destination resources use the same keys as the former resources.
moved {
  from = mysql_database.this
  to   = module.db.mysql_database.this
}

moved {
  from = mysql_user.owner
  to   = module.db.mysql_user.owner
}

moved {
  from = mysql_user.user
  to   = module.db.mysql_user.user
}

# Password generation moved to module.db, which declares the same `random_password` and
# `time_rotating` resources this module used to duplicate. The destination `for_each` keys
# are unchanged, and module.db writes `keepers` only while `force_reset` is true, so the
# generated values are adopted in place rather than replaced.
#
# These addresses only ever hold instances when `rotation_lambda_name` is empty; under a
# rotation lambda both sides are empty and the blocks are inert. `random_password.owner_initial`
# and `random_password.user_initial` stay in this module — they seed the first Secrets Manager
# version for the rotation-lambda path and have no counterpart in module.db.
moved {
  from = random_password.owner
  to   = module.db.random_password.owner
}

moved {
  from = random_password.user
  to   = module.db.random_password.user
}

moved {
  from = time_rotating.owner
  to   = module.db.time_rotating.owner
}

moved {
  from = time_rotating.user
  to   = module.db.time_rotating.user
}

# Import blocks must remain in this root module. Their destinations follow the
# moved resources so existing and newly imported configurations share addresses.
import {
  for_each = {
    for key, db in var.databases : key => db if try(db.create, true) && try(db.import, false)
  }
  to = module.db.mysql_database.this[each.key]
  id = each.value.name
}

import {
  for_each = {
    for key, db in var.databases : key => db if try(db.import, false) && try(db.create_owner, false)
  }
  to = module.db.mysql_user.owner[each.key]
  id = local.owner_list[each.key]
}

import {
  for_each = {
    for key, user in var.users : key => user if try(user.import, false)
  }
  to = module.db.mysql_user.user[each.key]
  id = each.value.name
}
