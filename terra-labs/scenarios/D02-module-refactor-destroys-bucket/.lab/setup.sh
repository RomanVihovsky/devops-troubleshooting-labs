state_bucket
cp "$SCN/.lab/before/main.tf" stacks/media/main.tf
apply stacks/media
echo 'jpeg' | aws s3 cp - s3://acme-media-uploads/u/42/avatar.jpg >/dev/null
remember_bucket acme-media-uploads
ws_commit "media: uploads bucket"
cp "$SCN/files/stacks/media/main.tf" stacks/media/main.tf
ws_commit "refactor: use modules/bucket for uploads" "Robin (media)"
