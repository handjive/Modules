[CmdletBinding()]
Param([string]$Config="")

[Config]::LoadFromFileOrDefault($PSCommandPath,$Config)
[Config]::Current.Filename | Write-host
[Config]::Current.keys | Write-Host
[Config]::Current.values | write-host
[Config]::Current.Runtime['ABC'] = 'DEF'
[Config]::Current.Runtime.ABC | write-host
