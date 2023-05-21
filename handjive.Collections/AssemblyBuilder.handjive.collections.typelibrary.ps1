param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
using SCG = System.Collections.Generic;
using SC = System.Collections;

namespace handjive{
    public interface IErsatzClassInstanceVariable{
        static SCG.Dictionary<System.Type,SCG.Dictionary<string,object>> _ErsatzClassInstanceVariables;
        static protected SCG.Dictionary<System.Type,SCG.Dictionary<string,object>> CIVDictionary{
            get{
                if( IErsatzClassInstanceVariable._ErsatzClassInstanceVariables == null ){
                    IErsatzClassInstanceVariable._ErsatzClassInstanceVariables = new SCG.Dictionary<System.Type,SCG.Dictionary<string,object>>();
                }
                return IErsatzClassInstanceVariable._ErsatzClassInstanceVariables;
            }
        }
        
        static SCG.Dictionary<string,object> ErsatzClassInstanceVariablesFor(System.Type owner){
            SCG.Dictionary<string,object> dict;
            if( !IErsatzClassInstanceVariable.CIVDictionary.TryGetValue(owner,out dict) ){
                IErsatzClassInstanceVariable.CIVDictionary[owner] = new SCG.Dictionary<string,object>();
            }
            return(IErsatzClassInstanceVariable.CIVDictionary[owner]);
        }

        static object ErsatzClassInstanceVariableNamedFor(string name,System.Type owner){
            object aValue;
            SCG.Dictionary<string,object> dict = IErsatzClassInstanceVariable.ErsatzClassInstanceVariablesFor(owner);
            if( dict.TryGetValue(name,out aValue) ){
                return aValue;
            }
            else{
                return null;
            }
        }        
    }

    namespace Collections{
        public interface ICollectionAdaptor{
            SCG.IEnumerable<object> Values{ get; }
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

        public class ComparerBase<T> : SC.IEqualityComparer, SC.IComparer,SCG.IEqualityComparer<T>,SCG.IComparer<T>{
            // IEqualityComparer
            bool SC.IEqualityComparer.Equals(object left,object right){
                return(this.PSEquals(left,right));
            }
            int SC.IEqualityComparer.GetHashCode(object obj){
                return(this.PSGetHashCode(obj));
            }

            // Generic.IEqualityComparer<T>
            bool SCG.IEqualityComparer<T>.Equals(T left,T right){
                return(this.PSEquals(left,right));
            }
            int SCG.IEqualityComparer<T>.GetHashCode(T obj){
                return(this.PSGetHashCode(obj));
            }

            // IComparer
            int SC.IComparer.Compare(object left,object right){
                return(this.PSCompare(left,right));
            }

