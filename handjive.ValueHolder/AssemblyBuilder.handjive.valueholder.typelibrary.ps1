param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
using handjive.Foundation;

namespace handjive{
    public interface IValueModel : IValueable,IAdaptor{
    }
}
"@

$REFS = [Reflection.Assembly]::Load('handjive.Foundation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=22b2bd9641469b21, processorArchitecture=MSIL')
$DLLNAME = 'handjive.valueholder.typelibrary.dll'

if( $Build ){
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME  -Refs @($REFS) -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
