publish tf-module-pgbox v1.0.0 "$SCN/.lab/modules/v1.0.0" "pgbox: postgres in a box"
publish tf-module-pgbox v2.0.0 "$SCN/.lab/modules/v2.0.0" "refactor!: consistent naming (this)"
sed -i 's/?ref=v2.0.0/?ref=v1.0.0/' stacks/inventory-db/main.tf
apply stacks/inventory-db
remember_ctr tfl-inventory-db
remember vol "$(docker volume inspect -f '{{.CreatedAt}}' tfl-inventory-pgdata)"
ws_commit "inventory-db: pgbox v1.0.0"
sed -i 's/?ref=v1.0.0/?ref=v2.0.0/' stacks/inventory-db/main.tf
ws_commit "chore(deps): tf-module-pgbox v2.0.0" "renovate[bot]"
