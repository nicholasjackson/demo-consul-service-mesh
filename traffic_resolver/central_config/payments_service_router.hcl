# A/B test
kind = "service-router"
name = "payments"
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
      service = "payments"
      service_subset = "v2"
    }

  },
]
