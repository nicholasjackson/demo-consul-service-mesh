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
        header = [
          {
            name  = ":authority"
            exact = "api.v2.test"
          },
        ]
      }
    }

    destination {
      service = "api-v2"
    }
  },
]
