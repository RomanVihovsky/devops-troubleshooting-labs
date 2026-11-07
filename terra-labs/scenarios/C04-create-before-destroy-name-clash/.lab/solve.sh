sed -i 's|  name        = "tfl-api"|  name        = "tfl-api-${var.color}" # unique per generation (create_before_destroy)|' stacks/api/main.tf
apply stacks/api
