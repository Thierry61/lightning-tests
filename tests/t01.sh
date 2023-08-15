echo "Create a mining wallet, generate an address and mine 100 blocks to it (3 times)"
bitcoin createwallet wallet1
# Don't use bitcoin -generate because addresses are provided unordered by bitcoin getaddressesbylabel ""
export addr1=$(bitcoin getnewaddress); bitcoin generatetoaddress 100 $addr1 > /dev/null
export addr2=$(bitcoin getnewaddress); bitcoin generatetoaddress 100 $addr2 > /dev/null
export addr3=$(bitcoin getnewaddress); bitcoin generatetoaddress 100 $addr3 > /dev/null

echo "Check amount in each address"
echo "addr1: $(bitcoin getreceivedbyaddress $addr1)"
echo "addr2: $(bitcoin getreceivedbyaddress $addr2)"
echo "addr3:    $(bitcoin getreceivedbyaddress $addr3)"

# Intermediate result is:
# addr1: 5000.00000000
# addr2: 3725.00000000
# addr3:    0.00000000

echo "Move 20 BTC to addr1"
export tx_id=$(bitcoin sendtoaddress $addr1 20 "" "" false true 6 "economical" false)

echo "Mine 100 blocks to a 4th address"
export addr4=$(bitcoin getnewaddress); bitcoin generatetoaddress 100 $addr4 > /dev/null
bitcoin generatetoaddress 100 $addr4 > /dev/null

echo "Check amount in each address"
# Remarks:
# - getreceivedbyaddress is not useable anymore as an address was spent => use listaddressgroupings instead
# - 25BTC were taken out of addr2
# - the fee (0.00000141) was added to addr4
# - the change (4.99999859) was added to a new address => transaction output different from 20BTC
export change_addr=$(bitcoin gettransaction $tx_id true true | jq -r '.decoded.vout | .[] | select(.value!=20).scriptPubKey.address')
echo "addr1: $(bitcoin listaddressgroupings | jq --arg addr $addr1 -r '.[]|.[]|select(.[0]==$addr)[1]')"
echo "addr2: $(bitcoin listaddressgroupings | jq --arg addr $addr2 -r '.[]|.[]|select(.[0]==$addr)[1]')"
echo "addr3: $(bitcoin listaddressgroupings | jq --arg addr $addr3 -r '.[]|.[]|select(.[0]==$addr)[1]')"
echo "addr4: $(bitcoin listaddressgroupings | jq --arg addr $addr4 -r '.[]|.[]|select(.[0]==$addr)[1]')"
echo "change:   $(bitcoin listaddressgroupings | jq --arg addr $change_addr -r '.[]|.[]|select(.[0]==$addr)[1]')"

# Final result is:
# addr1: 5020
# addr2: 3700
# addr3: 2487.5
# addr4: 1250.00000141
# change:   4.99999859
