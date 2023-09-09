# Commands to launch bitcoin core daemon

# Define env vars related to RPC connections
export USERNAME=$(cat /run/secrets/username)
export PASSWORD=$(cat /run/secrets/password)
export PORT=$(cat /port)
export RPCAUTH_LINE=$(./rpcauth.py $USERNAME $PASSWORD | grep rpcauth)

# Create bitcoind config file
cat << EOF > bitcoin.conf
regtest=1
server=1
txindex=1
listenonion=0
fallbackfee=0.00001
$RPCAUTH_LINE
[regtest]
rpcport=$PORT
rpcbind=0.0.0.0
rpcallowip=127.0.0.1
rpcallowip=172.0.0.0/8
rpcallowip=192.0.0.0/8
rpcthreads=24
EOF
echo "bitcoin.conf file created"

echo "Launching bitcoind program..."
bitcoind -conf=$PWD/bitcoin.conf

echo "bitcoind program stopped"

sleep infinity
