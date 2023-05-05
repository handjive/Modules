param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Collections{
        public interface ICollectionAdaptor{
            System.Collections.Generic.IEnumerable<object> Values{ get; }
        }

        public interface IPluggableEnumerator {
            object Substance{ get; set; }
            object OnCurrentBlock{ get; set; }
            object OnMoveNextBlock{ get; set; }
            object OnResetBlock{ get; set; }
            object OnDisposeBlock{ get; set; }
            object WorkingSet{ get; }
        }        

        public interface IPluggableComparer{
            object CompareBlock{ get; set; }
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
        public class CombinedComparer : ComparerBase<object>{
        }
        
        public interface IBag{
            int Count{ get; }
            handjive.Collections.CombinedComparer Comparer{ get; set; }
            object this[int index]{ get; }
            System.Collections.Generic.IEnumerable<object> Values{ get; }
            System.Collections.Generic.IEnumerable<object> ValuesSorted{ get; }
            System.Collections.Generic.IEnumerable<object> ValuesOrdered{ get; }
            System.Collections.Generic.IEnumerable<object> ElementsSorted{ get; }
            System.Collections.Generic.IEnumerable<object> ElementsOrdered{ get; }
        }

        public interface IIndexedBag{
            object GetIndexBlock{ get; set; }
            object this[object index]{ get; }
            System.Collections.Generic.IEnumerable<object> Indexes{ get; }
            System.Collections.Generic.IEnumerable<object> ElementsSorted{ get; }
            System.Collections.Generic.IEnumerable<object> ElementsOrdered{ get; }

            //System.Collections.IEnumerator IndexesOrdered{ get; }
            //System.Collections.IEnumerator Values{ get; }
            //int Count{ get; }
            //object[] this[int index]{ get; }
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

        public interface IItemIndexer{
            object this[object index]{ get; set; }
            object this[int index]{ get; set; }
        }
        public interface IItemIndexer_IntIndex{
            object this[int index]{ get; set; }
        }
        public interface IItemIndexer_ObjectIndex{
            object this[object index]{ get; set; }
        }

        public class IndexableEnumerableBase : IItemIndexer ,System.Collections.Generic.IEnumerable<object>{
            System.Collections.Generic.IEnumerator<object> System.Collections.Generic.IEnumerable<object>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
    
            public object this[object index]{
                get{ return PSGetItem_ObjectIndex(index); }
                set{ PSSetItem_ObjectIndex(index,value); }
            }
            public object this[int index]{
                get{ return PSGetItem_IntIndex(index); }
                set{ PSSetItem_IntIndex(index,value); }
            }
    
            protected virtual System.Collections.Generic.IEnumerator<object> PSGetEnumerator(){ return(null); }
            protected virtual object PSGetItem_ObjectIndex(object index){ return(null); }
            protected virtual void   PSSetItem_ObjectIndex(object index,object value){  }
            protected virtual object PSGetItem_IntIndex(int index){ return(null); }
            protected virtual void   PSSetItem_IntIndex(int index,object value){  }
        }
        public interface IIndexAdaptor{
            int Count { get; }
        }
        
        public interface IBag2{
            int Count { get; }
            int CountOccurrences { get; }
            int CountWithoutDuplicate { get; }

            System.Collections.Generic.IEnumerable<object> Values{ get; }
            System.Collections.Generic.IEnumerable<object> ValuesOrdered{ get; }
            System.Collections.Generic.IEnumerable<object> ValuesSorted{ get; }
            System.Collections.Generic.IEnumerable<object> ValuesAndOccurrences{ get; }
            System.Collections.Generic.IEnumerable<object> ValuesAndOccurrencesOrdered{ get; }
            System.Collections.Generic.IEnumerable<object> ValuesAndOccurrencesSorted{ get; }
        }
        public interface ISortingComparerHolder{
            CombinedComparer Values { get; set; }
            CombinedComparer ValuesAndOccurrences { get; set; }
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
