$IP = "40.113.2.54"
Search-AzGraph -Query "Resources | where properties contains '$IP' | project name, type, resourceGroup, subscriptionId" -UseTenantScope