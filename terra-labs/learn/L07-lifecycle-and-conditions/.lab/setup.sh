apply shop
aws ssm put-parameter --name /shop/banner --type String --value "Black Friday -20%" --overwrite >/dev/null
remember_ctr tfl-shop-web
remember vol_created "$(docker volume inspect -f '{{.CreatedAt}}' tfl-shop-data)"
