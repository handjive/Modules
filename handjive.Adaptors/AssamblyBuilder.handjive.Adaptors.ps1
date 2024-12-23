param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
using SCG = System.Collections.Generic;
using SC = System.Collections;
using handjive.Foundation;

namespace handjive{
    namespace Adaptors {
        //
        // Interfaces
        //
    }
}
"@

# handjive.Foundation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=22b2bd9641469b21, processorArchitecture=MSIL
$DLLNAME = 'handjive.adaptors.typelibrary.dll'
#$REFS = @( 'handjive.Foundation.dll'  )
#$REFS = [Reflection.Assembly]::LoadFrom('handjive.Foundation.dll')
$REFS = @('.\handjive.Foundation\handjive.foundation.typelibrary.dll' )

if( $Build ){
    #add-type -typeDefinition $cscode -OutputAssembly "$PSScriptROOT\$DLLNAME" -ReferencedAssemblies @($REFS) -OutputType Library
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Refs @($REFS) -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
