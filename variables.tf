variable "smart_groups" {
  description = "Map of Smart Groups to create. The map key is used as the Terraform resource label and as the default name if 'name' is not specified."
  default     = {}
  nullable    = false
  type = map(object({
    name = optional(string)
    selector = list(object({
      cidr           = optional(string)
      fqdn           = optional(string)
      site           = optional(string)
      type           = optional(string)
      res_id         = optional(string)
      account_id     = optional(string)
      account_name   = optional(string)
      name           = optional(string)
      region         = optional(string)
      zone           = optional(string)
      k8s_cluster_id = optional(string)
      k8s_namespace  = optional(string)
      k8s_service    = optional(string)
      k8s_pod        = optional(string)
      s2c            = optional(string)
      external       = optional(string)
      tags           = optional(map(string))
      ext_args       = optional(map(string))
    }))
  }))
}

variable "web_groups" {
  description = "Map of Web Groups to create. The map key is used as the Terraform resource label and as the default name if 'name' is not specified."
  default     = {}
  nullable    = false
  type = map(object({
    name = optional(string)
    selector = list(object({
      snifilter = optional(string)
      urlfilter = optional(string)
    }))
  }))
}

variable "rulesets" {
  description = "Map of DCF Rulesets to create. The map key is used as the Terraform resource label and as the default name if 'name' is not specified. Smart Group and Web Group references in rules are resolved by map key first; unresolved values are treated as raw UUIDs to support referencing pre-existing groups."
  default     = {}
  nullable    = false
  type = map(object({
    name             = optional(string)
    attach_to = optional(string)
    rules = optional(list(object({
      name             = string
      action           = string
      protocol         = string
      src_smart_groups = list(string)
      dst_smart_groups = list(string)
      priority         = optional(number)
      port_ranges = optional(list(object({
        lo = number
        hi = optional(number)
      })))
      web_groups               = optional(list(string))
      flow_app_requirement     = optional(string)
      decrypt_policy           = optional(string)
      tls_profile              = optional(string)
      log_profile              = optional(string)
      exclude_sg_orchestration = optional(bool)
      watch                    = optional(bool)
      logging                  = optional(bool)
    })), [])
  }))
}
