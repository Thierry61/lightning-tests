# Commands to launch lightning node

# Define env vars related to bitcoin RPC connections
export USERNAME=$(cat /run/secrets/username)
export PASSWORD=$(cat /run/secrets/password)
export PORT=$(cat /port)

# Defaults for lighting-cli command
export LIGHTNING_DIR=$HOME/.lightning
export LIGHTNING_RPC=$LIGHTNING_DIR/lightning-rpc

# lightningd configuration file location
export LIGHTNING_CONF=$HOME/lightning.conf

# Global IP address. This needs iproute2 package installation.
# Another solution would be 0.0.0.0.
export MY_IP=$(ip addr show scope global | sed -nre 's:.*inet (.*)/.*:\1:p')

mkdir -p $LIGHTNING_DIR

# Create bitcoind config file
cat << EOF > $LIGHTNING_CONF
network=regtest
bitcoin-rpcuser=$USERNAME
bitcoin-rpcpassword=$PASSWORD
bitcoin-rpcconnect=bitcoin
bitcoin-rpcport=$PORT
lightning-dir=$LIGHTNING_DIR
rpc-file=$LIGHTNING_RPC
addr=$MY_IP
announce-addr-discovered=true
announce-addr=$MY_IP:9735
experimental-dual-fund
experimental-anchors
experimental-onion-messages
EOF
echo "lightning.conf file created"

echo "Launching lightningd program..."
lightningd --conf=$LIGHTNING_CONF

echo "lightningd program stopped"

sleep infinity
