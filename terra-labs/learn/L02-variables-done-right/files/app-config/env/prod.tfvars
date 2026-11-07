env = "prod"

service = {
  name     = "checkout"
  replicas = 3
  tags = {
    tier = "critical"
  }
}
