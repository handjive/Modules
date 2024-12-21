function AssemblyBuilder{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ParameterSetName="Type")][switch]$TypeDefinition
        ,[Parameter(Mandatory,ParameterSetName="Member")][switch]$MemberDefinition
        ,[Parameter(Mandatory,ParameterSetName="Member")][string]$Namespace
        ,[Parameter()][string]$Name
        ,[Parameter(Mandatory)][string]$Source
        ,[Parameter(Mandatory)][string]$Destination
        ,[Parameter(Mandatory)][string]$AssemblyName
        ,[object[]]$Refs = @()
    )

    $ASSEMBLY_PATH = Join-Path -Path $Destination -childPath $AssemblyName

    if( Test-Path -LiteralPath $ASSEMBLY_PATH ){
        Write-Host 'Saving current assembly '
        $newName = [String]::Format('{0}-saved{1}',$AssemblyName,(Get-Date -format 'yyyyMMddhhMMss'))
        $newPath = Join-Path -Path $Destination -childPath $newName
        Move-Item -LiteralPath $ASSEMBLY_PATH -Destination $newPath
    }

    switch( $PsCmdlet.ParameterSetName ){
        'Type' {
            Write-Host 'Generating assembly (Type Definition)'
            if( $Refs.Count -eq 0 ){
                add-type -typeDefinition $Source -OutputAssembly $ASSEMBLY_PATH -OutputType Library
            }
            else{
                add-type -typeDefinition $cscode -OutputAssembly $ASSEMBLY_PATH -ReferencedAssemblies $Refs -OutputType Library    
            }
        }
        'Member' {
            Write-Host 'Generating assembly (Member Definition)'
            if( $Refs.Count -eq 0 ){
                add-type  -memberDefinition $Source -Name $Name -OutputAssembly $ASSEMBLY_PATH -ReferencedAssemblies $Refs -OutputType Library
            }
            else{
                add-type  -memberDefinition $Source -Name $Name -OutputAssembly $ASSEMBLY_PATH -OutputType Library
            }
        }
    }
}

Export-ModuleMember *