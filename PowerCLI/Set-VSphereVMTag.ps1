<#
Example usage:

Set-VSphereVMTag `
-CategoryName "Environment" `
-TagName "Production" `
-VMNames "vm-app-01", "vm-db-01", "vm-web-01"

Prompt for missing values:

Set-VSphereVMTag

Use a text file:

$VMs = Get-Content C:\Temp\vmlist.txt
Set-VSphereVMTag -CategoryName "Environment" -TagName "Production" -VMNames $VMs
#>

function Set-VSphereVMTag {
      [CmdletBinding()]
      param (
          [string]$CategoryName,
          [string]$TagName,
          [string[]]$VMNames,

          [ValidateSet("Single", "Multiple")]
          [string]$Cardinality = "Single"
      )

      if (-not $CategoryName) {
          $CategoryName = Read-Host "Enter tag category name"
      }

      if (-not $TagName) {
          $TagName = Read-Host "Enter tag name"
      }

      if (-not $VMNames -or $VMNames.Count -eq 0) {
          $VMInput = Read-Host "Enter VM names separated by commas"
          $VMNames = $VMInput -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
      }

      if (-not $CategoryName -or -not $TagName -or -not $VMNames) {
          throw "CategoryName, TagName, and VMNames are required."
      }

      $Category = Get-TagCategory -Name $CategoryName -ErrorAction SilentlyContinue

      if (-not $Category) {
          Write-Host "Creating tag category '$CategoryName'..."
          $Category = New-TagCategory `
              -Name $CategoryName `
              -Cardinality $Cardinality `
              -EntityType VirtualMachine
      }

      $Tag = Get-Tag -Name $TagName -Category $Category -ErrorAction SilentlyContinue

      if (-not $Tag) {
          Write-Host "Creating tag '$TagName' in category '$CategoryName'..."
          $Tag = New-Tag -Name $TagName -Category $Category
      }

      foreach ($VMName in $VMNames) {
          $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

          if (-not $VM) {
              Write-Warning "VM not found: $VMName"
              continue
          }

          $ExistingAssignment = Get-TagAssignment -Entity $VM -Category $Category -ErrorAction SilentlyContinue |
              Where-Object { $_.Tag.Name -eq $TagName }

          if ($ExistingAssignment) {
              Write-Host "VM '$VMName' already has tag '$TagName'"
              continue
          }

          New-TagAssignment -Tag $Tag -Entity $VM | Out-Null
          Write-Host "Assigned tag '$TagName' to VM '$VMName'"
      }
  }