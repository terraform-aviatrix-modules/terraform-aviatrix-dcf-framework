output "smart_groups" {
  description = "Map of all managed Smart Groups, keyed by the input map key. Each entry exposes the resource name and computed UUID."
  value = {
    for k, v in aviatrix_smart_group.smart_groups : k => {
      name = v.name
      uuid = v.uuid
    }
  }
}

output "web_groups" {
  description = "Map of all managed Web Groups, keyed by the input map key. Each entry exposes the resource name and computed UUID."
  value = {
    for k, v in aviatrix_web_group.web_groups : k => {
      name = v.name
      uuid = v.uuid
    }
  }
}

output "rulesets" {
  description = "Map of all managed DCF Rulesets, keyed by the input map key."
  value       = aviatrix_dcf_ruleset.rulesets
}
