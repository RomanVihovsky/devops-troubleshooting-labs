aws_up
aws launch shop-web-1 web1 web >> "$SETUP_LOG"
aws launch shop-web-2 web2 web >> "$SETUP_LOG"
aws launch shop-db-1 db1 db >> "$SETUP_LOG"
aws launch shop-web-9 10.78.0.19 web >> "$SETUP_LOG"
aws stop shop-web-9
aws launch stg-web-1 10.78.0.40 web staging >> "$SETUP_LOG"
aws launch legacy-web-1 10.78.0.41 web prod us-east-1 >> "$SETUP_LOG"
ap site.yml
ws_commit "shop: web + db tiers (inventory from the CMDB export)"
