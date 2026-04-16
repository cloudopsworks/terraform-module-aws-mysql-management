##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

## Users definition - YAML format
# users:
#   <user_ref>:
#     name: "user_name"          # (Required) The name of the user to be created.
#     grant: "readwrite"         # (Required) Grant type for the user. Possible values: owner, readwrite, readonly.
#     db_ref: "db_ref"           # (Optional) Reference to the database this user is associated with. Defaults to server's default dbname.
#     database_name: "dbname"    # (Optional) Explicit name of the database this user is associated with. Defaults to server's default dbname.
#     host: "%"                  # (Optional) The source host for the user. Defaults to "%".
#     tls_option: "NONE"         # (Optional) The TLS option for the user. Defaults to "NONE".
#     import: false              # (Optional) Whether to import the user if it already exists. Defaults to false.
variable "users" {
  description = "Users and user attributes - see docs for example"
  type        = any
  default     = {}
}

## Roles definition - YAML format
# roles:
#   <role_ref>:
#     name: "role_name"          # (Required) The name of the role to be created.
#     db_ref: "db_ref"           # (Optional) Reference to the database this role is associated with.
#     database_name: "dbname"    # (Optional) Explicit name of the database this role is associated with. Defaults to "*".
#     table_name: "*"            # (Optional) Name of the table this role is associated with. Defaults to "*".
#     grant_option: false        # (Optional) If the role has grant option. Defaults to false.
#     grants:                    # (Optional) List of grants for the role. Defaults to ["ALL PRIVILEGES"].
#       - "SELECT"
#       - "INSERT"
#     import: false              # (Optional) Whether to import the role if it already exists. Defaults to false.
variable "roles" {
  description = "Roles and role attributes - see docs for example"
  type        = any
  default     = {}
}

## Databases definition - YAML format
# databases:
#   <db_ref>:
#     name: "database_name"      # (Required) The name of the database to be created.
#     create: true               # (Optional) Whether to create the database. Defaults to true.
#     create_owner: false        # (Optional) Whether to create a dedicated owner user for this database. Defaults to false.
#     owner: "owner_name"        # (Optional) Name of the owner of the database. Defaults to <db_name>_ow.
#     default_character_set: "utf8mb4" # (Optional) Character set of the database. Defaults to "utf8mb4".
#     default_collation: "utf8mb4_general_ci" # (Optional) Collation of the database. Defaults to "utf8mb4_general_ci".
#     host: "%"                  # (Optional) The source host for the owner user. Defaults to "%".
#     tls_option: "NONE"         # (Optional) The TLS option for the owner user. Defaults to "NONE".
#     import: false              # (Optional) Whether to import the database if it already exists. Defaults to false.
variable "databases" {
  description = "Databases and database attributes - see docs for example"
  type        = any
  default     = {}
}

## Hoop attributes - YAML format
# hoop:
#   enabled: false              # (Optional) Whether Hoop is enabled. Defaults to false.
#   agent_id: "agent-uuid"      # (Required if enabled is true) UUID of the Hoop agent.
#   community: true             # (Optional) Use community secret prefix (_aws:) vs enterprise (_envs/aws#); default: true
#   import: false               # (Optional) Import existing Hoop connection; default: false
#   tags: {key: "value"}        # (Optional) Tags map for Hoop connection.
#   access_control: ["group"]   # (Optional) Access control groups for Hoop connection.
#   engine: "mysql"             # (Optional) Database engine for Hoop. Defaults to "mysql".
#   server_name: "server"       # (Optional) Server name for Hoop.
#   cluster: false              # (Optional) Whether the server is an Aurora cluster. Defaults to false.
#   port: 3306                  # (Optional) Port for local tunnel. Defaults to 3306.
#   username: "localuser"       # (Optional) Username for local tunnel.
#   password: "localpass"       # (Optional) Password for local tunnel.
variable "hoop" {
  description = "Hoop attributes - see docs for example"
  type        = any
  default     = {}
}

## RDS attributes - YAML format
# rds:
#   enabled: false              # (Optional) Whether RDS integration is enabled. Defaults to false.
#   name: "rds-instance-id"     # (Optional) RDS instance or cluster identifier.
#   secret_name: "secret-name"  # (Optional) AWS Secrets Manager secret name for credentials.
#   cluster: false              # (Optional) Whether the RDS is an Aurora cluster. Defaults to false.
#   from_secret: false          # (Optional) Read connection details from secret. Defaults to false.
#   server_name: "logical-name" # (Optional) Override logical server name.
variable "rds" {
  description = "RDS attributes - see docs for example"
  type        = any
  default     = {}
}

## Direct connection attributes - YAML format
# direct:
#   secret_name: "secret-name"  # (Optional) AWS Secrets Manager secret name for direct connection.
variable "direct" {
  description = "Direct connection attributes - see docs for example"
  type        = any
  default     = {}
}

# password_rotation_period: 90    # (Optional) Password rotation period in days. Defaults to 90.
variable "password_rotation_period" {
  description = "Password rotation period in days"
  type        = number
  default     = 90
}


# secrets_kms_key_id: "alias/key" # (Optional) KMS Key ID to encrypt secrets. Defaults to null.
variable "secrets_kms_key_id" {
  description = "(optional) KMS Key ID to use to encrypt data in this secret, can be ARN or KMS Alias"
  type        = string
  default     = null
}

# rotation_lambda_name: "name"   # (Optional) Name of the lambda for password rotation. Defaults to "".
variable "rotation_lambda_name" {
  description = "Name of the lambda function to rotate the password"
  type        = string
  default     = ""
}

# rotation_duration: "1h"       # (Optional) Duration for rotation lambda. Defaults to "1h".
variable "rotation_duration" {
  description = "Duration of the lambda function to rotate the password"
  type        = string
  default     = "1h"
}

# rotate_immediately: false     # (Optional) Rotate password immediately. Defaults to false.
variable "rotate_immediately" {
  description = "Rotate the password immediately"
  type        = bool
  default     = false
}

# force_reset: false            # (Optional) Force reset the password. Defaults to false.
variable "force_reset" {
  description = "Force Reset the password"
  type        = bool
  default     = false
}