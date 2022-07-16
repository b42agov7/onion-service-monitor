#!/bin/bash
# version 0.1
# b42agov7
# 2022-07-12

set -eE -o pipefail
trap 'echo "$0:$LINENO:error: \"$BASH_COMMAND\" returned $?" >&2' ERR

# variables
mail_address="YOUR-MAIL-ADDRESS"
hidden_service_dir="YOUR-HIDDEN-SERVICE-DIR"
onion_service_address=$(cat /var/lib/tor/${hidden_service_dir}/hostname)

# main
[[ ! -e /var/log/tor/${hidden_service_dir}.error.log ]] && touch /var/log/tor/${hidden_service_dir}.error.log

if [[ ! -e /var/lib/tor/${hidden_service_dir}/hostname ]]; then
        echo "$0: [ERROR]: The hostname file for your Onion Service doesn't exists." >> /var/log/tor/${hidden_service_dir}.error.log
        mail -s "[ERROR]: The hostname file for your Onion Service doesn't exists." ${mail_address}
        exit 1
fi

if ! curl_output=$(curl -ILs --socks5-hostname 127.0.0.1:9050 ${onion_service_address} 2>&1); then
        echo "$0: [ERROR]: Curl to Onion Service failed. Output: ${curl_output}" >> /var/log/tor/${hidden_service_dir}.error.log
        mail -s "[ERROR] Curl to Onion Service failed. See logs." ${mail_address}
        exit 1
fi

http_code=$(printf "%s\n" "$curl_output" | grep ^HTTP | tail -n1 | awk '{print $2}')

if [[ ${http_code} -ne 200 ]]; then
        echo "$0: [ERROR]: The Onion Service is down." >> /var/log/tor/${hidden_service_dir}.error.log
        mail -s "[ERROR]: The onion Service is down." ${mail_address}
        exit 1
fi
