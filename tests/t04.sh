# Create a dual funded channel

echo "Create a mining wallet"
bitcoin createwallet wallet1

echo "Mine 100 blocks and ensure that the first ten coinbase outputs are spendable"
bitcoin -generate 100 > /dev/null
bitcoin -generate 10 > /dev/null

echo "Create a bitcoin address for Alice, Bob and Charlie and move 2 BTC to each of them"
bitcoin sendtoaddress $(alice   newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(bob     newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(charlie newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false

echo "Confirm these transactions and wait 30s"
bitcoin -generate 6 > /dev/null
sleep 30

echo "Connect everyone"
alice connect id=$bob_id host=$bob_ip
alice connect id=$charlie_id host=$charlie_ip
bob   connect id=$charlie_id host=$charlie_ip

# A chain of channels is needed so that Bob appear in Alice node list.
# (direct connections are not enough)
echo "Create regular channels from Alice to Charlie and from Bob to Charlie"
alice fundchannel id=$charlie_id amount=16000000
bob   fundchannel id=$charlie_id amount=16000000
echo "Confirm these transactions"
bitcoin -generate 6 > /dev/null

echo "Setup Bob's lease policy" # see https://medium.com/blockstream/setting-up-liquidity-ads-in-c-lightning-54e4c59c091d
bob funderupdate policy=match policy_mod=100 \
    lease_fee_base_msat=100sat lease_fee_basis=100

echo "Wait until Alice knows about Bob's node"
while true
do
    if [ $(alice listnodes id=$bob_id | jq -r '.nodes[] | length') ]
    then
        break
    fi
    sleep 5
    echo -n '.'
done
echo

echo "Wait until Alice knows about Bob's compact lease"
while true
do
    export compact_lease=$(alice listnodes id=$bob_id | jq -r '.nodes[0].option_will_fund.compact_lease')
    if [ $compact_lease != null ]
    then
        break
    fi
    sleep 5
    echo -n '.'
done
echo

# TODO: Make next command work. Errors are:
# - in stdout: "You gave bad parameters: We requested 250000sat, which is more than they've offered to provide (0sat)"
# - in both Alice and Bob logs: "Unsaved peer failed. Deleting channel"
#echo "Create dual channel between Alice and Bob"
#alice fundchannel id=$bob_id amount=500000 request_amt=250000 feerate=6432000perkw compact_lease="$compact_lease"

#echo "Confirm these transactions"
#bitcoin -generate 6 > /dev/null

#echo "Bob creates an invoice"
#export invoice=$(bob invoice amount_msat=11000000 label=01 description="Bob's first invoice" | jq -r '.bolt11')

#echo "Alice pays the invoice"
#alice pay bolt11=$invoice
