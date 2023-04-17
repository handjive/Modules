param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Collections{
        public interface ICollectionAdaptor{
            System.Collections.Generic.IEnumerator<object> Values{ get; }
        }
        public interface IPluggableEnumerator {
            object Substance{ get; set; }
            object OnCurrentBlock{ get; set; }
            object OnMoveNextBlock{ get; set; }
            object OnResetBlock{ get; set; }
            object OnDisposeBlock{ get; set; }
            object WorkingSet{ get; }
        }        
        public interface IBag{
            System.Collections.Generic.IEnumerator<object> Values{ get; }
            int Count{ get; }
            System.Collections.Generic.IComparer<object> SortingComparer{ get; set; }
            System.Collections.IEqualityComparer EqualityComparer{ get; set; }
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

        public class ComparerBase<T> : System.Collections.IEqualityComparer, System.Collections.IComparer,System.Collections.Generic.IEqualityComparer<T>,System.Collections.Generic.IComparer<T>{
            // IEqualityComparer
            bool System.Collections.IEqualityComparer.Equals(object left,object right){
                return(this.PSEquals(left,right));
            }
            int System.Collections.IEqualityComparer.GetHashCode(object obj){
                return(this.PSGetHashCode(obj));
            }

            // Generic.IEqualityComparer<T>
            bool System.Collections.Generic.IEqualityComparer<T>.Equals(T left,T right){
                return(this.PSEquals(left,right));
            }
            int System.Collections.Generic.IEqualityComparer<T>.GetHashCode(T obj){
                return(this.PSGetHashCode(obj));
            }

            // IComparer
            int System.Collections.IComparer.Compare(object left,object right){
                return(this.PSCompare(left,right));
            }

            // Generic.IComparer<T>
            int System.Collections.Generic.IComparer<T>.Compare(T left,T right){
                return(this.PSCompare(left,right));
            }

            // Subclass Responsibility
            virtual protected bool PSEquals(object left,object right){
                return(false);
            }
            virtual protected int PSGetHashCode(object obj){
                return(0);
            }
            virtual protected int PSCompare(object left,object right){
                return(0);
            }
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
        public class EnumerableBase<T> : System.Collections.Generic.IEnumerable<T>{
            System.Collections.Generic.IEnumerator<T> System.Collections.Generic.IEnumerable<T>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            protected virtual System.Collections.Generic.IEnumerator<T> PSGetEnumerator(){
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

$DLLNAME = 'handjive.collections.typelibrary.dll'
if( $Build ){
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
