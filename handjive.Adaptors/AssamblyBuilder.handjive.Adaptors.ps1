param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
using SCG = System.Collections.Generic;
using SC = System.Collections;
using handjive.Foundation;

namespace handjive{
    namespace Adaptors {
        public interface IValueModel : IValueable{
        }

        public interface IDependencyServer{
            object Events{ get; }
            object Dependents{ get; }
        }

        //
        // Interfaces
        //
        public interface IItemIndexable<TIndex,TValue>{
            int Count { get; }
            TValue this[TIndex index]{ get; set; }
        }
        
        public interface IIndexAdaptor<TIndex,TValue> : IAdaptor{
            int Count { get; }
            TValue this[TIndex index]{ get; set; }
        }

        //
        // Base Classes
        //
        public class PluggableIndexerBase : SCG.IEnumerable<object>, IIndexAdaptor<object,object> {
            // IEnumerable
            SCG.IEnumerator<object> SCG.IEnumerable<object>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            SC.IEnumerator SC.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }

            // IIndexAdaptor
            object IIndexAdaptor<object,object>.this[object index]{
                get{
                    return this.PSget_Item(index);
                }
                set{
                    this.PSset_Item(index,value);
                }
            }
            object this[object index]{
                get{
                    return this.PSget_Item(index);
                }
                set{
                    this.PSset_Item(index,value);
                }
            }
            int IIndexAdaptor<object,object>.Count{
                get{
                    return this.PSget_Count();
                }
            }

            // IAdaptor
            object IAdaptor.Subject{
                get{
                    return this.PSget_Subject();
                }
                set{
                    this.PSset_Subject(value);
                }
            }
            
            // PowerShell responsibilities
            protected virtual SCG.IEnumerator<object> PSGetEnumerator(){
                return(null);
            }
            protected virtual object PSget_Item(object index){
                return null;
            }
            protected virtual void PSset_Item(object index,object value){
            }
            protected virtual int PSget_Count(){
                return 0;
            }
            protected virtual object PSget_Subject(){ return(null); }
            protected virtual void PSset_Subject(object subject){ }
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
