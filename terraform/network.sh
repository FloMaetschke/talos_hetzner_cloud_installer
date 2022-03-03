#!/bin/bash
echo $1

source generate_wg_keys.sh SERVER

cat <<EOL >controlplane_patch.yaml
- op: add
  path: "/cluster/extraManifests"
  value:
    - https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.6.0/deploy/kubernetes/hcloud-csi.yml

- op: add
  path: "/cluster/inlineManifests"
  value:
    - name: hcloud-csi-secret
      contents: |-
        ---
        ### THIS SECRET IS FOR HCLOUD_CSI EXTRA MANIFEST ###
        apiVersion: v1
        kind: Secret
        metadata:
          name: hcloud-csi
          namespace: kube-system
        stringData:
          token: $HCLOUD_TOKEN
    - name: hcloud-controller-manager
      contents: |-
        ---
        apiVersion: v1
        kind: Secret
        metadata:
          name: hcloud
          namespace: kube-system
        type: Opaque
        stringData:
          token: $HCLOUD_TOKEN
          network: talos
        ---
        apiVersion: v1
        kind: ServiceAccount
        metadata:
          name: cloud-controller-manager
          namespace: kube-system
        ---
        apiVersion: scheduling.k8s.io/v1
        kind: PriorityClass
        metadata:
          name: high-priority
        value: 1000000
        globalDefault: false
        description: "This priority class should be used for XYZ service pods only."
        ---
        kind: ClusterRoleBinding
        apiVersion: rbac.authorization.k8s.io/v1
        metadata:
          name: system:cloud-controller-manager
        roleRef:
          apiGroup: rbac.authorization.k8s.io
          kind: ClusterRole
          name: cluster-admin
        subjects:
          - kind: ServiceAccount
            name: cloud-controller-manager
            namespace: kube-system
        ---
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: hcloud-cloud-controller-manager
          namespace: kube-system
        spec:
          replicas: 1
          revisionHistoryLimit: 2
          selector:
            matchLabels:
              app: hcloud-cloud-controller-manager
          template:
            metadata:
              labels:
                app: hcloud-cloud-controller-manager
            spec:
              priorityClassName: high-priority
              serviceAccountName: cloud-controller-manager
              dnsPolicy: Default
              tolerations:
                # this taint is set by all kubelets running $(--cloud-provider=external)
                # so we should tolerate it to schedule the cloud controller manager
                - key: "node.cloudprovider.kubernetes.io/uninitialized"
                  value: "true"
                  effect: "NoSchedule"
                - key: "CriticalAddonsOnly"
                  operator: "Exists"
                # cloud controller manages should be able to run on masters
                - key: "node-role.kubernetes.io/master"
                  effect: NoSchedule
                - key: "node.kubernetes.io/not-ready"
                  effect: "NoSchedule"
              hostNetwork: true
              containers:
                - image: hetznercloud/hcloud-cloud-controller-manager:v1.12.1
                  name: hcloud-cloud-controller-manager
                  command:
                    - "/bin/hcloud-cloud-controller-manager"
                    - "--cloud-provider=hcloud"
                    - "--leader-elect=false"
                    - "--allow-untagged-cloud"
                    - "--allocate-node-cidrs=true"
                    - "--cluster-cidr=10.42.0.0/16"
                  resources:
                    requests:
                      cpu: 100m
                      memory: 50Mi
                  env:
                    - name: NODE_NAME
                      valueFrom:
                        fieldRef:
                          fieldPath: spec.nodeName
                    - name: HCLOUD_TOKEN
                      valueFrom:
                        secretKeyRef:
                          name: hcloud
                          key: token
                    - name: HCLOUD_NETWORK
                      valueFrom:
                        secretKeyRef:
                          name: hcloud
                          key: network
- op: add
  path: "/machine/network/interfaces"
  value:
    - interface: eth0
      mtu: 0
      dhcp: true
    - interface: eth1
      mtu: 0
      dhcp: true
    - interface: wg0
      addresses:
        - 10.20.0.1/24
      mtu: 0
      wireguard:
        privateKey: $WG_SERVER_PRIVATE_KEY
        listenPort: 51111
        peers:
EOL

echo Generating $WIREGUARD_CLIENT_COUNT client configs ...
echo
for ((i = 1; i <= $WIREGUARD_CLIENT_COUNT; i++)); do
  private_key_name="WG_CLIENT${i}_PRIVATE_KEY"
  public_key_name="WG_CLIENT${i}_PUBLIC_KEY"
  source generate_wg_keys.sh "CLIENT${i}"

  cat <<EOL >>controlplane_patch.yaml
          - publicKey: ${!public_key_name}
            persistentKeepaliveInterval: 25s
            allowedIPs:
              - 10.20.0.10${i}/32
EOL
  cat <<EOL >"wireguard/client${i}.conf"
[Interface]
PrivateKey = ${!private_key_name}
Address = 10.20.0.10${i}/32

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = SERVER_IP_ADDRESS:51111
AllowedIPs = 10.20.0.1/24
EOL
  echo " --> wireguard/client${i}.conf created"
done
echo
echo "SERVER_IP_ADDRESS in client config(s) will be patched later."
echo
talosctl gen config talos-cluster https://10.29.0.2:6443 \
  --output-dir ../settings/ \
  --with-kubespan \
  --config-patch "$(yq e -o=j -I=0 cluster_patch.yaml)" \
  --config-patch-control-plane "$(yq e -o=j -I=0 controlplane_patch.yaml)" \
  --config-patch-worker "$(yq e -o=j -I=0 worker_patch.yaml)"

talosctl validate --config ../settings/controlplane.yaml --mode cloud
talosctl validate --config ../settings/worker.yaml --mode cloud