            // Generic.IComparer<T>
            int SCG.IComparer<T>.Compare(T left,T right){
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
        
        /* public interface IBag{
            int Count{ get; }
            handjive.Collections.CombinedComparer Comparer{ get; set; }
            object this[int index]{ get; }
            SCG.IEnumerable<object> Values{ get; }
            SCG.IEnumerable<object> ValuesSorted{ get; }
            SCG.IEnumerable<object> ValuesOrdered{ get; }
            SCG.IEnumerable<object> ElementsSorted{ get; }
            SCG.IEnumerable<object> ElementsOrdered{ get; }
        } */

        /* public interface IIndexedBag{
            object GetIndexBlock{ get; set; }
            object this[object index]{ get; }
            SCG.IEnumerable<object> Indexes{ get; }
            SCG.IEnumerable<object> ElementsSorted{ get; }
            SCG.IEnumerable<object> ElementsOrdered{ get; }

            //SC.IEnumerator IndexesOrdered{ get; }
            //SC.IEnumerator Values{ get; }
            //int Count{ get; }
            //object[] this[int index]{ get; }
            //SC.IEnumerator ValuesAndOccurrences{ get; }
            //SC.IEnumerator IndexesAndValuesAndOccurrences{ get; }
        } */

        public class EnumerableBase : SCG.IEnumerable<object>{
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
        public class EnumerableBase<T> : SCG.IEnumerable<T>{
            SCG.IEnumerator<T> SCG.IEnumerable<T>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            SC.IEnumerator SC.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            protected virtual SCG.IEnumerator<T> PSGetEnumerator(){
                return(null);
            }
        }


        public class EnumeratorBase : SCG.IEnumerator<object>{
            object SCG.IEnumerator<object>.Current{ 
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

            object SC.IEnumerator.Current{
                get{
                    return(this.PSCurrent());
                }
            }
            bool SC.IEnumerator.MoveNext(){
                return(this.PSMoveNext());
            }
            void SC.IEnumerator.Reset(){
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

        public class IndexableEnumerableBase : IItemIndexer ,SCG.IEnumerable<object>{
            SCG.IEnumerator<object> SCG.IEnumerable<object>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            SC.IEnumerator SC.IEnumerable.GetEnumerator(){
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
    
            protected virtual SCG.IEnumerator<object> PSGetEnumerator(){ return(null); }
            protected virtual object PSGetItem_ObjectIndex(object index){ return(null); }
            protected virtual void   PSSetItem_ObjectIndex(object index,object value){  }
            protected virtual object PSGetItem_IntIndex(int index){ return(null); }
            protected virtual void   PSSetItem_IntIndex(int index,object value){  }
        }

        public interface IIndexAdaptor{
            int Count { get; }
        }
        
        public interface IBag{
            int Count { get; }
            int CountOccurrences { get; }
            int CountWithoutDuplicate { get; }

            CombinedComparer Comparer{ get; set; }

            IndexableEnumerableBase Elements{ get; }
            IndexableEnumerableBase ValuesAndOccurrences{ get; }
            IndexableEnumerableBase ValuesAndElements{ get; }
        }

        public interface IQuoterInstaller{  // Obsolete: インターフェース明示メソッドが実装できないので、あれこれやってみたけど役立たず
            public System.Type Quoter{ get;  }
            public System.Type QuoteTo{ get;  }
            public void InstallOn(System.Type target){
                IQuotable.GetQUOTERS(target)[this.QuoteTo] = this.Quoter;
            }
        }
        public interface IExtractorInstaller{   // Obsolete: インターフェース明示メソッドが実装できないので、あれこれやってみたけど役立たず
            public System.Type Extractor{ get;  }
            public System.Type ExtractTo{ get;  }
            public void InstallOn(System.Type target){
                IExtractable.GetEXTRACTORS(target)[this.ExtractTo] = this.Extractor;
            }
        }
        
        public interface IQuoter{   // Obsolete: インターフェース明示メソッドが実装できないので、あれこれやってみたけど役立たず
            //static IQuoterInstaller Installer{ get{ return IQuoter.Get_Installer(); } }
            static IQuoterInstaller Installer{ get; }
        }
        public interface IExtractor{    // Obsolete: インターフェース明示メソッドが実装できないので、あれこれやってみたけど役立たず
            static IExtractorInstaller Installer{ get; }
            //static IExtractorInstaller Installer{ get{ return IExtractor.get_Installer(); } }
        }

        public interface IQuotable {    // Obsolete: インターフェース明示メソッドが実装できないので、あれこれやってみたけど役立たず
            public static SCG.Dictionary<System.Type,SCG.Dictionary<System.Type,System.Type>> QUOTERS_DICTIONARY;   // key=Target type, Value=Converter
            
            public static SCG.Dictionary<System.Type,System.Type> GetQUOTERS(System.Type target){
                SCG.Dictionary<System.Type,System.Type> quoters;
            
                if( IQuotable.QUOTERS_DICTIONARY == null ){
                    IQuotable.QUOTERS_DICTIONARY = new SCG.Dictionary<System.Type,SCG.Dictionary<System.Type,System.Type>>();
                }
                if( !IQuotable.QUOTERS_DICTIONARY.TryGetValue(target,out quoters) ){
                    IQuotable.QUOTERS_DICTIONARY[target] = new SCG.Dictionary<System.Type,System.Type>();
                }
                return(IQuotable.QUOTERS_DICTIONARY[target]);
            }

            public object QuoteTo(System.Type aType);
        }
        public interface IExtractable { // Obsolete: インターフェース明示メソッドが実装できないので、あれこれやってみたけど役立たず
            public static SCG.Dictionary<System.Type,SCG.Dictionary<System.Type,System.Type>> EXTRACTORS_DICTIONARY;
            
            public static SCG.Dictionary<System.Type,System.Type> GetEXTRACTORS(System.Type target){
                SCG.Dictionary<System.Type,System.Type> quoters;
            
                if( IExtractable.EXTRACTORS_DICTIONARY == null ){
                    IExtractable.EXTRACTORS_DICTIONARY = new SCG.Dictionary<System.Type,SCG.Dictionary<System.Type,System.Type>>();
                }
                if( !IExtractable.EXTRACTORS_DICTIONARY.TryGetValue(target,out quoters) ){
                    IExtractable.EXTRACTORS_DICTIONARY[target] = new SCG.Dictionary<System.Type,System.Type>();
                }
                return(IExtractable.EXTRACTORS_DICTIONARY[target]);
            }
            public object ExtractTo(System.Type aType);
        }

        public interface ISortingComparerHolder{    // Obsolate
            CombinedComparer Elements { get; set; }
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
