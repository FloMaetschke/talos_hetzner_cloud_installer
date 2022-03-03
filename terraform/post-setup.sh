echo Wating for Kubernetes to get ready:
sleep 30
status=1

while [ $status -ne 0 ]; do
    echo waiting ...
    kubectl wait --for=condition=Ready pods --all --all-namespaces
    status=$?
done

# kubectl create secret generic hcloud -n kube-system \
#     --from-literal=token=$HCLOUD_TOKEN \
#     --from-literal=network='talos'

# echo Terminating old Flannel and intializing new Flannel Overlay-Network on ETH1
# kubectl patch daemonset kube-flannel -n kube-system --type "json" --patch "$(yq e -o=j -I=0 flannel-interface-patch.yaml)"
# kubectl rollout status daemonset/kube-flannel -n kube-system
# echo "Done Waiting for CoreDNS!"

status=1
while [ $status -ne 0 ]; do
    echo "Waiting for CoreDNS ..."
    kubectl rollout status deployment/coredns -n kube-system
    status=$?
done

## TODO: Add generic fluxcd install here!
