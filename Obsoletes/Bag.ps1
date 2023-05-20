using module handjive.ValueHolder
using module handjive.ChainScript

using namespace handjive.Collections

<# HashTableでよくね? #>
class BagElement{
    [object]$Value
    [int]$Occurrence

    BagElement(){
    }

    BagElement([object]$value,[int]$Occurrence){
        $this.Value = $value
        $this.Occurrence = $Occurrence
    }
}

<#
# TODO: SortingComparerが機能してない? 
#
#  重複を無視する(が、重複数は保持する)コレクション
#　(格納対象オブジェクトはICompareable.CompareTo()に答える必要あり)
#
#   プロパティ
#       SortingComparer         Collections.IComparer   { get; set }  ValuesSorted,ElementsSortedのソート順を決定するためのIComparer
#       ValuesOrdered           Collections.IEnumerable { get; }    追加順で値を返すEnumerator
#       ValuesSorted            Collections.IEnumerable { get; }    SortingComparer順で値を返すEnumerator。
#                                                                   比較の結果同じ(-eq)と判定されたオブジェクトは集約されてしまう。ValueOrderdの結果と食い違う事になるので注意。
#                                                                   (ValuesOrderdで返されるオブジェクトがValuesSortedには含まれない、という状況が起きる)
#       ElementsOrdered         Collections.IEnumerable { get; }    追加順で値と重複数([Bag]::ELEMENT_CLASSのインスタンス)を返すEnumerator
#       ElementsSorted          Collections.IEnumerable { get; }    SortingComparer順で値と重複数([Bag]::ELEMENT_CLASSのインスタンス)を返すEnumerator
#       Count                   int { get; }                        値の数
#       item[]                  int item[[int]$index]   { get; }    追加順で指定した値
#
#   メソッド
#       Add             [void] ([object]$aValue)      $aValueを追加する
#       AddAll          [void] ([object[]]$values)    $valuesを追加する
#       Remove          [void] ([object]$aValue)      $aValueの重複数を減算する。重複が無くなれば値そのものを削除する(3度追加された値は3度Removeされないと無くならない)。
#       RemoveAll       [void] ([object[]$values)     $valuesそれぞれをRemoveする
#       Purge           [void] ([object]$aValue)      $aValueを削除する。Removeと違い、一度の操作でその値と重複数を削除する。
#       PurgeAll        [void] ([object[]]$values)    $valuesそれぞれをPurgeする
#
#       OccurrencesOf   [int] ([object]$aValue)       $aValueの重複数を得る
#       Includes        [bool]([object]$aValue)       $aValueが含まれるかの真偽値を返す
#>
class Bag : EnumerableBase,handjive.IWrapper,IBag{
    static [Bag]Intersect([Collections.Generic.IEnumerable[object]]$left,[Collections.Generic.IEnumerable[object]]$right,[CombinedComparer]$comparer){
        $aBag = [Bag]::new($left,$comparer)
        $aBag.IntersectBy($right,$comparer)
        return($aBag)
    }
    static [Bag]Except([Collections.Generic.IEnumerable[object]]$left,[Collections.Generic.IEnumerable[object]]$right,[CombinedComparer]$comparer){
        $aBag = [Bag]::new($left,$comparer)
        $aBag.ExceptWith($right,$comparer)
        return($aBag)
    }

    static $ELEMENT_CLASS = [BagElement]
    static $SUBSTANCE_CLASS = [Collections.Specialized.OrderedDictionary]
    static $VALUESET_CLASS = [Collections.Generic.SortedSet[object]]
    
    hidden [ValueHolder]$wpvSubstanceHolder
    hidden [ValueHolder]$wpvComparerHolder

    hidden [Collections.Generic.SortedSet[object]]$wpvValueSet

    Bag(){
        $this.Initialize([PluggableComparer]::New())
    }
    Bag([CombinedComparer]$comparer){
        $this.Initialize($comparer)
    }
    Bag([Bag]$aBag){
        $this.Initialize([PluggableComparer]::New())
        $this.Substance = $aBag.Substance
    }
    Bag([Bag]$aBag,[CombinedComparer]$comparer){
        $this.Initialize($comparer)
        $this.Substance = $aBag.Substance
    }
    Bag([Collections.Generic.IEnumerable[object]]$enumerable){
        $this.Initialize([PluggableComparer]::New())
        $this.AddAll($enumerable)
    }
    Bag([Collections.Generic.IEnumerable[object]]$enumerable,[CombinedComparer]$comparer){
        $this.Initialize($comparer)
        $this.AddAll($enumerable)
    }

