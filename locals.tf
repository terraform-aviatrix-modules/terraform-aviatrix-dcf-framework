locals {
  # Resolve Smart Group map keys to their computed UUIDs.
  # Used by ruleset rules to translate key references to UUIDs via lookup().
  smart_group_uuid_map = { for k, v in aviatrix_smart_group.smart_groups : k => v.uuid }

  # Resolve Web Group map keys to their computed UUIDs.
  # Used by ruleset rules to translate key references to UUIDs via lookup().
  web_group_uuid_map = { for k, v in aviatrix_web_group.web_groups : k => v.uuid }
}
