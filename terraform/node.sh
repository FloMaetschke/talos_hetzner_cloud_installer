echo Waiting for worker node to become available ...
sleep 30
echo Applying initial configuration to join cluster
talosctl apply-config --insecure --nodes ${1/$'\r'/} --file ../settings/worker.yaml
