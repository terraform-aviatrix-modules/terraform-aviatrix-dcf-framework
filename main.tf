resource "aviatrix_smart_group" "smart_groups" {
  for_each = var.smart_groups

  name = coalesce(each.value.name, each.key)

  selector {
    dynamic "match_expressions" {
      for_each = each.value.selector
      content {
        cidr           = match_expressions.value.cidr
        fqdn           = match_expressions.value.fqdn
        site           = match_expressions.value.site
        type           = match_expressions.value.type
        resource_id    = match_expressions.value.resource_id
        account_id     = match_expressions.value.account_id
        account_name   = match_expressions.value.account_name
        name           = match_expressions.value.name
        region         = match_expressions.value.region
        zone           = match_expressions.value.zone
        k8s_cluster_id = match_expressions.value.k8s_cluster_id
        k8s_namespace  = match_expressions.value.k8s_namespace
        k8s_service    = match_expressions.value.k8s_service
        k8s_pod_name   = match_expressions.value.k8s_pod_name
        s2c            = match_expressions.value.s2c
        external       = match_expressions.value.external
        tags           = match_expressions.value.tags
        ext_args       = match_expressions.value.ext_args
      }
    }
  }
}

resource "aviatrix_web_group" "web_groups" {
  for_each = var.web_groups

  name = coalesce(each.value.name, each.key)

  selector {
    dynamic "match_expressions" {
      for_each = each.value.selector
      content {
        snifilter = match_expressions.value.snifilter
        urlfilter = match_expressions.value.urlfilter
      }
    }
  }
}

resource "aviatrix_dcf_ruleset" "rulesets" {
  for_each = var.rulesets

  name      = coalesce(each.value.name, each.key)
  attach_to = each.value.attach_to

  dynamic "rules" {
    for_each = each.value.rules
    content {
      name     = rules.value.name
      action   = rules.value.action
      protocol = rules.value.protocol
      priority = rules.value.priority

      # Resolve references by map key; fall back to treating the value as a raw UUID
      # to allow referencing Smart Groups not managed by this module.
      src_smart_groups = [
        for sg in rules.value.src_smart_groups :
        lookup(local.smart_group_uuid_map, sg, sg)
      ]

      dst_smart_groups = [
        for sg in rules.value.dst_smart_groups :
        lookup(local.smart_group_uuid_map, sg, sg)
      ]

      web_groups = rules.value.web_groups != null ? [
        for wg in rules.value.web_groups :
        lookup(local.web_group_uuid_map, wg, wg)
      ] : null

      dynamic "port_ranges" {
        for_each = rules.value.port_ranges != null ? rules.value.port_ranges : []
        content {
          lo = port_ranges.value.lo
          hi = port_ranges.value.hi
        }
      }

      flow_app_requirement     = rules.value.flow_app_requirement
      decrypt_policy           = rules.value.decrypt_policy
      tls_profile              = rules.value.tls_profile
      log_profile              = rules.value.log_profile
      exclude_sg_orchestration = rules.value.exclude_sg_orchestration
      watch                    = rules.value.watch
      logging                  = rules.value.logging
    }
  }

  # Explicit ordering: all Smart Groups and Web Groups must exist before any ruleset
  # is created or modified, as rulesets reference group UUIDs.
  depends_on = [
    aviatrix_smart_group.smart_groups,
    aviatrix_web_group.web_groups,
  ]
}
