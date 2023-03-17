$script:message1=@"
AssemblyPath(to handjive.everythingapi.dll and everything64.dll) does not specified.
Try to complement with `$PSScriptRoot($PSScriptRoot)
"@

$script:message_quit=@"

*** Unable to resolve assembly path ***

Set $global:PERSONAL_ASSEMBLY_PATH (and place assembly)
  or Set assembly path with "[EverythingAPI]::AssemblyPath"
  or place assembly into ScriptRoot.
"@

class EverythingAPI{
    static [string]$AssemblyName = 'handjive.EverythingAPI.dll'
    static [string]$AssemblyPath = $global:PERSONAL_ASSEMBLY_PATH
    static [Reflection.TypeInfo]$Default
    
    static [Reflection.TypeInfo]DefaultAPI(){
        if( $null -eq [EverythingAPI]::Default){
            Write-Host 'Loading EverythingAPI assembly'

            if($null -eq [EverythingAPI]::AssemblyPath){
                Write-Host $script:message1 -ForegroundColor Yellow
                if( $PSScriptRoot -eq ""){
                    Write-Host $script:message_quit -ForegroundColor Yellow
                    return ($null)
                }
    
                [EverythingAPI]::AssemblyPath = $PSScriptRoot

            }

            $aPath = Join-Path ([EverythingAPI]::AssemblyPath) ([EverythingAPI]::AssemblyName)
            if( ! (Test-Path -literalPath $aPath) ){
                [String]::Format('Assembly "{}" does not exists.',$aPath) | Write-Host -ForegroundColor Yellow
                return ($null)
            }
            [EverythingAPI]::Default = add-type -literalPath $aPath -passThru
        }
        return([EverythingAPI]::Default)
    }
    EverythingAPI([string]$AssemblyPath)
    {
        [EverythingAPI]::AssemblyPath = $AssemblyPath
    }

    [Reflection.TypeInfo]GetAPI(){
        return([EverythingAPI]::DefaultAPI())
   }
}