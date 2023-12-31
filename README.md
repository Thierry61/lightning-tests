Simulation of a regtest bitcoin node and a set of 6 lightning nodes (alice, bob, charlie, dave, erin, frank).
The alias.sh file permits commands in the nodes using their names.

Steps:
- install Docker Desktop
- on Windows install jq-win64 and GitBash, note that this is the only target I have tested
- define bitcoin RPC port number in `configs/port.txt`
- define bitcoin RPC auth username and password in `secrets/username.txt` and `secrets/password.txt`
- pull lightningd image: `docker pull elementsproject/lightningd:v23.08.1`
- rebuild images: `docker compose build` (needed when Dockerfile.* or start-*.sh files are modified)
- launch the application: `docker compose up -d`
- create aliases: `. alias.sh`
- execute commands interacting with bitcoin and lightning nodes, for example: `. tests/t02.sh`
- shutdown the application: `docker compose down`

Useful docker commands:
- display logs of all services: `docker compose logs`
- display logs of a specific service: `docker compose logs bitcoin`
- inspect application bridge network: `docker network inspect lightning-tests_default`
- list containers: `docker compose ps`
- inspect a specific container: `docker inspect lightning-tests-bitcoin-1`
- get its IP config: `docker inspect lightning-tests-bitcoin-1 | jq -r '.[0].NetworkSettings.Networks."lightning-tests_default"'`

Useful commands to interact with bitcoin node:
- bitcoin getblockchaininfo
- bitcoin getdeploymentinfo | jq -r '.deployments.segwit' (to check that segwit is active)
- bitcoin createwallet wallet1
- bitcoin getnewaddress
- bitcoin generatetoaddress 100 \<address\>
- bitcoin getbalances
- bitcoin getaddressesbylabel ""
- bitcoin getaddressinfo \<address\>
- bitcoin getreceivedbyaddress \<address\> (beware, this isn't a balance!!!)
- bitcoin listaddressgroupings
- bitcoin sendtoaddress --help
- bitcoin sendtoaddress \<address\> 20 "" "" false true 6 "economical" false
- bitcoin gettransaction \<transaction-id\> true true

Useful commands to interact with lightning nodes:
- export addr=$(alice newaddr | jq -r '.bech32')
- alice connect id=$bob_id host=$bob_ip
- alice fundchannel id=$bob_id amount=16000000
- export invoice=$(frank invoice amount_msat=1000000000 label=01 description="Frank's first invoice" | jq -r '.bolt11')
- alice pay bolt11=$invoice
- bob getinfo | jq -r '.fees_collected_msat'
