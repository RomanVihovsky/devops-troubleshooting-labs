state_bucket
sed -i 's/required_version = "~> 1.9.0"/required_version = ">= 1.5"/' modules/legacy-tags/main.tf
apply stacks/shop
ws_commit "shop: orders topic"
cp "$SCN/files/modules/legacy-tags/main.tf" modules/legacy-tags/main.tf
ws_commit "vendor legacy-tags from the archived repo" "Taylor (shop)"
rm -rf stacks/shop/.terraform/modules
