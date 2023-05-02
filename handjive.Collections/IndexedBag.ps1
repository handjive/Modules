using module handjive.ValueHolder
using module handjive.ChainScript

using namespace handjive.Collections

<# HashTableでよくね? #>
class IndexedBagElement {
    [object]$Value
    [int]$Occurrence
        [object]$Index

    IndexedBagElement(){
    }
    IndexedBagElement([BagElement]$anElement){
        $this.Value = $anElement.Value
        $this.Occurrence = $anElement.Occurrence
    }
}


class IndexedBag : Bag,IIndexedBag{ 
    static $ELEMENT_CLASS = [IndexedBagElement]
    
    hidden [ValueHolder]$wpvGetIndexBlockHolder
    hidden [ValueHolder]$wpvIndexComparerHolder
    hidden [Collections.Generic.SortedDictionary[object,object]]$wpvIndexDictionary

    hidden [Collections.Generic.SortedDictionary[object,object]]buildIndexDictionary([IndexedBag]$anIndexedBag,[CombinedComparer]$indexComparer)
    {
        $newDict = [Collections.Generic.SortedDictionary[object,object]]::new([Collections.Generic.IComparer[object]]$indexComparer)
        $anIndexedBag.Substance.keys.foreach{
            $aValue = $anIndexedBag.Substance[[object]$key]
            $index = $anIndexedBag.GetIndexOf($aValue)
            $newDict.add($index,$aValue)
        }
        return($newDict)
    }

    hidden Initialize([ScriptBlock]$getIndexBlock){
        <#
        # GetKeyBlockかIndexComparerが変更されたらIndexDictionaryを再構成
        #>
        $comparer = [PluggableComparer]::GetSubjectBlock($getIndexBlock)
        $this.wpvIndexDictionary = [Collections.Generic.SortedDictionary[object,object]]::new($comparer)

        $this.wpvGetIndexBlockHolder = [ValueHolder]::new($getIndexBlock)
        $this.wpvGetIndexBlockHolder.AddValueChangedListener($this,{
            param($receiver,$args1,$args2,$workingset)
            $receiver.wpvIndexComparerHolder.Subject = [PluggableComparer]::GetSubjectBlock($args1[1])
            $receiver.wpvIndexDictionary = $receiver.buildIndexDictionary($receiver,$receiver.IndexComparer)
        })
        $this.wpvIndexComparerHolder = [ValueHolder]::new($comparer)
        $this.wpvIndexComparerHolder.AddValueChangedListener($this,{ 
            param($receiver,$args1,$args2,$workingset) 
            $receiver.wpvGetIndexBlockHolder.Subject = $args1[1].GetSubjectBlock
            $receiver.wpvIndexDictionary = $receiver.buildIndexDictionary($receiver,$receiver.IndexComparer)
            $receiver.Comparer = $receiver.IndexComparer
        })
    }

    IndexedBag() : base(){
        ([IndexedBag]$this).Initialize({ $args[0] })
    }
    IndexedBag([Collections.Generic.IEnumerator[object]]$enumerator,[CombinedComparer]$comparer){
        ([IndexedBag]$this).Initialize($comparer.GetSubjectBlock)
        $this.AddAll($enumerator)
    }
    IndexedBag([Collections.Generic.IEnumerable[object]]$enumerable,[CombinedComparer]$comparer){
        ([IndexedBag]$this).Initialize($comparer.GetSubjectBlock)
        $this.AddAll($enumerable)
    }

    [object]newElement(){
        return(([IndexedBag]::ELEMENT_CLASS)::new())
    }
    [object]GetIndexOf([object]$value){
        $scriptblock = $this.GetIndexBlock
        $result = &$scriptblock $value
        return($result)
    }

    [object]get_GetIndexBlock(){
        $scriptblock = $this.wpvGetIndexBlockHolder.Value()
        return($scriptBlock)
    }
    set_GetIndexBlock([object]$scriptBlock){
        $this.wpvGetIndexBlockHolder.Value($scriptBlock)
    }

    [object]get_Item([object]$anIndex){
        return($this.wpvIndexDictionary[$anIndex])
    }

    [Collections.Generic.IEnumerable[object]]get_Indexes(){
        return $this.wpvIndexDictionary.keys
        <#$enumr = [PluggableEnumerator]::new($this)
        $enumr.workingset.keyEnumerator = $this.wpvIndexDictionary.keys.getEnumerator()
        $enumr.OnMoveNextBlock = {
            param($substance,$workingset)
            return $workingset.keyEnumerator.MoveNext()
        }
        $enumr.OnCurrentBlock = {
            param($substance,$workingset)
            return $workingset.keyEnumerator.Current
        }
        $enumr.OnResetBlock = {
            param($substance,$workingset)
            $workingset.keyEnumerator.Reset()
        }
        return $enumr.ToEnumerable()
        #>
    }

