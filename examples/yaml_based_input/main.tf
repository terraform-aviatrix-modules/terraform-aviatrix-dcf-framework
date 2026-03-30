module "dcf" {
  source = "../.."

  smart_groups = try(local.policy.smart_groups, {})
  web_groups   = try(local.policy.web_groups, {})
  rulesets     = try(local.policy.rulesets, {})
}

locals {
  policy = yamldecode(file("${path.module}/policy.yml"))
}
