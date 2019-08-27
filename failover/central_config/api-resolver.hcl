kind     = "service-resolver"
name     = "api"

failover = {
  "*" = {
    datacenters = ["dc2"]
  }
}
