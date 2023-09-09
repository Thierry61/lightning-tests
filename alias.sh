# Define aliases to interact with compose services
# Import them in your session with: . alias.sh
# To be executed after starting the application (to get IP addresses)

# Alias jq under GitBash
# Remarks:
# - GitBash was install with: winget install --id Git.Git -e --source winget
# - jq-win64 was installed with: winget install --id jqlang.jq -e --source winget
if [ "${BASH_VERSINFO[5]}" = "x86_64-pc-msys" ]; then
    alias jq=jq-win64
    # Prevent unwanted path expansion under GitBash
    export MSYS_NO_PATHCONV=1
fi

# Alias for bitcoin commands. For example: bitcoin getblockchaininfo
alias bitcoin='docker compose exec -it bitcoin bitcoin-cli -rpcport=$(cat configs/port.txt) -rpcuser=$(cat secrets/username.txt) -rpcpassword=$(cat secrets/password.txt)'

# Lightning nodes IP addresses (inside docker bridge network)
export   alice_ip=$(docker network inspect lightning-tests_default | jq -r '. [0].Containers | to_entries | .[] | select(.value.Name|endswith("lightning-1")).value.IPv4Address' | cut -d/ -f1)
export     bob_ip=$(docker network inspect lightning-tests_default | jq -r '. [0].Containers | to_entries | .[] | select(.value.Name|endswith("lightning-2")).value.IPv4Address' | cut -d/ -f1)
export charlie_ip=$(docker network inspect lightning-tests_default | jq -r '. [0].Containers | to_entries | .[] | select(.value.Name|endswith("lightning-3")).value.IPv4Address' | cut -d/ -f1)
export    dave_ip=$(docker network inspect lightning-tests_default | jq -r '. [0].Containers | to_entries | .[] | select(.value.Name|endswith("lightning-4")).value.IPv4Address' | cut -d/ -f1)
export    erin_ip=$(docker network inspect lightning-tests_default | jq -r '. [0].Containers | to_entries | .[] | select(.value.Name|endswith("lightning-5")).value.IPv4Address' | cut -d/ -f1)
export   frank_ip=$(docker network inspect lightning-tests_default | jq -r '. [0].Containers | to_entries | .[] | select(.value.Name|endswith("lightning-6")).value.IPv4Address' | cut -d/ -f1)

# Aliases for lightning commands. For example: alice connect id=$bob_id host=$bob_ip
alias   alice='docker exec -it $(docker compose ps --format json | jq -r ".[] | select(.Name|endswith(\"lightning-1\")).ID") lightning-cli -k --conf=/root/lightning.conf'
alias     bob='docker exec -it $(docker compose ps --format json | jq -r ".[] | select(.Name|endswith(\"lightning-2\")).ID") lightning-cli -k --conf=/root/lightning.conf'
alias charlie='docker exec -it $(docker compose ps --format json | jq -r ".[] | select(.Name|endswith(\"lightning-3\")).ID") lightning-cli -k --conf=/root/lightning.conf'
alias    dave='docker exec -it $(docker compose ps --format json | jq -r ".[] | select(.Name|endswith(\"lightning-4\")).ID") lightning-cli -k --conf=/root/lightning.conf'
alias    erin='docker exec -it $(docker compose ps --format json | jq -r ".[] | select(.Name|endswith(\"lightning-5\")).ID") lightning-cli -k --conf=/root/lightning.conf'
alias   frank='docker exec -it $(docker compose ps --format json | jq -r ".[] | select(.Name|endswith(\"lightning-6\")).ID") lightning-cli -k --conf=/root/lightning.conf'

# Lightning nodes IDs
export   alice_id=$(alice getinfo | jq -r '.id')
export     bob_id=$(bob getinfo | jq -r '.id')
export charlie_id=$(charlie getinfo | jq -r '.id')
export    dave_id=$(dave getinfo | jq -r '.id')
export    erin_id=$(erin getinfo | jq -r '.id')
export   frank_id=$(frank getinfo | jq -r '.id')
