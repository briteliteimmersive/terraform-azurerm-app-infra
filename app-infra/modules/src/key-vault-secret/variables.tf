variable "keyvault_secrets" {
  type = object(
    {
      key_vault_id = string
      secrets = list(
        object(
          {
            secret_key   = string
            secret_value = string
          }
        )
      )
    }
  )
}