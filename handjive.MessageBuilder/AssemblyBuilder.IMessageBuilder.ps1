import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    public interface IMessageBuilder{
        string[] Lines{ get; }
    }
}
"@

AssemblyBuilder -TypeDefinition -Source $cscode -Destination $PSScriptRoot -AssemblyName 'handjive.MessageBuilderIF.dll'