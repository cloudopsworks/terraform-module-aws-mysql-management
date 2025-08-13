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
#     name: <name> # (required) Name of the user
#     grant: owner | readwrite | readonly # (required) Grant type for the user
#     db_ref: <db_ref> # (optional) Reference to the database this user is associated with, dafaults to the default dbname of server
#     database_name: <database_name> # (optional) Name of the database this user is associated with, dafaults to the default dbname of server
variable "users" {
  description = "Users and user attributes - see docs for example"
  type        = any
  default     = {}
}

## Roles definition - YAML format
# roles:
#   <role_ref>:
#     name: <name> # (required) Name of the user
#     db_ref: <db_ref> # (optional) Reference to the database this user is associated with, dafaults to the default dbname of server
#     database_name: <database_name> # (optional) Name of the database this user is associated with, dafaults to the default dbname of server
#     table_name: <table_name> # (optional) Name of the table this user is associated with, defaults to `*`
#     grant_option: true | false # (optional) If the role has grant option, defaults to null
#     grants: # (optional) Grants for the role, defaults to ALL PRIVILEGES
#       - ALL PRIVILEGES # (optional) Grant type for the role, defaults to
variable "roles" {
  description = "Roles and role attributes - see docs for example"
  type        = any
  default     = {}
}

## Databases definition - YAML format
# databases:
#   <db_ref>:
#     name: <name> # (required) Name of the database
#     create_owner: true | false # (optional) If the database should be created with an owner, defaults to false
#     owner: <owner> # (optional) Owner of the database, required if create_owner is false
#     default_character_set: <mysql charset> # (optional) Character set of the database, defaults to `utf8mb4`
#     default_collation: <mysql collation> # (optional) Collation of the database, defaults to `utf8mb4_general_ci`
variable "databases" {
  description = "Databases and database attributes - see docs for example"
  type        = any
  default     = {}
}

## Hoop attributes - YAML format
# hoop:
#   enabled: true | false # (optional) If the hoop should be enabled, defaults to false, if hoop is enabled and rds is enabled, hoop connection strings will be generated as outputs
#   agent: "agent_name" # (optional) Name of the hoop agent, required if enabled is true
#   # Optional below for rds.enabled=false and run with a 'hoop connect' session, most suited for local runs
#   connection_name: "rds-db-shared-forward-coreswitch-dev-001-usea1-ow"
#   admin_user: "forward_admin"
#   db_name: "postgres"
#   engine: "postgres"
#   default_sslmode: "require"
#   server_name: "rds-db-shared-forward-coreswitch-dev-001-usea1"
#   cluster: false
#   tags:  # (optional) Tags to apply to the hoop, hoop format <tagname>=<tagvalue>, defaults to empty list
#     - tag_name=tag_value
variable "hoop" {
  description = "Hoop attributes - see docs for example"
  type        = any
  default     = {}
}

## RDS attributes - YAML format
# rds:
#   enabled: true | false # (optional) If the RDS should be enabled, defaults to false
#   name: "<rds_name>" # (optional) Name of the RDS instance, required if enabled is true
#   secret_name: "<rds_secret_name>" # (optional) Name of the RDS secret, required if enabled is true
#   cluster: true | false # (optional) If the RDS is an Aurora RDS Cluster, defaults to false
variable "rds" {
  description = "RDS attributes - see docs for example"
  type        = any
  default     = {}
}

variable "direct" {
  description = "Direct connection attributes - see docs for example"
  type        = any
  default     = {}
}

variable "password_rotation_period" {
  description = "Password rotation period in days"
  type        = number
  default     = 90
}

variable "run_hoop" {
  description = "Run hoop with agent, be careful with this option, it will run the HOOP command in output in a null_resource"
  type        = bool
  default     = false
}

variable "secrets_kms_key_id" {
  description = "(optional) KMS Key ID to use to encrypt data in this secret, can be ARN or KMS Alias"
  type        = string
  default     = null
}

variable "rotation_lambda_name" {
  description = "Name of the lambda function to rotate the password"
  type        = string
  default     = ""
}

variable "rotation_duration" {
  description = "Duration of the lambda function to rotate the password"
  type        = string
  default     = "1h"
}

variable "rotate_immediately" {
  description = "Rotate the password immediately"
  type        = bool
  default     = false
}

variable "force_reset" {
  description = "Force Reset the password"
  type        = bool
  default     = false
}