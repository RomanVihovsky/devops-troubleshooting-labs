good=$(git log --format=%H -n1 --grep='^pricing module')
git show "$good:modules/pricing/main.tf" > modules/pricing/main.tf
