using module ConfigurationUtilities

$configFilename = Get-ConfigurationFilename $PSCommandPath ''
$configFilename | Write-Host
Get-Configurations $configFilename ''


