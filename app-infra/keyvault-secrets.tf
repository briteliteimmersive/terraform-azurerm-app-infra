locals {

  global_secrets = [
    {
      secret_key   = "SUBSCRIPTION-ID"
      secret_value = local.subscription_id
    },
    {
      secret_key   = "TENANT-ID"
      secret_value = local.client_tenant_id
    }
  ]

}

module "common_infra_secret" {
  source = "./modules/src/key-vault-secret"
  keyvault_secrets = {
    key_vault_id = local.infra_keyvault_id
    secrets      = concat(local.linux_vm_secrets, local.global_secrets)
  }
}