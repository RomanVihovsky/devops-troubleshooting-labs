mkcompose () 
{ 
    local d=$1;
    shift;
    { 
        echo "# Machines for this scenario (definitions: ../../infra/hosts.yml)";
        echo "services:";
        for h in "$@";
        do
            printf '  %s:\n    extends: { file: ../../infra/hosts.yml, service: %s }\n' "$h" "$h";
        done;
        printf 'networks:\n  lab:\n    name: linuxlab\n    ipam: { config: [ { subnet: 10.77.0.0/24 } ] }\n'
    } > "$d/compose.yml"
}
