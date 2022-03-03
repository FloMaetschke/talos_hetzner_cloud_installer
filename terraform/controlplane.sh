echo "Updating $WIREGUARD_CLIENT_COUNT wireguard client configs with server ip ..."
for ((i = 1; i <= $WIREGUARD_CLIENT_COUNT; i++)); do
    sed -i "s/SERVER_IP_ADDRESS/${1/$'\r'/}/g" "wireguard/client${i}.conf"
    echo "--> wireguard/client${i}.conf updated"
done

echo Waiting for controleplane node to become available ...
sleep 40
talosctl --talosconfig ../settings/talosconfig config endpoint 10.20.0.1
talosctl --talosconfig ../settings/talosconfig config node 10.20.0.1
talosctl apply-config --insecure --nodes ${1/$'\r'/} --endpoints ${1/$'\r'/} --file ../settings/controlplane.yaml
sleep 70
talosctl --talosconfig ../settings/talosconfig bootstrap --nodes ${1/$'\r'/} --endpoints ${1/$'\r'/}
talosctl --talosconfig ../settings/talosconfig kubeconfig ../settings/kubeconfig --nodes ${1/$'\r'/} --endpoints ${1/$'\r'/}
sed -i "s/10.29.0.2/10.20.0.1/g" ../settings/kubeconfig
modprobe wireguard
wg-quick up wireguard/client1.conf
