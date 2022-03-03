PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(echo $PRIVATE_KEY | wg pubkey)

declare -x "WG_$(echo $1)_PRIVATE_KEY"=$PRIVATE_KEY
declare -x "WG_$(echo $1)_PUBLIC_KEY"=$PUBLIC_KEY
