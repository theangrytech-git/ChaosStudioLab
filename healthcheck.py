import logging
import os
import json
import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.resource import ResourceManagementClient
from azure.keyvault.secrets import SecretClient

# Set up Azure credentials
subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
tag_key = os.getenv('TARGET_TAG_KEY', 'Health')  # Change this to your desired tag key
tag_value = os.getenv('TARGET_TAG_VALUE', 'Active')  # Change this to your desired tag value

# Azure SDK Clients
credentials = DefaultAzureCredential()
compute_client = ComputeManagementClient(credentials, subscription_id)
resource_client = ResourceManagementClient(credentials, subscription_id)
kv_client = SecretClient(vault_url=os.getenv('KEY_VAULT_URL'), credential=credentials)

def get_resources_by_tag():
    """Fetches all VMs, VM Scale Sets, and VM Availability Sets with the specified tag."""
    tagged_resources = []

    # List all resource groups
    for rg in resource_client.resource_groups.list():
        # List all resources in the resource group filtered by tag
        resources = resource_client.resources.list_by_resource_group(rg.name, filter=f"tagName eq '{tag_key}' and tagValue eq '{tag_value}'")
        
        for resource in resources:
            # We are interested in VMs, VMSS, and VM Availability Sets
            if resource.type == "Microsoft.Compute/virtualMachines" or \
               resource.type == "Microsoft.Compute/virtualMachineScaleSets" or \
               resource.type == "Microsoft.Compute/availabilitySets":
                tagged_resources.append({
                    "name": resource.name,
                    "resource_group": resource.resource_group,
                    "type": resource.type
                })

    return tagged_resources

def check_vm_health(vm_name, resource_group):
    """Check the health status of a single virtual machine."""
    try:
        # Get VM instance view for status
        vm_instance = compute_client.virtual_machines.instance_view(resource_group, vm_name)
        statuses = vm_instance.statuses

        # Check status codes to determine health
        power_state = next((status.code for status in statuses if "PowerState" in status.code), "Unknown")
        provisioning_state = next((status.code for status in statuses if "ProvisioningState" in status.code), "Unknown")

        # Determine health based on power and provisioning state
        if power_state == "PowerState/running" and provisioning_state == "ProvisioningState/succeeded":
            return {"vm_name": vm_name, "status": "Healthy", "color": "green"}
        elif power_state in ["PowerState/deallocating", "PowerState/stopping"] or provisioning_state in ["ProvisioningState/updating", "ProvisioningState/creating", "ProvisioningState/migrating"]:
            return {"vm_name": vm_name, "status": "Unknown", "color": "amber"}
        elif power_state in ["PowerState/stopped", "PowerState/deallocated"] or provisioning_state in ["ProvisioningState/failed", "ProvisioningState/deleted"]:
            return {"vm_name": vm_name, "status": "Error", "color": "red"}
        else:
            return {"vm_name": vm_name, "status": "Unknown", "color": "amber"}

    except Exception as e:
        logging.error(f"Error checking VM {vm_name}: {str(e)}")
        return {"vm_name": vm_name, "status": "Error", "color": "red"}

def check_function_app_health(fa_name, resource_group):
    """Check the health status of a single Function App and fetch secrets."""
    try:
        # Get Function App status
        function_app_details = web_client.web_apps.get(resource_group, fa_name)
        fa_state = function_app_details.state

        # Fetch secrets from Key Vault
        appsecret1 = kv_client.get_secret("appsecret1").value
        appsecret2 = kv_client.get_secret("appsecret2").value

        # Determine health based on the state
        if fa_state == "Running":
            return {"fa_name": fa_name, "status": "Healthy", "color": "green", "appsecret1": appsecret1, "appsecret2": appsecret2}
        elif fa_state in ["Stopped", "StoppedDeallocated"]:
            return {"fa_name": fa_name, "status": "Error", "color": "red", "appsecret1": appsecret1, "appsecret2": appsecret2}
        else:
            return {"fa_name": fa_name, "status": "Unknown", "color": "amber", "appsecret1": appsecret1, "appsecret2": appsecret2}

    except Exception as e:
        logging.error(f"Error checking Function App {fa_name}: {str(e)}")
        return {"fa_name": fa_name, "status": "Error", "color": "red"}

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Checking health for VMs, VM Scale Sets, VM Availability Sets, and Function Apps...')

    # Initialize the response dictionary
    response_data = {
        "virtual_machines": [],
        "function_apps": []
    }

    # Get all VMs, VMSS, and Availability Sets that match the tag
    tagged_resources = get_resources_by_tag()

    # Check health for VMs, VMSS, and Availability Sets
    for resource in tagged_resources:
        if resource["type"] == "Microsoft.Compute/virtualMachines":
            health_status = check_vm_health(resource["name"], resource["resource_group"])
            response_data["virtual_machines"].append(health_status)
        # Add logic for VM Scale Sets and Availability Sets here if needed
        elif resource["type"] == "Microsoft.Compute/virtualMachineScaleSets":
             pass
        # elif resource["type"] == "Microsoft.Compute/availabilitySets":
        #     pass

    # Check health for Function Apps
    for function_app in function_app_list:
        fa_name = function_app["name"]
        resource_group = function_app["resource_group"]
        health_status = check_function_app_health(fa_name, resource_group)
        response_data["function_apps"].append(health_status)

    # Return JSON with health status for VMs, VMSS, Availability Sets, and Function Apps
    return func.HttpResponse(
        json.dumps(response_data),
        mimetype="application/json"
    )
