#!/bin/bash

# Get a list of all subscriptions
subscriptions=$(az account list --all --query '[].id' --output tsv)

# Iterate through each subscription
while read -r subscriptionId; do
    echo "Checking VMs in subscription: $subscriptionId"
    
    # Set the current subscription
    az account set --subscription "$subscriptionId"

    # Get a list of all resource groups in the current subscription
    resourceGroups=$(az group list --query '[].name' --output tsv)

    # Iterate through each resource group
    while read -r resourceGroup; do
        echo "Checking VMs in resource group: $resourceGroup"

        # Get a list of all VMs in the current resource group
        vms=$(az vm list --resource-group "$resourceGroup" --query '[].name' --output tsv)

        # Iterate through each VM
        while read -r vmName; do
            echo "Checking backup status for VM: $vmName"

            # Get backup status for the VM
            backupStatus=$(az backup protection check-vm --vm-id "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Compute/virtualMachines/$vmName" --query 'status')

            # Check if the VM is not backed up
            if [ "$backupStatus" == "\"NotProtected\"" ]; then
                echo "VM $vmName in resource group $resourceGroup is not backed up."
            else
                echo "VM $vmName in resource group $resourceGroup is backed up."
            fi
        done <<< "$vms"
    done <<< "$resourceGroups"
done <<< "$subscriptions"
