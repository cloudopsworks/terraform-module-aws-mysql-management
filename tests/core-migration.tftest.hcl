##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}
mock_provider "mysql" {}

variables {
  org = {
    organization_name = "cloudopsworks"
    organization_unit = "platform"
    environment_type  = "testing"
    environment_name  = "test"
  }

  direct = {
    server_name = "test-mysql"
    host        = "127.0.0.1"
    port        = 3306
    username    = "root"
    password    = "test-password"
    engine      = "mysql"
    db_name     = "mysql"
  }

  databases = {
    shared = {
      name         = "appdb"
      create       = true
      create_owner = true
      host         = "%"
      tls_option   = "NONE"
      import       = false
    }
  }

  users = {
    shared = {
      name       = "app_reader"
      grant      = "readonly"
      db_ref     = "shared"
      host       = "%"
      tls_option = "NONE"
      import     = false
    }
  }
}

run "state_compatible_child_addresses" {
  command = plan

  assert {
    condition     = length(module.db.databases) == 1
    error_message = "Managed databases must live in module.db.mysql_database.this."
  }

  assert {
    condition     = length(module.db.owner_usernames) == 1
    error_message = "Database owners must live in module.db.mysql_user.owner."
  }

  assert {
    condition     = length(module.db.user_usernames) == 1
    error_message = "Regular users must live in module.db.mysql_user.user."
  }

  assert {
    condition     = length(random_password.owner) == 1 && length(random_password.user) == 1
    error_message = "AWS must retain ownership of password generation during the state move."
  }

  assert {
    condition     = length(mysql_grant.owner) == 1 && length(mysql_grant.user_ro_tab_def_priv) == 1
    error_message = "AWS must retain the existing grant resources and keys."
  }
}
