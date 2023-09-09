# Test some lightning commands

function check_all_channels {
    echo "Check all channels own amount:"
    printf "Alice   => Bob:     %11s\n" $(alice   listfunds | jq --arg next $bob_id     -r '.channels | .[] | select(.peer_id==$next) | .our_amount_msat')
    printf "Bob     => Charlie: %11s\n" $(bob     listfunds | jq --arg next $charlie_id -r '.channels | .[] | select(.peer_id==$next) | .our_amount_msat')
    printf "Bob     => Alice:   %11s\n" $(bob     listfunds | jq --arg prev $alice_id   -r '.channels | .[] | select(.peer_id==$prev) | .our_amount_msat')
    printf "Charlie => Dave:    %11s\n" $(charlie listfunds | jq --arg next $dave_id    -r '.channels | .[] | select(.peer_id==$next) | .our_amount_msat')
    printf "Charlie => Bob:     %11s\n" $(charlie listfunds | jq --arg prev $bob_id     -r '.channels | .[] | select(.peer_id==$prev) | .our_amount_msat')
    printf "Dave    => Erin:    %11s\n" $(dave    listfunds | jq --arg next $erin_id    -r '.channels | .[] | select(.peer_id==$next) | .our_amount_msat')
    printf "Dave    => Charlie: %11s\n" $(dave    listfunds | jq --arg prev $charlie_id -r '.channels | .[] | select(.peer_id==$prev) | .our_amount_msat')
    printf "Erin    => Frank:   %11s\n" $(erin    listfunds | jq --arg next $frank_id   -r '.channels | .[] | select(.peer_id==$next) | .our_amount_msat')
    printf "Erin    => Dave:    %11s\n" $(erin    listfunds | jq --arg prev $dave_id    -r '.channels | .[] | select(.peer_id==$prev) | .our_amount_msat')
    printf "Frank   => Erin:    %11s\n" $(frank   listfunds | jq --arg prev $erin_id    -r '.channels | .[] | select(.peer_id==$prev) | .our_amount_msat')
}

echo "Create a mining wallet"
bitcoin createwallet wallet1

echo "Mine 100 blocks and ensure that the first ten coinbase outputs are spendable"
bitcoin -generate 100 > /dev/null
bitcoin -generate 10 > /dev/null

echo "Create a bitcoin address for alice's node and move 2 BTC to it"
export addr=$(alice newaddr | jq -r '.bech32')
bitcoin sendtoaddress $addr 2 "" "" false true 6 "economical" false

echo "Same for other lightning nodes"
bitcoin sendtoaddress $(bob newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(charlie newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(dave newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(erin newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(frank newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false

echo "Confirm these transactions and wait 30s"
bitcoin -generate 6 > /dev/null
sleep 30

echo "Connect alice => bob => charlie => david => erin => frank"
alice connect id=$bob_id host=$bob_ip
bob connect id=$charlie_id host=$charlie_ip
charlie connect id=$dave_id host=$dave_ip
dave connect id=$erin_id host=$erin_ip
erin connect id=$frank_id host=$frank_ip

echo "Create channels following the same connection graph."
alice fundchannel id=$bob_id amount=16000000
bob fundchannel id=$charlie_id amount=16000000
charlie fundchannel id=$dave_id amount=16000000
dave fundchannel id=$erin_id amount=16000000
erin fundchannel id=$frank_id amount=16000000

echo "Confirm these transactions"
bitcoin -generate 6 > /dev/null

check_all_channels

echo "Franck creates a 1 Msat (= 1 Gmsat) invoice"
export invoice=$(frank invoice amount_msat=1000000000 label=01 description="Frank's first invoice" | jq -r '.bolt11')

echo "Alice pays the invoice. Note that command doesn't work immediately => wait until Alice knows a channel with Frank as destination (about 3mn!)"
until [ $(alice listchannels | jq --arg dst $frank_id -r '.channels[] | select(.destination==$dst) | length') ]
do
    sleep 5
    echo -n '.'
done
echo
alice pay bolt11=$invoice

check_all_channels

# Final result shows that fees at each node is 10 sat + 1 msat, so alice paid 50 sat + 5 msat as fees.
# Amount in intermediate nodes is slightly increased with the fees received (16000010001)
# and is rebalanced between its 2 channels, for example for bob: 14999969997 + 1000040004
# Each channel capacity remains the same at 16000000, for example between Bob and Charlie: 14999969997 + 1000030003
# Alice   => Bob:     14999959996
# Bob     => Charlie: 14999969997
# Bob     => Alice:    1000040004
# Charlie => Dave:    14999979998
# Charlie => Bob:      1000030003
# Dave    => Erin:    14999989999
# Dave    => Charlie:  1000020002
# Erin    => Frank:   15000000000
# Erin    => Dave:     1000010001
# Frank   => Erin:     1000000000

echo "Bob's HTLCs"
bob listhtlcs
echo "Bob's collected fees (amount_msat difference between in and out HTLCs: 10001 = 1000040004 - 1000030003)"
bob getinfo | jq -r '.fees_collected_msat'