    <#
     Todo: SortedDictionaryのソート順と、要素になるBagのソート順は合わせられていることを保証しなきゃ不味くない?
       >> 一応、AddメソッドでBagを追加するときに、DictionaryのComparerコピーしてみてる(要確認)
    #>
    hidden [ChainScript]elementsEnumeratorBody([Collections.IEnumerator]$indexEnumerator,[Collections.IEnumerator]$valueEnumerator){
        $scriptChain = [ChainScript]::new()
        $script1 = $scriptChain.newElement()
        $script1.context.indexEnumerator = $indexEnumerator
        $script1.context.IndexDictionary = $this.wpvIndexDictionary
        $script1.Block = {
            param($context,$workingset,$control,$depth)
            if( $context.indexEnumerator.MoveNext() ){
                $workingset.currentIndex = $context.indexEnumerator.Current
                $workingset.valueEnumerator = ($context.IndexDictionary[$workingset.currentIndex]).ElementsSorted
                $control.Flow = [ChainFlow]::Forward
            }
            else{
                $control.Flow = [ChainFlow]::Terminate
            }
        }
        $script2 = $scriptChain.newElement()
        $script2.Block = {
            param($context,$workingset,$control,$depth)
            if( $workingset.valueEnumerator.MoveNext() ){
                $control.Flow = [ChainFlow]::Ready
            }
            else{
                $control.Flow = [ChainFlow]::Backward
            }
        }
        $scriptChain.ResetBlock = {
            param($sc)
            $sc.chain[0].context.indexEnumerator.Reset()
        }
        $scriptChain.GetValueBlock = {
            param($sc,$workingset)
            $workingset.currentIndex,$workingset.valueEnumerator.Current.Value,$workingset.valueEnumerator.Current.Occurrence
        }
        return($scriptChain)
    }

    <#[Collections.IEnumerator]get_ElementsSorted(){
        $enumerator = [PluggableEnumerator]::new($this)
        return($enumerator)
    }#>

    hidden [Collections.Generic.IEnumerator[object]]elementsSortedEnumerator(){
        $indexEnum = $this.Indexes
        $bagsEnum = $this.wpvIndexDictionary.Values.GetEnumerator()
        $scriptChain = $this.elementsEnumeratorBody($indexEnum,$bagsEnum)
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.workingset.ScriptChain = $scriptChain
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            $nextable = $workingset.ScriptChain.Perform()
            return($nextable)
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $elem = $substance.newElement()
            $result = $workingset.ScriptChain.GetValue()
            $elem.Index = $result[0]
            $elem.Value = $result[1]
            $elem.Occurrence = $result[2]
            return($elem)
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.ScriptChain.Reset()
        }
        return($enumerator)
    }
    [Collections.Generic.IEnumerable[object]]get_ElementsSorted(){
        return $this.elementsSortedEnumerator().ToEnumerable()
    }
    
    [Collections.Generic.IEnumerator[object]]elementsOrderedEnumerator(){
        $enumerator = $this.create_ElementsEnumerator()
        $enumerator.WorkingSet.valueEnumerator = $this.Substance.Keys.GetEnumerator()
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $elem = $substance.newElement()
            $elem.Index = $substance.GetIndexOf($workingset.valueEnumerator.Current)
            $elem.Value = $workingset.valueEnumerator.Current
            $elem.Occurrence = $substance.Substance[[object]$elem.Value]
            return($elem)
        }
        $enumerator.PSReset()
        return($enumerator)
    }
    [Collections.Generic.IEnumerable[object]]get_ElementsOrdered(){
        return $this.elementsOrderedEnumerator().ToEnumerable()
    }

    [Collections.Generic.IEnumerable[object]]PSGetEnumerator(){
        return $this.get_ElementsSorted()
    }

    Add([object]$value){
        ([Bag]$this).Add($value)

        $index = $this.GetIndexOf($value)
        if( $null -eq $this.wpvIndexDictionary[$index] ){
            # ComparerがCombinedComparerじゃなかったらWrapする
            $cmpr = $this.wpvIndexDictionary.Comparer
            $adjustedCmpr = if( $cmpr -is [CombinedComparer] ){ $cmpr } else{ [CombinedComparerWrapper]::new([Collections.Generic.IComparer[object]]$cmpr) }
            $newBag = [Bag]::new([CombinedComparer]$adjustedCmpr)
            $this.wpvIndexDictionary.Add($index,$newBag)
        }
        ($this.wpvIndexDictionary[$index]).Add($value)
    }

    Remove([object]$value){
        $index = &$this.GetIndexBlock $value
        $aBag = $this.wpvIndexDictionary[[object]$index]
        if( $null -eq $aBag ){
            return
        }
        $aBag.Remove($value)
        iF( $aBag.Count -eq 0 ){
            $this.wpvIndexDictionary.Remove($index)
        }
        ([Bag]$this).Remove($value)
    }


<#    Set([IndexedBagElement]$element){
        $this.Substance[$element.Value] = $element.Occurrence
    }
    SetAll([BagElement[]]$elements){
        $elements.foreach{ $this.Set($_) }
    }
#>

    Purge([object]$aValue){
        $anIndex = $this.GetIndexOf($aValue)
        $aBag = $this.wpvIndexDictionary[$anIndex]
        $aBag.Purge($aValue)
        ([Bag]$this).Purge($aValue)
        if( $aBag.Count -eq 0 ){
            $this.wpvIndexDictionary.Remove($anIndex)
        }
    }
    PurgeAll([object[]]$indexes){
        $indexes.foreach{ $this.Purge($_) }
    }
    
    PurgeIndex([object]$anIndex){
        $aBag = $this.wpvIndexDictionary[$anIndex]
        $anArray = $aBag.ValuesOrdered.ToArray()
        $anArray.foreach{ $this.Purge($_) }
    }
}


class Set {
}