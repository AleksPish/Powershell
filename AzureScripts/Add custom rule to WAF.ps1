#Add vairables for the WAF:

$rgname = "<resource group containing the WAF>"
$location = "<location eg westeurope>"

#Create noew policy on WAF to block specific IP address:

$variable1 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RemoteAddr

$condition1 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable1 -Operator IPMatch -MatchValue "192.168.5.0/24" -NegationCondition $False

$rule = New-AzApplicationGatewayFirewallCustomRule -Name BlockIPAddress1 -Priority 10 -RuleType MatchRule -MatchCondition $condition1 -Action Block -State Enabled

#Once Rule is created we may need to update the policy on the WAF:

# Get the existing policy
$policy = Get-AzApplicationGatewayFirewallPolicy -Name <name of current waf policy> -ResourceGroupName $RGname
# Add an existing rule named $rule
$policy.CustomRules.Add($rule)
# Update the policy
Set-AzApplicationGatewayFirewallPolicy -InputObject $policy

#If there is no current policy create one and apply it:
# Create a firewall policy
$policySetting = New-AzApplicationGatewayFirewallPolicySetting -Mode Prevention -State Enabled
$wafPolicy = New-AzApplicationGatewayFirewallPolicy -Name wafpolicyNew -ResourceGroup $rgname -Location $location -PolicySetting $PolicySetting -CustomRule $rule