    hidden initialize([CombinedComparer]$comparer){
        $this.wpvSubstanceHolder = [ValueHolder]::new(([Bag]::SUBSTANCE_CLASS)::new($comparer))
        $this.wpvSubstanceHolder.AddValueChangedListener($this,{
            param($receiver,$args1,$args2,$workingset) 
            $receiver.buildValueSet($args1[1],$receiver.Comparer)
        })

        $this.wpvComparerHolder = [ValueHolder]::new($comparer)
        $this.wpvComparerHolder.AddValueChangedListener($this,{ 
            param($receiver,$args1,$args2,$workingset) 
            $receiver.rebuildSubstance($args1[0])
            #$receiver.buildValueSet($args1[0])
        })

        $this.wpvValueSet = ([Bag]::VALUESET_CLASS)::new([Collections.Generic.IComparer[object]]$comparer)
    }
    hidden rebuildSubstance([CombinedComparer]$aComparer){
        $newSubstance = ([Bag]::SUBSTANCE_CLASS)::new($aComparer)
        $this.Substance.psbase.Keys.foreach{
            $this.basicAdd($newSubstance,$_)
        }
        $this.Substance = $newSubstance
    }
    hidden buildValueSet([Collections.Specialized.OrderedDictionary]$dict,[CombinedComparer]$aComparer){
        $this.wpvValueSet = ([Bag]::VALUESET_CLASS)::new($aComparer)
        if( $this.Substance.psbase.Count -gt 0){
            $this.Substance.psbase.Keys.foreach{ $this.wpvValueSet.Add($_) }
        }
    }

    hidden [object]newElement(){
        return(([Bag]::ELEMENT_CLASS)::new())
    }

    hidden [object]get_Substance(){
        return($this.wpvSubstanceHolder.Value())
    }
    hidden set_Substance([object]$aSubstance){
        $this.wpvSubstanceHolder.Value($aSubstance)
    }

    hidden [CombinedComparer]get_Comparer(){
        return($this.wpvComparerHolder.Value())
    }
    hidden set_Comparer([CombinedComparer]$aComparer){
        $this.wpvComparerHolder.Value($aComparer)
    }
    
