locals {

  global_secrets = concat(local.linux_vm_secrets)

}

module "common_infra_secret" {
  source = "./modules/src/key-vault-secret"
  keyvault_secrets = {
    key_vault_id = local.infra_keyvault_id
    secrets      = local.global_secrets
  }
}