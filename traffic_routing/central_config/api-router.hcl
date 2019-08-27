kind = "service-router"
name = "api"
routes = [
  {
    match {
      http {
        path_prefix = "/v1"
      }
    }

    destination {
      service = "api-v1"
    }
  },
  {
    match {
      http {
        path_prefix = "/v2"
      }
    }

    destination {
      service = "api-v2"
    }
  },
]
