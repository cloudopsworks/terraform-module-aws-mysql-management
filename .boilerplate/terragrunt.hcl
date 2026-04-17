locals {
  local_vars  = yamldecode(file("./inputs.yaml"))
  spoke_vars  = yamldecode(file(find_in_parent_folders("spoke-inputs.yaml")))
  region_vars = yamldecode(file(find_in_parent_folders("region-inputs.yaml")))
  env_vars    = yamldecode(file(find_in_parent_folders("env-inputs.yaml")))
  global_vars = yamldecode(file(find_in_parent_folders("global-inputs.yaml")))

  local_tags  = jsondecode(file("./local-tags.json"))
  spoke_tags  = jsondecode(file(find_in_parent_folders("spoke-tags.json")))
  region_tags = jsondecode(file(find_in_parent_folders("region-tags.json")))
  env_tags    = jsondecode(file(find_in_parent_folders("env-tags.json")))
  global_tags = jsondecode(file(find_in_parent_folders("global-tags.json")))

  tags = merge(
    local.global_tags,
    local.env_tags,
    local.region_tags,
    local.spoke_tags,
    local.local_tags
  )
}

include "root" {
  path = find_in_parent_folders("{{ .RootFileName }}")
}

terraform {
  source = "{{ .sourceUrl }}"
}
{{ if .rds_enabled }}
dependency "database" {
  config_path = "{{ .rds_path }}"
  #skip_outputs = true
  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["validate", "destroy"]
  mock_outputs = {
    {{- if $.rds_cluster }}
    rds_cluster_identifier = "rds-cluster-identifier"
    cluster_secrets_credentials_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds-cluster-credentials-arn"
    {{- else }}
    rds_instance_identifier = "rds-instance-identifier"
    rds_secrets_credentials_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:rds-instance-credentials-arn"
    {{- end }}
  }
}
{{ end }}
inputs = {
  is_hub     = {{ .is_hub }}
  org        = local.env_vars.org
  spoke_def  = local.spoke_vars.spoke
  {{- range .requiredVariables }}
  {{- if ne .Name "org" }}
  {{ .Name }} = local.local_vars.{{ .Name }}
  {{- end }}
  {{- end }}
  {{- range .optionalVariables }}
  {{- if not (eq .Name "extra_tags" "is_hub" "spoke_def" "org") }}
  {{- if and $.rds_enabled (eq .Name "rds") }}
  rds = {
    enabled = true
    {{- if $.rds_cluster }}
    name = dependency.database.outputs.rds_cluster_identifier
    secret_name = dependency.database.outputs.cluster_secrets_credentials_arn
    {{- else }}
    name = dependency.database.outputs.rds_instance_identifier
    secret_name = dependency.database.outputs.rds_secrets_credentials_arn
    {{- end }}
    cluster = {{ $.rds_cluster }}
  }
  {{- else }}
  {{ .Name }} = try(local.local_vars.{{ .Name }}, {{ .DefaultValue }})
  {{- end }}
  {{- end }}
  {{- end }}
  extra_tags = local.tags
}