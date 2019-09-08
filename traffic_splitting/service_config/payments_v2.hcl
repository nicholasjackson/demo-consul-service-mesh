service {
  name = "payments"
  id = "payments-v2"
  address = "10.5.0.6"
  port = 9090
  
  tags      = ["v2"]
  meta      = {
    version = "2"
  }
  
  connect { 
    sidecar_service {
      port = 20000
      
      check {
        name = "Connect Envoy Sidecar"
        tcp = "10.5.0.6:20000"
        interval ="10s"
      }
    }  
  }
}
