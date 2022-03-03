
# Talos Production Cluster Bootstrap for Hetzner
This project is intended to offer an easy way to host a production ready k8s talos cluster on Hetzner Cloud.

- Easy going by just running a single command:
  `./clustercontrol.sh`
- The cluster is secured by 2 firewalls, only allowing wireguard as access endpoint, so no administration api endpoint is reachable from the public.
- The services provided by the cluster are published with a load balancer controlled by ingress-nginx and the `hetzner-cluster-controller-manager`


## How it works:
This project provides a local docker container containing all useful tools needed for the bootstrap and to administrate the cluster. It also features a wireguard-connection inside the container after the cluster was bootstrapped.

### Tools:
- terraform
- kubectl
- talosctl
- packer
- ansible
- kubediff
- helm
- kubectx
- kubens
- yq
- flux
- fluxctl
- wireguard




## Configuration

Please create a .env file with your settings based on sample.env.



## References
### Wireguard inside Docker in Windows:
https://centerorbit.medium.com/installing-wireguard-in-wsl-2-dd676520cb21