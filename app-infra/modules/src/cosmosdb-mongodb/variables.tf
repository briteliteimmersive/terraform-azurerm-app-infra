variable "cosmosdb_mongodb_configs" {
  type = list(object(
    {
      resource_key        = string
      name                = string
      resource_group_name = string
      account_name        = string
      throughput          = number
      autoscale_settings = object({
        max_throughput = number
      })
      collections = list(object({
        name                   = string
        shard_key              = string
        analytical_storage_ttl = number
        default_ttl_seconds    = number
        throughput             = number
        index = list(object(
          {
            keys   = list(string)
            unique = bool
          }
        ))
        autoscale_settings = object({
          max_throughput = number
        })
      }))
    }
  ))
}