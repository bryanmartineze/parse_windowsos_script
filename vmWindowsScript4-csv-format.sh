#!/bin/bash

# Output CSV header
echo "VMName,Offer,SKU,LicensePolicy,SubscriptionName"

# Get the list of subscription IDs and names
subscriptions=$(az account list --query "[].{id:id,name:name,state:state}" -o json | jq -r '.[] | select(.state == "Enabled") | "\(.id),\(.name)"')

# Iterate over each subscription
IFS=$'\n'
for subscription in $subscriptions; do
    subscription_id=$(echo $subscription | cut -d',' -f1)
    subscription_name=$(echo $subscription | cut -d',' -f2)

    # Set the current subscription context
    az account set --subscription $subscription_id

    # Run the Azure CLI command for the current subscription and transform output to CSV
    az vm list --query "[?storageProfile.imageReference.sku=='2012-Datacenter' || storageProfile.imageReference.sku=='2012-datacenter-gensecond' || storageProfile.imageReference.sku=='2012-Datacenter-smalldisk' || storageProfile.imageReference.sku=='2012-datacenter-smalldisk-g2' || storageProfile.imageReference.sku=='2012-Datacenter-zhcn' || storageProfile.imageReference.sku=='2012-datacenter-zhcn-g2' || storageProfile.imageReference.sku=='2012-R2-Datacenter' || storageProfile.imageReference.sku=='2012-r2-datacenter-gensecond' || storageProfile.imageReference.sku=='2012-R2-Datacenter-smalldisk' || storageProfile.imageReference.sku=='2012-r2-datacenter-smalldisk-g2' || storageProfile.imageReference.sku=='2012-R2-Datacenter-zhcn' || storageProfile.imageReference.sku=='2012-r2-datacenter-zhcn-g2' || storageProfile.imageReference.sku=='2008-Datacenter' || storageProfile.imageReference.sku=='2008-r2-datacenter' || storageProfile.imageReference.sku=='2008-Enterprise' || storageProfile.imageReference.sku=='2003-Enterprise'].{VMName:name,Offer:storageProfile.imageReference.offer,SKU:storageProfile.imageReference.sku, LicensePolicy:licenseType}" --output json | jq -r --arg subscription_name "$subscription_name" '.[] | "\(.VMName),\(.Offer),\(.SKU),\(.LicensePolicy),\($subscription_name)"'
done | sed '/^\s*$/d' # Remove empty lines

