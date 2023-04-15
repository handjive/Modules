param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    public interface IValueModel<T>{
        T Subject{ get;set; }
        T Value();
        void Value(T aValue);
    }
}
"@

$DLLNAME = 'handjive.valueholder.typelibrary.dll'
if( $Build ){
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
