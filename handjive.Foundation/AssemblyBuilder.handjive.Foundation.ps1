param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
using System;
namespace handjive{
    namespace Foundation{
        public class SubclassResponsibilityException : Exception
        {
            public SubclassResponsibilityException()
            {
            }

            public SubclassResponsibilityException(string message)
                : base(message)
            {
            }

            public SubclassResponsibilityException(string message, Exception inner)
                : base(message, inner)
            {
            }
        }
    }
}
"@

$DLLNAME = 'handjive.foundation.dll'
if( $Build ){
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
