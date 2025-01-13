#!/bin/bash

# Exit on error
set -e

# Function to display messages with colors
display_message() {
    local message="$1"
    local color="$2"
    case $color in
        red) echo -e "\033[91m${message}\033[0m" ;;
        green) echo -e "\033[92m${message}\033[0m" ;;
        yellow) echo -e "\033[93m${message}\033[0m" ;;
        blue) echo -e "\033[94m${message}\033[0m" ;;
        magenta) echo -e "\033[95m${message}\033[0m" ;;
        cyan) echo -e "\033[96m${message}\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Display banner
display_banner() {
    display_message "###########################################" "cyan"
    display_message "#      Kubernetes Deployment Tool         #" "magenta"
    display_message "#        RDP Environment Setup            #" "magenta"
    display_message "###########################################" "cyan"
}

# Check for Azure authentication
check_azure_authentication() {
    az account show &> /dev/null
    if [ $? -ne 0 ]; then
        display_message "Please authenticate to your Azure account using 'az login --use-device-code'." "red"
        exit 1
    fi
}

# Delete older Azure resource groups
delete_old_resource_groups() {
    az group list --query "[?starts_with(name, 'MFA-Bypass')].name" -o tsv | while read -r group; do
        az group delete --name "$group" --yes --no-wait &> /dev/null
        if [ $? -eq 0 ]; then
            display_message "Successfully deleted resource group $group." "green"
        else
            display_message "Failed to delete resource group $group." "red"
        fi
    done
}

# Generate a random password
generate_random_password() {
    echo $(openssl rand -base64 12)
}

# Deploy Docker container in Azure Kubernetes Service
deploy_docker_in_aks() {
    local resource_group="$1"
    local aks_name="tiny-remote-desktop-aks-$RANDOM"
    local location="eastus"
    local node_count=1
    local dns_name="tiny-remote-desktop-$RANDOM"
    local vnc_password=$(generate_random_password)

    display_message "Creating Azure Kubernetes Service cluster..." "blue"

    az aks create \
        --resource-group "$resource_group" \
        --name "$aks_name" \
        --node-count "$node_count" \
        --generate-ssh-keys \
        --location "$location" > /dev/null

    if [ $? -ne 0 ]; then
        display_message "Failed to create Azure Kubernetes Service cluster." "red"
        exit 1
    fi

    display_message "Azure Kubernetes Service cluster '$aks_name' created successfully." "green"

    display_message "Configuring kubectl for AKS..." "blue"
    az aks get-credentials --resource-group "$resource_group" --name "$aks_name" --overwrite-existing > /dev/null

    display_message "Deploying RDP container to AKS..." "blue"

    # Create Kubernetes manifest for the deployment and service
   cat <<EOF > tiny-remote-desktop-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tiny-remote-desktop
  labels:
    app: tiny-remote-desktop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tiny-remote-desktop
  template:
    metadata:
      labels:
        app: tiny-remote-desktop
    spec:
      containers:
      - name: tiny-remote-desktop
        image: soff/tiny-remote-desktop
        ports:
        - containerPort: 6901
        env:
        - name: VNC_PASSWORD
          value: "$vnc_password"
        - name: RESOLUTION
          value: "1920x1080"
---
apiVersion: v1
kind: Service
metadata:
  name: tiny-remote-desktop-service
spec:
  selector:
    app: tiny-remote-desktop
  ports:
  - protocol: TCP
    port: 6901
    targetPort: 6901
  type: LoadBalancer
EOF

    kubectl apply -f tiny-remote-desktop-deployment.yaml > /dev/null

    display_message "Waiting for external IP assignment..." "yellow"
    sleep 30

    local external_ip=""
    while [[ -z "$external_ip" ]]; do
        external_ip=$(kubectl get service tiny-remote-desktop-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        if [[ -z "$external_ip" ]]; then
            display_message "Still waiting for external IP..." "yellow"
            sleep 10
        fi
    done

    display_message "RDP container deployed successfully." "green"
    display_message "Access the RDP environment at: http://$external_ip:6901" "cyan"

    # Display connection details
    display_message "Connection details:" "magenta"
    echo "VNC Password: $vnc_password"
    echo "Public IP: $external_ip"
}

# Main script execution
main() {
    display_banner

    local RESOURCE_GROUP="MFA-Bypass-Docker-RG$RANDOM"
    local LOCATION="eastus"

    while getopts "r:" opt; do
        case $opt in
            r) ALLOWED_IP="$OPTARG" ;;
            *) display_message "Invalid option." "red"; exit 1 ;;
        esac
    done

    if [[ -z "$ALLOWED_IP" ]]; then
        display_message "Usage: $0 -r <allowed_ip_cidr>" "red"
        exit 1
    fi

    display_message "Starting RDP environment setup in Azure Kubernetes Service..." "blue"

    # Check Azure authentication
    check_azure_authentication

    # Delete old resource groups
    delete_old_resource_groups

    display_message "Creating resource group..." "blue"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" > /dev/null
    display_message "Resource group '$RESOURCE_GROUP' created successfully." "green"

    # Deploy Docker container in AKS
    deploy_docker_in_aks "$RESOURCE_GROUP"

    display_message "Setup complete. Use the URL provided to access the RDP environment." "green"
}

main "$@"
