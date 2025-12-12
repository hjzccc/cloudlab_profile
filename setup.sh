#!/bin/bash
wget -P /local/tmp/ https://raw.githubusercontent.com/hjzccc/cloudlab_profile/refs/heads/main/install_dependencis.sh && \
wget -P /local/tmp/ https://raw.githubusercontent.com/hjzccc/cloudlab_profile/refs/heads/main/k8s/ssh_gateway.yaml && \
wget -P /local/tmp/ https://raw.githubusercontent.com/hjzccc/cloudlab_profile/refs/heads/main/k8s/serviceweaver_config.yaml && \
wget -P /local/tmp/ https://raw.githubusercontent.com/hjzccc/cloudlab_profile/refs/heads/main/k8s/setup_debug_container.py && \
chmod +x /local/tmp/install_dependencis.sh && \
/local/tmp/install_dependencis.sh && \
pip install kubernetes uuid && \
sudo chmod 644 /etc/rancher/k3s/k3s.yaml && \
kubectl apply -f /local/tmp/ssh_gateway.yaml && \
go install github.com/ServiceWeaver/weaver-kube/cmd/weaver-kube@v0.23.0