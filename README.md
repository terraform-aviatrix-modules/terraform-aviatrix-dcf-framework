# terraform-aviatrix-dcf-framework

### Description
This module manages Aviatrix [Distributed Cloud Firewall (DCF)](https://docs.aviatrix.com/documentation/latest/security/distributed-cloud-firewall.html) Smart Groups, Web Groups, and Rulesets from a single structured data input. Policy can be supplied as a native Terraform map or loaded from an external [YAML](examples/yaml_based_input) or [JSON](examples/json_based_input) file, allowing firewall policy to be managed as code without embedding resource definitions directly in HCL.

The module resolves Smart Group and Web Group map keys to their computed UUIDs before attaching them to rules, and looks up DCF attachment point IDs automatically from the `attach_to` name supplied per ruleset.

### Compatibility
Module version | Terraform version | Controller version | Terraform provider version
:--- | :--- | :--- | :---
v1.0.0 | >= 1.3.0 | >= 7.1 | >= 3.1.0

Check [release notes](RELEASE_NOTES.md) for more details.
Check [compatibility list](COMPATIBILITY.md) for older versions.

### Usage Example

Policy is maintained in a separate YAML file and decoded at plan time. A JSON equivalent is also supported — see the [json_based_input](examples/json_based_input) example.

**main.tf**
```hcl
resource "aviatrix_distributed_firewalling_config" "this" {
  enable_distributed_firewalling = true
}

locals {
  policy = yamldecode(file("${path.module}/policy.yml"))
}

module "dcf" {
  source  = "terraform-aviatrix-modules/dcf-framework/aviatrix"
  version = "1.0.0"

  smart_groups = try(local.policy.smart_groups, {})
  web_groups   = try(local.policy.web_groups, {})
  rulesets     = try(local.policy.rulesets, {})
}
```

**policy.yml**
```yaml
---
smart_groups:

  # --- CIDR-based groups ---
  rfc1918:
    selector:
      - cidr: "10.0.0.0/8"
      - cidr: "172.16.0.0/12"
      - cidr: "192.168.0.0/16"

  internet:
    selector:
      - cidr: "0.0.0.0/0"

  # --- Tag-based VM groups ---
  app-servers:
    selector:
      - type: vm
        account_name: my-aws-account
        region: us-east-1
        tags:
          role: app
          env: prod

  db-servers:
    selector:
      - type: vm
        account_name: my-aws-account
        region: us-east-1
        tags:
          role: db
          env: prod

  # --- Threat intelligence feed ---
  threat-feeds:
    selector:
      - external: threatiq
      - external: geo
        ext_args:
          country_iso_code: CN

web_groups:

  # SNI-based allow-list for outbound HTTPS
  allowed-saas:
    selector:
      - snifilter: "*.salesforce.com"
      - snifilter: "*.okta.com"

  # URL-based allow-list for package downloads
  allowed-downloads:
    selector:
      - urlfilter: "registry.npmjs.org/*"
      - urlfilter: "pypi.org/packages/*"

rulesets:

  prod-policy:
    attach_to: "TERRAFORM_BEFORE_UI_MANAGED"
    rules:

      - name: block-threat-intel
        action: DENY
        protocol: ANY
        priority: 10
        src_smart_groups:
          - threat-feeds
        dst_smart_groups:
          - rfc1918
        logging: true

      - name: app-to-saas-https
        action: DEEP_PACKET_INSPECTION_PERMIT
        protocol: TCP
        priority: 100
        src_smart_groups:
          - app-servers
        dst_smart_groups:
          - internet
        web_groups:
          - allowed-saas
        port_ranges:
          - lo: 443
            hi: 443
        flow_app_requirement: TLS_REQUIRED
        logging: true

      - name: deny-all
        action: DENY
        protocol: ANY
        priority: 65000
        src_smart_groups:
          - internet
        dst_smart_groups:
          - rfc1918
        logging: true
```

### Variables
There are no required variables. All inputs default to an empty map, producing no resources unless values are provided.

The following variables are optional:

key | default | value
:---|:---|:---
smart_groups | `{}` | Map of Smart Groups to create. The map key is used as the Terraform resource label and default name. See [Smart Group selector arguments](#smart-group-selector-arguments).
web_groups | `{}` | Map of Web Groups to create. The map key is used as the Terraform resource label and default name. See [Web Group selector arguments](#web-group-selector-arguments).
rulesets | `{}` | Map of DCF Rulesets to create. The map key is used as the Terraform resource label and default name. Smart Group and Web Group references in rules are resolved by map key; unresolved values are treated as raw UUIDs. See [Ruleset arguments](#ruleset-arguments).

### Built-in Smart Groups

The Aviatrix platform pre-defines the following Smart Groups. They cannot be managed or created via Terraform, but can be referenced by name in `src_smart_groups` and `dst_smart_groups` rule fields just like any customer-defined Smart Group — no entry in the `smart_groups` input is required.

name | UUID | description
:---|:---|:---
`Any` | `def000ad-0000-0000-0000-000000000000` | Matches all traffic regardless of source or destination
`Public Internet` | `def000ad-0000-0000-0000-000000000001` | Matches traffic to/from the public internet

**Example** — reference a built-in group in a rule:

```yaml
rules:
  - name: allow-https-outbound
    action: PERMIT
    protocol: TCP
    priority: 100
    src_smart_groups:
      - Any
    dst_smart_groups:
      - Public Internet
    port_ranges:
      - lo: 443
        hi: 443
    logging: true
```

### Smart Group selector arguments
key | required | value
:---|:---|:---
cidr | No | CIDR block to match
fqdn | No | FQDN to match
site | No | Site name to match
type | No | Resource type (`vm`, `vpc`, `k8s`)
res_id | No | Resource ID
account_id | No | Account ID
account_name | No | Access account name
name | No | Resource name
region | No | Cloud region
zone | No | Availability zone
k8s_cluster_id | No | Kubernetes cluster ID
k8s_namespace | No | Kubernetes namespace
k8s_service | No | Kubernetes service
k8s_pod | No | Kubernetes pod
s2c | No | Site2Cloud connection name
external | No | External threat feed (`threatiq`, `geo`)
tags | No | Map of key/value tags to match
ext_args | No | Map of extra arguments for external feeds (e.g. `country_iso_code`)

### Web Group selector arguments
key | required | value
:---|:---|:---
snifilter | No | SNI hostname pattern (e.g. `*.example.com`)
urlfilter | No | URL pattern without `http://` or `https://` prefix (e.g. `registry.npmjs.org/*`)

### Ruleset arguments
key | required | value
:---|:---|:---
name | No | Override the ruleset name (defaults to the map key)
attach_to | No | Name of the DCF attachment point (e.g. `TERRAFORM_BEFORE_UI_MANAGED`). The module resolves this to the attachment point ID automatically.
rules | No | List of rule objects. See [Rule arguments](#rule-arguments).

### Rule arguments
key | required | value
:---|:---|:---
name | Yes | Rule name
action | Yes | `PERMIT`, `DENY`, `DEEP_PACKET_INSPECTION_PERMIT`, or `INTRUSION_DETECTION_PERMIT`
protocol | Yes | `TCP`, `UDP`, `ICMP`, or `ANY`
src_smart_groups | Yes | List of Smart Group map keys or raw UUIDs for the source
dst_smart_groups | Yes | List of Smart Group map keys or raw UUIDs for the destination
priority | No | Rule priority (default: `0`)
port_ranges | No | List of `{ lo, hi }` port range objects. Cannot be used with `ICMP`.
web_groups | No | List of Web Group map keys or raw UUIDs
flow_app_requirement | No | `APP_UNSPECIFIED`, `TLS_REQUIRED`, or `NOT_TLS_REQUIRED`
decrypt_policy | No | `DECRYPT_UNSPECIFIED`, `DECRYPT_ALLOWED`, or `DECRYPT_NOT_ALLOWED`
tls_profile | No | TLS profile UUID
log_profile | No | Logging profile UUID
exclude_sg_orchestration | No | Exclude this rule from SG orchestration (`true`/`false`, default: `false`)
watch | No | Watch-only mode — observe without enforcing (`true`/`false`)
logging | No | Enable logging for matching packets (`true`/`false`)

### Outputs
This module will return the following outputs:

key | description
:---|:---
smart_groups | Map of created Smart Groups keyed by input map key, each exposing `name` and `uuid`
web_groups | Map of created Web Groups keyed by input map key, each exposing `name` and `uuid`
rulesets | Map of created DCF Ruleset resources keyed by input map key
\<keyname> | \<description of object that will be returned in this output>
