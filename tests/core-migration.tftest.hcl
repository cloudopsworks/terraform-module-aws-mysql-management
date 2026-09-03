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

  mock_data "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:mysql-rotation"
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
    condition     = length(random_password.owner_initial) == 0 && length(random_password.user_initial) == 0
    error_message = "Without a rotation lambda the initial-password seeds must not be created; module.db owns generation."
  }

  assert {
    condition     = module.db.owner_password_managed["shared"] && module.db.user_password_managed["shared"]
    error_message = "Password-authenticated accounts must report a module-held password."
  }

  assert {
    condition     = length(mysql_grant.owner) == 1 && length(mysql_grant.user_ro_tab_def_priv) == 1
    error_message = "AWS must retain the existing grant resources and keys."
  }
}

# An account whose auth_plugin authenticates without a stored password must still be created
# and still get a secret, but that secret must carry connection metadata only.
run "iam_authenticated_accounts_store_no_password" {
  command = plan

  variables {
    users = {
      shared = {
        name       = "app_reader"
        grant      = "readonly"
        db_ref     = "shared"
        host       = "%"
        tls_option = "NONE"
        import     = false
      }
      iam = {
        name                 = "app_iam"
        grant                = "readwrite"
        db_ref               = "shared"
        auth_plugin          = "AWSAuthenticationPlugin"
        max_user_connections = 50
      }
    }
  }

  assert {
    condition     = length(module.db.user_usernames) == 2
    error_message = "An IAM-authenticated user must still be created in MySQL."
  }

  assert {
    condition     = !module.db.user_password_managed["iam"]
    error_message = "AWSAuthenticationPlugin must suppress password generation."
  }

  assert {
    condition     = module.db.user_password_managed["shared"]
    error_message = "Suppression must not leak to password-authenticated users in the same map."
  }

  assert {
    condition     = length(local.user_stored_passwords["iam"]) == 0
    error_message = "No password may be written into an IAM-authenticated user's secret payload."
  }

  assert {
    condition     = length(aws_secretsmanager_secret.user) == 2
    error_message = "The secret itself must still be created so the connection metadata is available."
  }
}

# A rotation lambda and auth_plugin accounts must coexist: the lambda rotates the accounts
# that have a password, and the ones that authenticate without one are left out entirely
# rather than being seeded with a password they could never use.
run "rotation_lambda_mixes_with_auth_plugin_accounts" {
  command = plan

  variables {
    rotation_lambda_name = "mysql-rotation"

    databases = {
      shared = {
        name         = "appdb"
        create       = true
        create_owner = true
      }
      iamdb = {
        name         = "iamdb"
        create       = true
        create_owner = true
        auth_plugin  = "AWSAuthenticationPlugin"
      }
    }

    users = {
      rotated = {
        name   = "app_reader"
        grant  = "readonly"
        db_ref = "shared"
      }
      iam = {
        name        = "app_iam"
        grant       = "readwrite"
        db_ref      = "shared"
        auth_plugin = "awsauthenticationplugin" # matched case-insensitively
      }
      hashed = {
        name        = "app_hashed"
        grant       = "readonly"
        db_ref      = "shared"
        auth_string = "*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19"
      }
    }
  }

  assert {
    condition     = length(module.db.user_usernames) == 3 && length(module.db.owner_usernames) == 2
    error_message = "Every account must still be created in MySQL regardless of auth_plugin."
  }

  assert {
    condition     = length(random_password.user_initial) == 1 && keys(random_password.user_initial)[0] == "rotated"
    error_message = "Only the password-authenticated user may be seeded; a seed for an auth_plugin account is unusable."
  }

  assert {
    condition     = length(random_password.owner_initial) == 1 && keys(random_password.owner_initial)[0] == "shared"
    error_message = "Only the password-authenticated owner may be seeded."
  }

  assert {
    condition     = length(aws_secretsmanager_secret_rotation.user) == 1 && length(aws_secretsmanager_secret_rotation.owner) == 1
    error_message = "Rotation must cover the password-authenticated accounts only, not fail the plan for the others."
  }

  assert {
    condition     = length(aws_secretsmanager_secret.user) == 3 && length(aws_secretsmanager_secret.owner) == 2
    error_message = "Every account keeps its secret so connection metadata stays available."
  }

  assert {
    condition = (
      length(local.user_stored_passwords["iam"]) == 0
      && length(local.user_stored_passwords["hashed"]) == 0
      && length(local.owner_stored_passwords["iamdb"]) == 0
    )
    error_message = "No password may be written for an account that authenticates without one."
  }
}
