import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Collections{
        public interface IBag{
            System.Collections.Generic.IEnumerator<object> Values{ get; }
            int Count{ get; }
            object SortingComparer{ get; set; }
            object this[int index]{ get; }
            //int this[object key]{ get; }
            System.Collections.Generic.IEnumerator<object> ValuesSorted{ get; }
            System.Collections.Generic.IEnumerator<object> ValuesOrdered{ get; }
            System.Collections.Generic.IEnumerator<object> ElementsSorted{ get; }
            System.Collections.Generic.IEnumerator<object> ElementsOrdered{ get; }
        }

        public interface IIndexedBag{
            object GetIndexBlock{ get; set; }
            System.Collections.Generic.IEnumerator<object> Indexes{ get; }
            //System.Collections.IEnumerator IndexesOrdered{ get; }
            //System.Collections.IEnumerator Values{ get; }
            //int Count{ get; }
            //object[] this[int index]{ get; }
            object this[object index]{ get; }
            //System.Collections.IEnumerator ValuesAndOccurrences{ get; }
            //System.Collections.IEnumerator IndexesAndValuesAndOccurrences{ get; }
        }

        public class EnumerableBase : System.Collections.Generic.IEnumerable<object>{
            System.Collections.Generic.IEnumerator<object> System.Collections.Generic.IEnumerable<object>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            protected virtual System.Collections.Generic.IEnumerator<object> PSGetEnumerator(){
                return(null);
            }
        }

        public class EnumeratorBase : System.Collections.Generic.IEnumerator<object>{
            object System.Collections.Generic.IEnumerator<object>.Current{ 
                get{ 
                    return(this.PSCurrent()); 
                }
            }
            bool MoveNext(){
                return(this.PSMoveNext());
            }
            void Reset(){
                this.PSReset();
            }

            object System.Collections.IEnumerator.Current{
                get{
                    return(this.PSCurrent());
                }
            }
            bool System.Collections.IEnumerator.MoveNext(){
                return(this.PSMoveNext());
            }
            void System.Collections.IEnumerator.Reset(){
                this.PSReset();
            }

            void System.IDisposable.Dispose(){
                this.PSDispose();
            }
            
            protected virtual object PSCurrent(){
                return(null);
            }
            protected virtual bool PSMoveNext(){
                return(false);
            }
            protected virtual void PSReset(){
            }
            protected virtual void PSDispose(){
            }
        }
    }
}
"@
<#            protected object GetKeyBlock{
                get{ return (this._GetKeyBlock); }
                set{ this._GetKeyBlock = value; }
            }
#>
AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName 'handjive.collections.typelibrary.dll' -Destination $PSScriptRoot
