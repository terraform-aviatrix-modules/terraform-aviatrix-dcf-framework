resource "aviatrix_distributed_firewalling_config" "this" {
  enable_distributed_firewalling = true
}

# Merge all YAML files in the config directory into a single policy object
locals {
  smart_group_files = fileset("${path.module}/config/smart_groups", "*.yml")
  web_group_files   = fileset("${path.module}/config/web_groups", "*.yml")
  ruleset_files     = fileset("${path.module}/config/rulesets", "*.yml")

  policy = {
    smart_groups = merge([
      for f in local.smart_group_files :
      yamldecode(file("${path.module}/config/smart_groups/${f}")).smart_groups
    ]...)

    web_groups = merge([
      for f in local.web_group_files :
      yamldecode(file("${path.module}/config/web_groups/${f}")).web_groups
    ]...)

    rulesets = {
      prod-policy = {
        attach_to = "TERRAFORM_BEFORE_UI_MANAGED"
        rules = flatten([
          for f in local.ruleset_files :
          yamldecode(file("${path.module}/config/rulesets/${f}")).rules
        ])
      }
    }
  }
}

module "dcf" {
  source = "../.."

  smart_groups = try(local.policy.smart_groups, {})
  web_groups   = try(local.policy.web_groups, {})
  rulesets     = try(local.policy.rulesets, {})

  depends_on = [aviatrix_distributed_firewalling_config.this]
}
