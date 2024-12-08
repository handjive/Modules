param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Adaptors {
        public interface IIndexAdaptor<TIndex,TValue>{
            int Count { get; }
            TValue this[TIndex index]{ get; set; }
        }
    }
}
"@

$DLLNAME = 'handjive.adaptors.typelibrary.dll'
if( $Build ){
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
