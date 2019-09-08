kind = "service-resolver"
name = "payments"

# https://www.consul.io/api/health.html#filtering-2
# Show Node.Meta demonstration showing performance testing a new instance type
default_subset = "v1"

subsets = {
  v1 = {
    filter = "Service.Meta.version == 1"
  }
  v2 = {
    filter = "Service.Meta.version == 2"
  }
}
