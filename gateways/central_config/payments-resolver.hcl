kind           = "service-resolver"
name           = "payments"

redirect {
  service    = "payments"
  datacenter = "dc2"
}
