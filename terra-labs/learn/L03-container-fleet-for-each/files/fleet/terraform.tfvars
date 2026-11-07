services = {
  web = {
    image = "nginx:1.27-alpine"
    port  = 18081
  }
  api = {
    image = "nginx:1.27-alpine"
    port  = 18082
  }
  static = {
    image  = "nginx:1.27-alpine"
    port   = 18083
    memory = 32
  }
}
