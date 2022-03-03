#!/bin/bash

# while-menu-dialog: a menu driven system information program

DIALOG_CANCEL=1
DIALOG_ESC=255
HEIGHT=0
WIDTH=0

WG_CLIENT_FILE=/kubernetes/terraform/wireguard/client1.conf
if test -f "$WG_CLIENT_FILE"; then
    echo "$WG_CLIENT_FILE exists. Creating Wireguard tunnel ..."
    wg-quick up $WG_CLIENT_FILE
    wg
    WG_IP=$(ip address | grep "global client1")
    WG_DISCONNECTED=""
else
    echo no Wireguard tunnel found.
    WG_DISCONNECTED="NO TUNNEL FOUND"
fi

TALOS_DISK_IMAGE=$(hcloud image list -o columns=labels,id -o noheader | grep "os=talos")

display_result() {
    dialog --title "$1" \
        --no-collapse \
        --msgbox "$result" 0 0
}

#inet 10.20.0.101/32 scope global client1

while true; do
    exec 3>&1
    selection=$(
        dialog \
            --backtitle $"Clustercontrol v0.1.3      Talos Release: ${TALOS_DISK_IMAGE:30:7} (IMG_ID:${TALOS_DISK_IMAGE:39:9})   Wireguard: ${WG_IP:9:14}${WG_DISCONNECTED}" \
            --title "Menu" \
            --clear \
            --no-lines \
            --cancel-label "Exit" \
            --menu "Please select:" $HEIGHT $WIDTH 4 \
            "1" "Shell" \
            "2" "Create Cluster" \
            "3" "Destroy Cluster" \
            "4" "Create Talos Image Snaphot" \
            2>&1 1>&3
    )
    exit_status=$?
    exec 3>&-
    case $exit_status in
    $DIALOG_CANCEL)
        clear
        echo "Clustercontrol terminated."
        exit
        ;;
    $DIALOG_ESC)
        clear
        echo "Clustercontrol aborted." >&2
        exit 1
        ;;
    esac
    case $selection in
    1)
        clear
        bash
        ;;
    2)
        cd /kubernetes/terraform
        terraform apply -auto-approve
        bash post-setup.sh
        result="Cluster successfully deployed!"
        display_result "Cluster Deployment"
        ;;
    3)
        cd /kubernetes/terraform
        terraform destroy -auto-approve
        result="Cluster successfully destroyed!"
        display_result "Cluster Status"
        ;;
    4)
        clear
        cd /kubernetes/packer
        packer init .
        packer build .
        ;;

    esac
done
