#!/bin/bash

# Output CSV header
echo "VMName,BackupEnabled,SubscriptionName"

# Get the list of subscription IDs and names
subscriptions=$(az account list --query "[].{id:id,name:name,state:state}" -o json | jq -r '.[] | select(.state == "Enabled") | "\(.id),\(.name)"')

# Iterate over each subscription
IFS=$'\n'
for subscription in $subscriptions; do
    subscription_id=$(echo "$subscription" | cut -d',' -f1)
    subscription_name=$(echo "$subscription" | cut -d',' -f2)

    # Set the current subscription context
    az account set --subscription "$subscription_id"

    # Get a list of all resource groups in the current subscription
    resourceGroups=$(az group list --query '[].name' --output tsv)

    # Iterate through each resource group
    while read -r resourceGroup; do
        # Get a list of all VMs in the current resource group
        vms=$(az vm list --resource-group "$resourceGroup" --query '[].name' --output tsv)

        # Iterate through each VM
        while read -r vmName; do
            # Get backup status for the VM
            backupStatus=$(az backup protection check-vm --vm-id "/subscriptions/$subscription_id/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName" --query 'status')

            # Check if the VM backup is enabled
            if [ "$backupStatus" == "\"Protected\"" ]; then
                echo "$vmName,true,$subscription_name"
            else
                echo "$vmName,false,$subscription_name"
            fi
        done

