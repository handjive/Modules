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
        public interface IIndexAdaptor<TIndex,TValue>{
            int Count { get; }
            TValue this[TIndex index]{ get; set; }
        }

        public class PluggableIndexerBase : handjive.Foundation.IAdaptor, SCG.IEnumerable<object>{
            SCG.IEnumerator<object> SCG.IEnumerable<object>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            SC.IEnumerator SC.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            protected virtual SCG.IEnumerator<object> PSGetEnumerator(){
                return(null);
            }

            object handjive.Foundation.IAdaptor.Subject{
                get{ return null; }
                set{}
            }
        }

        public class PluggableEnumerableBase : SCG.IEnumerable<object>{
            SCG.IEnumerator<object> SCG.IEnumerable<object>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            SC.IEnumerator SC.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            protected virtual SCG.IEnumerator<object> PSGetEnumerator(){
                return(null);
            }
        }
    }
}
"@

# handjive.Foundation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=22b2bd9641469b21, processorArchitecture=MSIL
$DLLNAME = 'handjive.adaptors.typelibrary.dll'
#$REFS = @( 'handjive.Foundation.dll'  )
#$REFS = [Reflection.Assembly]::LoadFrom('handjive.Foundation.dll')
$REFS = [Reflection.Assembly]::Load('handjive.Foundation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=22b2bd9641469b21, processorArchitecture=MSIL')

if( $Build ){
    #add-type -typeDefinition $cscode -OutputAssembly "$PSScriptROOT\$DLLNAME" -ReferencedAssemblies @($REFS) -OutputType Library
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Refs @($REFS) -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
