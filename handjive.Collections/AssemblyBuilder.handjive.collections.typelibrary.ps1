import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Collections{
        public interface IBag{
            System.Collections.IEnumerator Values{ get; }
            int Count{ get; }
            object SortingComparer{ get; set; }
            object this[int index]{ get; set; }
            object this[object key]{ get; set; }
            System.Collections.IEnumerator ValuesSorted{ get; }
            System.Collections.IEnumerator ValuesOrdered{ get; }
            System.Collections.IEnumerator ElementsSorted{ get; }
            System.Collections.IEnumerator ElementsOrdered{ get; }
            //System.Collections.Generic.IEnumerator<object> ValuesAndOccurrences{ get; }
        }
        public interface IIndexedBag{
            object GetIndexBlock{ get; set; }
            System.Collections.IEnumerator Values{ get; }
            int Count{ get; }
            object[] this[int index]{ get; set; }
            object[] this[object key]{ get; set; }
            System.Collections.IEnumerator ValuesAndOccurrences{ get; }
            System.Collections.IEnumerator IndexesAndValuesAndOccurrences{ get; }
        }

        public interface IKeyedBag{
            object[] Indices{ get; }
            object[] Values{ get; }
            int Count{ get; }
            object[] IndicesAndValues{ get; }
            object[] IndicesAndValuesAndOccurrences{ get; }
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
