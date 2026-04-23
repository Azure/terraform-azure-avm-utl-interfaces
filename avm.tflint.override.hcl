rule "required_output_rmfr7" {
  enabled = false
}

# disabled as we must have subresource name as optional
rule "private_endpoints" {
  enabled = false
}

# disabled until this PR gets merged: https://github.com/Azure/tflint-ruleset-avm/pull/127
rule "role_assignments" {
  enabled = false
}
