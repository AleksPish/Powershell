$IP = "<IP_ADDRESS>"
Search-AzGraph -Query "Resources | where properties contains '$IP' | project name, type, resourceGroup, subscriptionId" -UseTenantScope