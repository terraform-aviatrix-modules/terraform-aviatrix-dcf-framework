locals {
  # Pre-existing platform-defined Smart Groups that are not customer-created
  # and therefore cannot be managed via aviatrix_smart_group resources.
  # Customers can reference these by name in their rule configurations.
  builtin_smart_groups = {
    "Anywhere"        = "def000ad-0000-0000-0000-000000000000"
    "Public Internet" = "def000ad-0000-0000-0000-000000000001"
  }

  # Resolve Smart Group map keys to their computed UUIDs.
  # Used by ruleset rules to translate key references to UUIDs via lookup().
  smart_group_uuid_map = merge(
    local.builtin_smart_groups,
    { for k, v in aviatrix_smart_group.smart_groups : k => v.uuid }
  )

  # Resolve Web Group map keys to their computed UUIDs.
  # Used by ruleset rules to translate key references to UUIDs via lookup().
  web_group_uuid_map = { for k, v in aviatrix_web_group.web_groups : k => v.uuid }
}
