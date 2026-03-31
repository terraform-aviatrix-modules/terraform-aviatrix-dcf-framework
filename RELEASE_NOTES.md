# terraform-aviatrix-dcf-framework - release notes

## v1.0.0

Initial release.

### Features
- Create and manage Aviatrix DCF Smart Groups from a structured map input
- Create and manage Aviatrix DCF Web Groups from a structured map input
- Create and manage Aviatrix DCF Rulesets from a structured map input
- Smart Group and Web Group map keys are automatically resolved to their computed UUIDs in ruleset rules; unresolved values fall back to raw UUIDs for referencing pre-existing groups
- `attach_to` per ruleset accepts a human-readable DCF attachment point name (e.g. `TERRAFORM_BEFORE_UI_MANAGED`); the module resolves it to the required ID via the `aviatrix_dcf_attachment_point` data source
- URL filter values are automatically stripped of `http://` / `https://` prefixes to satisfy the provider requirement
- Policy can be supplied as native Terraform maps or decoded from an external YAML or JSON file
- Full working examples provided for both [YAML-based](examples/yaml_based_input) and [JSON-based](examples/json_based_input) input
