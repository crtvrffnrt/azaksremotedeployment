## Azure Kubernetes Remote Desktop Deployment Script

This repository contains the `azaksremotedeployment.sh` script, which simplifies the deployment of a Remote Desktop environment on Azure Kubernetes Service (AKS). The script ensures that only specific IP addresses can access the environment via port 6901.

**Description**

* The script requires specifying Allowed IP ranges for api management using the `-r` flag.
* All IP`s can access Web-Url
* It automatically deletes old resource groups created by the script to maintain a clean Azure environment.

**How to Use**

Run the script to create a new Remote Desktop environment accessible only from your current public IP.

### Bash
```
az login --use-device-code && git clone https://github.com/crtvrffnrt/azaksremotedeployment.git && chmod +x ./azaksremotedeployment/azaksremotedeployment.sh && bash azaksremotedeployment/azaksremotedeployment.sh -r "$yourPublicip/32"
```

**Alternative from Azure Portal**

1. Login to Azure
2. Open Azure CLI & switch to bash
3. Change your Public IP in `$yourPublicip/32`
4. Wait until the environment is created and connection details are provided.

**Options**

**Specify Additional IP Ranges**

You can allow access for API ACCESS of Azure AKS with your current public IP and an additional range using the `-r` flag:

```bash
./azaksremotedeployment.sh -r "198.51.100.10/32"
```
**active password protection**
If set to true password is required to access Remote Destkop.


```bash
./azaksremotedeployment.sh -r "198.51.100.10/32" -p true
```


## Clean up
Old resource groups created by this script are automatically deleted to keep your Azure environment organized. If you wish to disable this behavior, modify the script accordingly.


