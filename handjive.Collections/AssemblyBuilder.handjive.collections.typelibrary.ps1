param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
using SCG = System.Collections.Generic;
using SC = System.Collections;
using handjive.Foundation;

namespace handjive{
    namespace Collections{
        public interface IItemIndexable<TIndex,TValue> : IAdaptor{
            int Count { get; }
            TValue this[TIndex index]{ get; set; }
        }
        
        //
        // Base Classes
        //
        public class PluggableIndexerBase : SCG.IEnumerable<object>, IItemIndexable<object,object> {
            // IEnumerable
            SCG.IEnumerator<object> SCG.IEnumerable<object>.GetEnumerator(){
                return(this.PSGetEnumerator());
            }
            SC.IEnumerator SC.IEnumerable.GetEnumerator(){
                return(this.PSGetEnumerator());
            }

            // IItemIndexable
            object IItemIndexable<object,object>.this[object index]{
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
            int IItemIndexable<object,object>.Count{
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
    
        // ---------------------
        public interface ICollectionAdaptor{
            SCG.IEnumerable<object> Values{ get; }
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
        
        public interface IItemIndexer{
            object this[object index]{ get; set; }
            object this[int index]{ get; set; }
        }

        public interface IIndexableWrapper{
            public object this[object index]{
                get{ return PSGetItem_ObjectIndex(index); }
                set{ PSSetItem_ObjectIndex(index,value); }
            }
            public object this[int index]{
                get{ return PSGetItem_IntIndex(index); }
                set{ PSSetItem_IntIndex(index,value); }
            }
            int Count { get; }
    
            protected virtual object PSGetItem_ObjectIndex(object index){ return(null); }
            protected virtual void   PSSetItem_ObjectIndex(object index,object value){  }
            protected virtual object PSGetItem_IntIndex(int index){ return(null); }
            protected virtual void   PSSetItem_IntIndex(int index,object value){  }
        }

        public interface IEnumerableWrapper : SCG.IEnumerable<object>{
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
        
        public interface IPluggableEnumerator {
            object Substance{ get; set; }
            object OnCurrentBlock{ get; set; }
            object OnMoveNextBlock{ get; set; }
            object OnResetBlock{ get; set; }
            object OnDisposeBlock{ get; set; }
            object WorkingSet{ get; }
        }        


        public interface IIndexAdaptor{
            int Count { get; }
        }
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

        public interface IBag{
            int Count { get; }
            int CountOccurrences { get; }
            int CountWithoutDuplicate { get; }

            CombinedComparer Comparer{ get; set; }

            SCG.List<object> Elements{ get; }
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

<#$DLLNAME = 'handjive.collections.typelibrary.dll'
if( $Build ){
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}#>

# handjive.Foundation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=22b2bd9641469b21, processorArchitecture=MSIL
$DLLNAME = 'handjive.collections.typelibrary.dll'
#$REFS = @( 'handjive.Foundation.dll'  )
#$REFS = [Reflection.Assembly]::LoadFrom('handjive.Foundation.dll')
$REFS = @(
     'System.Collections'
    ,'.\handjive.Foundation\handjive.foundation.typelibrary.dll'
)

if( $Build ){
    #add-type -typeDefinition $cscode -OutputAssembly "$PSScriptROOT\$DLLNAME" -ReferencedAssemblies @($REFS) -OutputType Library
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Refs @($REFS) -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}