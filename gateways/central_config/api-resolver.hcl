kind           = "service-resolver"
name           = "api"

redirect {
  service    = "api"
  datacenter = "dc2"
}
