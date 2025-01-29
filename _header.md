# terraform-azure-avm-utl-interfaces

This module helps AzAPI module authors satisfy the interface requirements of Azure Verified Modules.
It deploys no resources.
It translates data from the standard variable inputs and generates resource data for AzAPI resources!
Please see the examples for usage.

Here's an example of the data flow:

```text
┌──────────────────────────┐
│                          │
│  var.private_endpoints   ├───────────────────────────────────┐
│                          │                                   │
└──────────────────────────┘                                   ▼
                                                    ┌─────────────────────┐
                                                    │                     │
                                                    │ avm-utl-interfaces  │
                                                    │                     │
                                                    │  - type             │
                                                    │  - name             │
                                                    │  - body             │
                                                    │  - tags             │
                                                    │                     │
                                                    └───────────┬─────────┘
                                                                │
                                                                │
┌──────────────────────────────────────────────────────┐        │
│                                                      │        │
│ resource "azapi_resource" "pe" {                     │        │
│   type = module.interfaces.private_endpoints.type    │        │
│   name = module.interfaces.private_endpoints.name    │        │
│   body = module.interfaces.private_endpoints.body    │◄───────┘
│   tags = module.interfaces.private_endpoints.tags    │
│ }                                                    │
│                                                      │
└──────────────────────────────────────────────────────┘
```
