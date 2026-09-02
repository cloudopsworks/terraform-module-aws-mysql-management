## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.35 |
| <a name="requirement_mysql"></a> [mysql](#requirement\_mysql) | ~> 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.13 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.35 |
| <a name="provider_mysql"></a> [mysql](#provider\_mysql) | ~> 3.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.4 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_db"></a> [db](#module\_db) | git::https://github.com/cloudopsworks/terraform-module-mysql-management.git | v2.3.1-alpha.4 |
| <a name="module_tags"></a> [tags](#module\_tags) | cloudopsworks/tags/local | 1.0.10 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_secretsmanager_secret.owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_rotation.owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_rotation.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.owner_rotated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_secretsmanager_secret_version.user_rotated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [mysql_grant.owner](https://registry.terraform.io/providers/petoju/mysql/latest/docs/resources/grant) | resource |
| [mysql_grant.role](https://registry.terraform.io/providers/petoju/mysql/latest/docs/resources/grant) | resource |
| [mysql_grant.user_all_db](https://registry.terraform.io/providers/petoju/mysql/latest/docs/resources/grant) | resource |
| [mysql_grant.user_ro_tab_def_priv](https://registry.terraform.io/providers/petoju/mysql/latest/docs/resources/grant) | resource |
| [mysql_grant.user_tab_def_priv](https://registry.terraform.io/providers/petoju/mysql/latest/docs/resources/grant) | resource |
| [mysql_role.role](https://registry.terraform.io/providers/petoju/mysql/latest/docs/resources/role) | resource |
| [random_password.owner_initial](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.user_initial](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_db_instance.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance) | data source |
| [aws_db_instance.hoop_db_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance) | data source |
| [aws_lambda_function.rotation_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_function) | data source |
| [aws_rds_cluster.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/rds_cluster) | data source |
| [aws_rds_cluster.hoop_db_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/rds_cluster) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_secretsmanager_secret.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret_version.db_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.owner_rotated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_version.user_rotated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version) | data source |
| [aws_secretsmanager_secret_versions.owner_rotated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_versions) | data source |
| [aws_secretsmanager_secret_versions.user_rotated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_versions) | data source |
| [aws_secretsmanager_secrets.owner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secrets) | data source |
| [aws_secretsmanager_secrets.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secrets) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_databases"></a> [databases](#input\_databases) | Databases and database attributes - see docs for example | `any` | `{}` | no |
| <a name="input_direct"></a> [direct](#input\_direct) | Direct connection attributes - see docs for example | `any` | `{}` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Extra tags to add to the resources | `map(string)` | `{}` | no |
| <a name="input_force_reset"></a> [force\_reset](#input\_force\_reset) | Force Reset the password | `bool` | `false` | no |
| <a name="input_hoop"></a> [hoop](#input\_hoop) | Hoop attributes - see docs for example | `any` | `{}` | no |
| <a name="input_is_hub"></a> [is\_hub](#input\_is\_hub) | Is this a hub or spoke configuration? | `bool` | `false` | no |
| <a name="input_org"></a> [org](#input\_org) | Organization details | <pre>object({<br/>    organization_name = string<br/>    organization_unit = string<br/>    environment_type  = string<br/>    environment_name  = string<br/>  })</pre> | n/a | yes |
| <a name="input_password_rotation_period"></a> [password\_rotation\_period](#input\_password\_rotation\_period) | Password rotation period in days | `number` | `90` | no |
| <a name="input_rds"></a> [rds](#input\_rds) | RDS attributes - see docs for example | `any` | `{}` | no |
| <a name="input_roles"></a> [roles](#input\_roles) | Roles and role attributes - see docs for example | `any` | `{}` | no |
| <a name="input_rotate_immediately"></a> [rotate\_immediately](#input\_rotate\_immediately) | Rotate the password immediately | `bool` | `false` | no |
| <a name="input_rotation_duration"></a> [rotation\_duration](#input\_rotation\_duration) | Duration of the lambda function to rotate the password | `string` | `"1h"` | no |
| <a name="input_rotation_lambda_name"></a> [rotation\_lambda\_name](#input\_rotation\_lambda\_name) | Name of the lambda function to rotate the password | `string` | `""` | no |
| <a name="input_secrets_kms_key_id"></a> [secrets\_kms\_key\_id](#input\_secrets\_kms\_key\_id) | (optional) KMS Key ID to use to encrypt data in this secret, can be ARN or KMS Alias | `string` | `null` | no |
| <a name="input_secrets_recovery_window"></a> [secrets\_recovery\_window](#input\_secrets\_recovery\_window) | (optional) Default recovery window in days before a deleted secret is permanently removed. Use 0 to delete immediately, otherwise 7-30. Defaults to 30 | `number` | `30` | no |
| <a name="input_secrets_replica_kms_key_id"></a> [secrets\_replica\_kms\_key\_id](#input\_secrets\_replica\_kms\_key\_id) | (optional) KMS Key ID used to encrypt replicated secrets, can be ARN or KMS Alias. Must reside in the replica region. Defaults to null (AWS managed key) | `string` | `null` | no |
| <a name="input_secrets_replica_region"></a> [secrets\_replica\_region](#input\_secrets\_replica\_region) | (optional) Region to replicate every managed secret into. When null, no replica is created unless set per entity. Defaults to null | `string` | `null` | no |
| <a name="input_specials_in_password"></a> [specials\_in\_password](#input\_specials\_in\_password) | (optional) Use special characters in generated owner/user passwords. When false, generated passwords are alphanumeric only. Defaults to true | `bool` | `true` | no |
| <a name="input_spoke_def"></a> [spoke\_def](#input\_spoke\_def) | Spoke ID Number, must be a 3 digit number | `string` | `"001"` | no |
| <a name="input_users"></a> [users](#input\_users) | Users and user attributes - see docs for example | `any` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_hoop_connections"></a> [hoop\_connections](#output\_hoop\_connections) | Hoop.dev connection definitions for every managed owner and user, keyed by connection name. Null when `hoop.enabled` is false or the resolved engine is not MySQL. |
| <a name="output_owners"></a> [owners](#output\_owners) | Map of database refs to their generated owner user, keyed by the `databases` map key. Each entry exposes the owner username, the AWS Secrets Manager secret holding its credentials, and whether that secret carries a password. Only databases with `create_owner = true` are present. |
| <a name="output_users"></a> [users](#output\_users) | Map of user refs to their managed MySQL user, keyed by the `users` map key. Each entry exposes the username, the AWS Secrets Manager secret holding its credentials, and whether that secret carries a password. |
