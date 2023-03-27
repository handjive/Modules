$cscode = @"
namespace handjive{
    public interface IWrapper{
        object Substance{ get; set; }
    }
}
"@

AssemblyBuilder -TypeDefinition -Source $cscode -Destination $PSScriptRoot -AssemblyName 'handjive.miscif.dll'