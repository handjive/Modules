#
# Get-ConfigurationFilename
# 指定された名前か起動元スクリプトの拡張子を.jsonに変換したものを対象ファイル名として返す
function Get-ConfigurationFilename([string]$scriptPath,[string]$filename)
{
   $actualFilename = $filename

    if( $actualFilename -eq "" )
    {
        $actualFilename = $scriptPath.Trim()
        $actualFilename = $actualFilename -replace('\.ps1$','.json')
    }

    return $actualFilename
}
#
# Get-Configurations(呼びたし元スクリプトのパス,設定ファイル名)
#
function Get-Configurations([string]$scriptPath,[string]$filename)
{
    $actualFilename = Get-ConfigurationFilename($scriptPath,$filename)
    if( !(Test-Path $actualFilename) )
    {
        throw "Configuration file `"${actualFilename}`" did not exists."
    }

    $values = Get-Content $actualFilename -Raw |ConvertFrom-Json
    Add-Member -InputObject $values -NotePropertyName Runtime -NotePropertyValue @{} 
    return $values
}

Export-ModuleMember Get-Configurations
Export-ModuleMember Get-ConfigurationFilename
