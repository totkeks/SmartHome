#!/bin/sh

usage() {
	echo "Usage: $0 <action> <client_name> [--force] [--raw]"
	echo ""
	echo "Actions:"
	echo "  add     Add a new WireGuard client"
	echo "  remove  Remove an existing WireGuard client"
	echo ""
	echo "Options:"
	echo "  --force Overwrite existing client (only applicable for add action)"
	echo "  --raw   Show the raw client configuration instead of a QR code"
	echo ""
	echo "Examples:"
	echo "  $0 add phone"
	echo "  $0 add tablet --force"
	echo "  $0 add laptop --raw"
	echo "  $0 remove phone"
	exit 1
}

get_client_section() {
	local name="$1"
	uci show network | grep "description='$name'" | awk -F'[][]' '{print $2}'
}

restart_vpn_service() {
	ifup vpn
}

remove_client() {
	local name="$1"
	local section
	section=$(get_client_section "$name")

	if [ -z "$section" ]; then
		echo "Error: Client '$name' not found."
		exit 1
	fi

	echo "Removing client '$name'..."
	rm -f "/etc/wireguard/clients/$name"
	uci delete network.@wireguard_vpn["$section"]
	uci commit network
	restart_vpn_service

	echo "Client '$name' has been removed successfully."
}

add_client() {
	local name="$1"
	local force="$2"
	local raw="$3"
	local section

	section=$(get_client_section "$name")

	if [ -n "$section" ]; then
		if [ "$force" -eq 1 ]; then
			echo "Client '$name' already exists. Overwriting due to --force flag."
			remove_client "$name"
		else
			echo "Error: Client '$name' already exists. Use --force to overwrite."
			exit 1
		fi
	fi

	CLIENT_PRIVATE_KEY=$(wg genkey)
	CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
	CLIENT_PRESHARED_KEY=$(wg genpsk)

	SERVER_PUBLIC_KEY=$(cat /etc/wireguard/publickey)
	SERVER_ENDPOINT='${DOMAIN}:51820'

	NEXT_IP=10
	CURRENT_IPS=$(uci show network | grep 'allowed_ips=' | grep -o '10\.10\.50\.[0-9]\+\/32' | cut -d '.' -f4 | cut -d '/' -f1)

	while echo "$CURRENT_IPS" | grep -qw "$NEXT_IP"; do
		NEXT_IP=$((NEXT_IP + 1))
		if [ "$NEXT_IP" -gt "254" ]; then
			echo "Error: Exceeded the maximum number of clients. Cannot assign IP."
			exit 1
		fi
	done

	CLIENT_IPV4="10.10.50.$NEXT_IP/32"
	CLIENT_IPV6="fdde:adc0:0c1e:50::$NEXT_IP/128"

	uci add network wireguard_vpn
	uci set network.@wireguard_vpn[-1].public_key="$CLIENT_PUBLIC_KEY"
	uci set network.@wireguard_vpn[-1].preshared_key="$CLIENT_PRESHARED_KEY"
	uci set network.@wireguard_vpn[-1].description="$name"
	uci add_list network.@wireguard_vpn[-1].allowed_ips="$CLIENT_IPV4"
	uci add_list network.@wireguard_vpn[-1].allowed_ips="$CLIENT_IPV6"
	uci commit network
	restart_vpn_service

	cat <<EOF > /etc/wireguard/clients/"$name"
PublicKey=$CLIENT_PUBLIC_KEY
PresharedKey=$CLIENT_PRESHARED_KEY
AllowedIPs="$CLIENT_IPV4 $CLIENT_IPV6"
EOF
	chmod 600 /etc/wireguard/clients/"$name"

	CLIENT_CONFIG=$(cat <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = ${CLIENT_IPV4%/*}/24, ${CLIENT_IPV6%/*}/64
DNS = 10.10.50.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
PresharedKey = $CLIENT_PRESHARED_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF
)
	if [ "$raw" -eq 1 ]; then
		echo "$CLIENT_CONFIG"
	else
		echo "$CLIENT_CONFIG" | qrencode -t ansiutf8
	fi
}

if [ $# -lt 2 ]; then
	usage
fi

ACTION="$1"
CLIENT_NAME="$2"
FORCE=0
RAW=0

if [ "$#" -gt 4 ]; then
	echo "Error: Too many arguments"
	usage
fi

shift 2
for option in "$@"; do
	case "$option" in
		--force)
			FORCE=1
			;;
		--raw)
			RAW=1
			;;
		*)
			echo "Error: Unknown option '$option'"
			usage
			;;
	esac
done

if [ "$ACTION" = "remove" ] && { [ "$FORCE" -eq 1 ] || [ "$RAW" -eq 1 ]; }; then
	echo "Error: Options are only valid for add action"
	usage
fi

case "$ACTION" in
	add)
		add_client "$CLIENT_NAME" "$FORCE" "$RAW"
		;;
	remove)
		remove_client "$CLIENT_NAME"
		;;
	*)
		echo "Error: Unknown action '$ACTION'"
		usage
		;;
esac
