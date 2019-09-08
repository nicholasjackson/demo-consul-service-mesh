service {
  name = "currency"
  id = "currency-dc2"
  address = "10.6.0.4"
  port = 9090
  
  connect { 
    sidecar_service {
      port = 20000
      
      check {
        name = "Connect Envoy Sidecar"
        tcp = "10.6.0.4:20000"
        interval ="10s"
      }
    }  
  }
}
