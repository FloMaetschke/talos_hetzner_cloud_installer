FROM ubuntu:latest as system
RUN apt-get update
RUN apt-get update

FROM system AS deps
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y gnupg software-properties-common curl apt-transport-https ca-certificates python3-pip git fish wget wireguard-dkms wireguard-tools iproute2

FROM deps AS wireguardkernel
RUN mkdir /workspace && \
    cd workspace && \
    git clone --branch linux-msft-wsl-4.19.y --depth 1 https://github.com/microsoft/WSL2-Linux-Kernel.git && \
    git clone --depth 1 https://git.zx2c4.com/wireguard-linux-compat && \
    git clone --depth 1 https://git.zx2c4.com/wireguard-tools

RUN apt-get -y install libelf-dev build-essential pkg-config && \
    apt-get -y install bison build-essential flex libssl-dev libelf-dev bc

RUN cd /workspace/WSL2-Linux-Kernel && \
    zcat /proc/config.gz > .config && \
    make -j $(nproc) && \
    make -j $(nproc) modules_install && \
    cd /lib/modules && \
    ln -s $(uname -r)+/ $(uname -r)

RUN cd /workspace && \
    make -C wireguard-linux-compat/src -j$(nproc) && \
    make -C wireguard-linux-compat/src install && \
    make -C wireguard-tools/src -j$(nproc) && \
    make -C wireguard-tools/src install && \
    ls /lib/modules/$(uname -r)/extra/

FROM wireguardkernel AS clustertools
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt-add-repository ppa:ansible/ansible
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
RUN curl https://baltocdn.com/helm/signing.asc | apt-key add -
RUN echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3EFE0E0A2F2F60AA
RUN echo "deb http://ppa.launchpad.net/tektoncd/cli/ubuntu eoan main"|sudo tee /etc/apt/sources.list.d/tektoncd-ubuntu-cli.list
RUN curl -Lo /usr/local/bin/talosctl https://github.com/talos-systems/talos/releases/latest/download/talosctl-$(uname -s | tr "[:upper:]" "[:lower:]")-amd64
RUN chmod +x /usr/local/bin/talosctl
RUN curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
RUN chmod a+x /usr/local/bin/yq
RUN curl -L https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz | tar xvz -C /usr/local/bin/ hcloud
RUN chmod a+x /usr/local/bin/hcloud
RUN apt-get update && apt-get install -y terraform ansible kubectl helm nano mc packer iputils-ping dialog tektoncd-cli
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx
RUN ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
RUN ln -s /opt/kubectx/kubens /usr/local/bin/kubens
RUN helm plugin install https://github.com/databus23/helm-diff
WORKDIR /kubernetes
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
RUN mv kustomize /bin/
RUN curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh
RUN curl -s https://fluxcd.io/install.sh | bash 
RUN curl -Lo /usr/local/bin/fluxctl https://github.com/fluxcd/flux/releases/latest/download/fluxctl_linux_amd64
RUN chmod a+x /usr/local/bin/fluxctl
RUN curl -L https://github.com/fluxcd/webui/releases/download/v0.1.1/flux-webui_0.1.1_linux_amd64.tar.gz | tar xvz -C /usr/local/bin/ flux-webui
RUN chmod a+x /usr/local/bin/flux-webui


RUN echo "alias k=kubectl" >> /root/.bashrc
RUN echo "alias tf=terraform" >> /root/.bashrc
RUN echo "eval \"\$(ssh-agent)\"" >> /root/.bashrc
RUN echo "chmod 600 /kubernetes/keys/*" >> /root/.bashrc
RUN echo "ssh-add /kubernetes/keys/cluster.key" >> /root/.bashrc
RUN echo ". <(flux completion bash)" >> /root/.bashrc
FROM clustertools
ENV ANSIBLE_CONFIG=/kubernetes/ansible/ansible.cfg
#COPY . .
