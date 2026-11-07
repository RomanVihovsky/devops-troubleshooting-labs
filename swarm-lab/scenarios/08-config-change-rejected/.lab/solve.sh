ws_sed 's#^    file: ./greeting.txt#    name: app_greeting_v2\n    file: ./greeting.txt#'
deploy_stack
retry 90 all_nodes_http / 'Welcome from'
