kind           = "service-resolver"
name           = "currency"

failover = {
  "*" = {
    datacenters = ["dc2"]
  }
}
