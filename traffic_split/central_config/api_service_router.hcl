# A/B test

kind = "service-router"
name = "api"
routes = [
  {
    match {
      http {
        header = [
          {
            name  = "testgroup"
            exact = "b"
          },
        ]
      }
    }

    destination {
      service = "api"
      service_subset = "v2"
    }

  },
]