    hidden [Collections.Generic.IEnumerator[object]]basicValuesSorted(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.workingset.valueEnumerator = [Collections.IEnumerator]$this.wpvValueSet.GetEnumerator()
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            return($workingset.valueEnumerator.MoveNext())
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            return($workingset.valueEnumerator.Current)
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.valueEnumerator.Reset()
        }
        return($enumerator)
    }

    hidden [Collections.Generic.IEnumerator[object]]basicValuesOrdered(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.workingset.valueEnumerator = $this.Substance.Keys.GetEnumerator()
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            return($workingset.valueEnumerator.MoveNext())            
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            return($workingset.valueEnumerator.Current)
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.valueEnumerator.Reset()
        }
        return($enumerator)
    }

    hidden [Collections.Generic.IEnumerable[object]]get_ValuesOrdered(){
        return ($this.basicValuesOrdered()).ToEnumerable()
    }
    hidden [Collections.Generic.IEnumerable[object]]get_ValuesSorted(){
        return ($this.basicValuesSorted()).ToEnumerable()
    }
    hidden [Collections.Generic.IEnumerable[object]]get_Values(){
        return($this.get_ValuesSorted())
    }

    hidden [Collections.Generic.IEnumerator[object]]create_ElementsEnumerator(){        
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.valueEnumerator.Reset()
        }
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            $stat = $workingset.valueEnumerator.MoveNext()
            return($stat)
       }
       $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $elem = $substance.newElement()
            $elem.Value = $workingset.valueEnumerator.Current
            $elem.Occurrence = $substance.Substance[[object]$elem.Value]
            return($elem)
       }
       return($enumerator)
    }

    hidden [Collections.Generic.IEnumerator[object]]basicElementsSorted(){
        $enumerator = $this.create_ElementsEnumerator()
        $enumerator.WorkingSet.valueEnumerator = $this.basicValuesSorted()
        $enumerator.PSReset()
        return($enumerator)
    }
    [Collections.Generic.IEnumerable[object]]get_ElementsSorted(){
        return($this.basicElementsSorted().ToEnumerable())
    }

    hidden [Collections.Generic.IEnumerator[object]]basicElementsOrdered(){
        $enumerator = $this.create_ElementsEnumerator()
        $enumerator.WorkingSet.valueEnumerator = $this.basicValuesOrdered()
        $enumerator.PSReset()
        return($enumerator)
    }

    [Collections.Generic.IEnumerable[object]]get_ElementsOrdered(){
        return($this.basicElementsOrdered().ToEnumerable())
    }

    hidden [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return($this.basicElementsSorted())
    }
    

    hidden [int]get_Count(){
        <# 
        # なんだか全く釈然としないんだけど、単に$this.Substance.Count
        # としただけではCountの結果が返ってこない…
        # psbase介さないとプロパティのアクセスが出来ないっておかしくね?
        # (それぞれ確認するためにステップ分解したまんま)
        #>
        $aDict = $this.Substance -as [Bag]::SUBSTANCE_CLASS
        $count = $aDict.psbase.Count
        return($count)
    }

    hidden [object]get_Item([int]$index){
        $keys = $this.Substance.Keys
        return($keys[$index])
    }

    hidden basicAdd([Collections.Specialized.OrderedDictionary]$dict,[object]$aValue){
        if( $null -eq $dict[[object]$aValue] ){
            $dict.Add([object]$aValue,0)
        }
        ($dict[[object]$aValue])++

    }
    Add([object]$aValue){
        $this.basicAdd($this.Substance,$aValue)
        $this.wpvValueSet.Add($aValue)
    }
    <#AddAll([object[]]$values){
        $values.foreach{ $this.Add($_) }
    }#>
    AddAll([Collections.Generic.IEnumerator[object]]$enumr){
        $enumr.foreach{
            $this.Add($_)
        }
    }
    AddAll([Collections.Generic.IEnumerable[object]]$enumerable){
        $enumerable.foreach{
            $this.Add($_)
        }
    }
    
    Remove([object]$aValue){
        if( $null -eq $this.Substance[$aValue] )
        {
            return
        }

        if( $this.Substance[[object]$aValue] -eq 1 ){
            $this.Substance.Remove($aValue)
            $this.wpvValueSet.Remove($aValue)
        }
        else{
            $this.Substance[[object]$aValue]--
        }
    }
    RemoveAll([object[]]$values){
        $values.foreach{ $this.Remove($_) }
    }


    hidden Set([BagElement]$element){
        $this.Substance[[object]$element.Value] = $element.Occurrence
        $this.wpvValueSet.Add($element.Value)
    }
    hidden SetAll([BagElement[]]$elements){
        $elements.foreach{ $this.Set($_) }
    }


    Purge([object]$aValue){
        $this.Substance.Remove($aValue)
        $this.wpvValueSet.Remove($aValue)
    }
    PurgeAll([object[]]$values){
        $values.foreach{ $this.Purge($_) }
    }

    [int]OccurrencesOf([object]$value){
        return($this.Substance[[object]$value])
    }

    [bool]Includes([object]$aValue){
        return($this.wpvValueSet.Contains($aValue))
    }

    [bool]Includes([ScriptBlock]$nominator){
        $this.ValuesSorted.foreach{
            if( &$nominator $_ ){
                return $true
            }
        }

        return $false
    }

    hidden [object]basicIntersectBy([Collections.Generic.IEnumerable[object]]$enumerable,[CombinedComparer]$comparer){
        $newDict = ([Bag]::SUBSTANCE_CLASS)::new($comparer)
        $values = @()
        $enumerable.foreach{
            $values += $comparer.GetSubject($_)
        }
        $result = [Linq.Enumerable]::IntersectBy[object,object]($this.ValuesSorted,$values,[Func[object,object]]$comparer.GetSubjectBlock)
      
        $result.foreach{
            $this.basicAdd($newDict,$_)
        }
        return($newDict)
    }

    IntersectBy([Collections.Generic.IEnumerable[object]]$enumerable,[CombinedComparer]$comparer){
        $this.Substance = $this.basicIntersectBy($enumerable,$comparer)
    }

    hidden [object]basicExceptWith([Collections.Generic.IEnumerable[object]]$enumerable,[CombinedComparer]$comparer){
        $newDict = ([Bag]::SUBSTANCE_CLASS)::new($comparer)
        $result = [Linq.Enumerable]::Except($this.ValuesSorted,$enumerable,$comparer)
        $result.foreach{
            $this.basicAdd($newDict,$_)
        }
        return($newDict)
    }

    ExceptWith([Collections.Generic.IEnumerable[object]]$enumerable,[CombinedComparer]$comparer){
        $this.Substance = $this.basicExceptWith($enumerable,$comparer)
    }
}
