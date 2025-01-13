# Azure Kubernetes Remote Desktop Deployment Script

## Overview
This repository contains the `azaksremotedeployment.sh` script, which simplifies the deployment of a Remote Desktop environment on Azure Kubernetes Service (AKS). The script ensures that only specific IP addresses can access the environment via port 6901.

---

## Features
- Requires specifying Allowed IP ranges using the `-r` flag.
- Automatically deletes old resource groups created by the script to maintain a clean Azure environment.

---

## Usage
### Basic Usage
### How to Use
#### Bash
```
az login --use-device-code && git clone https://github.com/crtvrffnrt/azaksremotedeployment.git && chmod +x ./azaksremotedeployment/azaksremotedeployment.sh && ./azaksremotedeployment/azaksremotedeployment.sh -r "$yourPublicip/32"
```
Run the script to create a new Remote Desktop environment accessible only from your current public IP:

### Alternative from Azure Portal
1. Login to Azure
2. Open Azure CLI & switch to bash
```
git clone https://github.com/crtvrffnrt/azaksremotedeployment.git && chmod +x ./azaksremotedeployment/azaksremotedeployment.sh && ./azaksremotedeployment/azaksremotedeployment.sh -r "$yourPublicip/32"
```
3. Change your Public IP in `$yourPublicip/32`
4. Wait until the environment is created and connection details are provided.
5. Run the provided commands on your host PC to connect.

---

## Options
### Specify Additional IP Ranges
You can allow access for both your current public IP and an additional range using the `-r` flag:

```bash
./azaksremotedeployment.sh -r "198.51.100.10/32"
```

In this example, port 6901 will be accessible from:
- The specified IP range `198.51.100.10/32`

---

## Note on Remote Access
The environment provides Remote Desktop access via a web interface. Ensure you:
1. Use the provided URL and credentials to connect.
2. Keep your VNC password secure, as it will be shown during deployment.

---

## Connection

### Access the RDP Environment
#### Windows
```Powershell
cmdkey /generic:"$PublicIp" /user:"adminuser" /pass:"$pass"; mstsc /v:$publicip
```

#### Linux
```bash
xfreerdp /v:$publicip /u:adminuser /p:"$pass" /cert:ignore
```

---

## Cleanup
Old resource groups created by this script are automatically deleted to keep your Azure environment organized. If you wish to disable this behavior, modify the script accordingly.

---

![image](https://github.com/user-attachments/assets/46273c07-e789-4e9e-8c1a-6156c173b98c)
