ap site.yml
ws_commit "web role: nginx site on 8080"
remember_node web1
# 03:10 disk failure -> rebuilt from the golden image (new host keys)
node_rebuild web2
