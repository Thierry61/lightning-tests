# Measure channel propagation time

echo "Create a mining wallet"
bitcoin createwallet wallet1

echo "Mine 100 blocks and ensure that the first ten coinbase outputs are spendable"
bitcoin -generate 100 > /dev/null
bitcoin -generate 10 > /dev/null

echo "Create a bitcoin address for all nodes and move 2 BTC to each of them"
bitcoin sendtoaddress $(alice   newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(bob     newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(charlie newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(dave    newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(erin    newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false
bitcoin sendtoaddress $(frank   newaddr | jq -r '.bech32') 2 "" "" false true 6 "economical" false

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

echo "Mesure the time taken by each node to know Frank's node"
start_time=$SECONDS
for i in {1..5}
do
    if [ $i -eq 1 ]
    then
        printf "%-7s: " "Erin"
        until [ $(erin listchannels | jq --arg dst $frank_id -r '.channels[] | select(.destination==$dst) | length') ]
        do
            sleep 1
            echo -n '.'
        done
    fi
    if [ $i -eq 2 ]
    then
        printf "%-7s: " "Dave"
        until [ $(dave listchannels | jq --arg dst $frank_id -r '.channels[] | select(.destination==$dst) | length') ]
        do
            sleep 1
            echo -n '.'
        done
    fi
    if [ $i -eq 3 ]
    then
        printf "%-7s: " "Charlie"
        until [ $(charlie listchannels | jq --arg dst $frank_id -r '.channels[] | select(.destination==$dst) | length') ]
        do
            sleep 1
            echo -n '.'
        done
    fi
    if [ $i -eq 4 ]
    then
        printf "%-7s: " "Bob"
        until [ $(bob listchannels | jq --arg dst $frank_id -r '.channels[] | select(.destination==$dst) | length') ]
        do
            sleep 1
            echo -n '.'
        done
    fi
    if [ $i -eq 5 ]
    then
        printf "%-7s: " "Alice"
        until [ $(alice listchannels | jq --arg dst $frank_id -r '.channels[] | select(.destination==$dst) | length') ]
        do
            sleep 1
            echo -n '.'
        done
    fi
    echo " $(( SECONDS - start_time )) seconds"
done

# Example results: 1/2 minute for Erin, 2 minutes for Dave and Charlie, 3 minutes for Bob and 4 minutes for Alice
# Erin   : ................. 31 seconds
# Dave   : .............................................. 115 seconds
# Charlie:  116 seconds
# Bob    : ................................. 175 seconds
# Alice  : ............................... 232 seconds

# Another test was even worse: 1/2 minute for Erin, 2 minutes for Dave, 3 minutes Charlie, 4 minutes for Bob and 5 minutes for Alice
# Erin   : ................... 34 seconds
# Dave   : ............................................... 118 seconds
# Charlie: ................................. 178 seconds
# Bob    : ................................. 238 seconds
# Alice  : .............................. 293 seconds

# Another test was better: only (sic!) 3 minutes for Alice
# Erin   : ........... 21 seconds
# Dave   : .......................................... 103 seconds
# Charlie: ............................. 162 seconds
# Bob    :  163 seconds
# Alice  : .... 172 seconds
