variable "resource_group_config" {
  type = list(
    object(
      {
        resource_key = string
        name         = string
        location     = string
        tags         = map(string)
        role_assignments = list(
          object(
            {
              role_definition_id = string
              object_ids         = list(string)
            }
          )
        )
      }
    )
  )
}