using module handjive.ValueHolder

<#
# 一定範囲の整数値
#
# [Interval]::new(1,100,2)      1~100、増分2の整数(1,3,5,7....)
# [Interval]::new(-100,100,10)  -100~100、増分10の整数(-100,-90,-80...80,90,100)
#
# while($anInterval.MoveNext(){ $anInterval.Current }
# $anInterval.foreach{ ------ }
#>
class Interval : handjive.Collections.EnumerableBase, Collections.IEnumerator{
    [int]$Start
    [int]$Stop
    [int]$Step
    [bool]$Descending = $false

    [nullable[int]]$wpvCurrent
    
    Interval([int]$start,[int]$stop,[int]$step) : base(){
        $this.initialize($start,$stop,$step)
    }

    Interval([int]$start,[int]$stop) : base(){
        $this.initialize($start,$stop,1)
    }

    hidden [object]calcvalue([nullable[int]]$value,[int]$step,[int]$stop,[scriptblock]$ifOutOfRange)
    {
        if( $null -eq $value ){
            $this.wpvCurrent = $this.Start
            return($this.Current)
        }

        $newValue = $null
        if( $this.Descending ){
            $newValue = $value - $step
            if( $newValue -ge $stop ){
                return $newValue
            }
            else{
                &$ifOutOfRange
                return $null
            }
        }
        else{
            $newValue = $value + $step
            if( $newValue -le $stop ){
                return $newValue
            }
            else{
                &$ifOutOfRange
                return($null)
            }
        }
    }
    hidden [object]calcvalue(){
        $newValue = $this.calcvalue($this.Current,$this.Step,$this.Stop,{})
        return($newValue)
    }

    hidden initialize([int]$start,[int]$stop,[int]$step){
        $this.Start = $start
        $this.Stop = $stop
        $this.Step = [Math]::abs($step)

        if( $this.Start -ge $this.Stop ){
            $this.Descending = $true
        }
        $this.calcvalue($start,$step,$stop,{ throw 'Too much Step' })
    }

    [object]get_Current(){
#        write-host 'Current is ' $this.wpvCurrent
        return($this.wpvCurrent)
    }
    [bool]MoveNext(){
        $this.wpvCurrent = $this.calcvalue()
        return($null -ne $this.wpvCurrent)
    }
    Reset(){
        $this.wpvCurrent = $null
    }

    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            return $substance.MoveNext()
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            return($substance.Current)
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $substance.Reset()
        }

        return $enumerator
    }
}

<#
#　場当たり的なEnumerator
#
#  [PluggableEnumerator]::new(Enumerationの主体となるオブジェクト)
#　$penum.Substance         Enumerationの主体となるオブジェクト
#  $penum.Workingset        Enumerationを実行するために必要なｱﾚｺﾚを格納するための領域(HashTable)
#  $penum.OnCurrentBlock    Currentにアクセスされた時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnMoveNextBlock   MoveNext()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnResetBlock      Reset()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#>
class PluggableEnumerator : handjive.Collections.EnumeratorBase {
    [object]$Substance
    [ScriptBlock]$OnCurrentBlock = {}
    [ScriptBlock]$OnMoveNextBlock = { $false }
    [ScriptBlock]$OnResetBlock = {}
    [HashTable]$WorkingSet

    PluggableEnumerator([object]$substance) : base(){
        $this.Substance = $Substance
        $this.WorkingSet = @{}
    }

    PSDispose([bool]$disposing){
    }

    [object]PSCurrent(){
        $result = &$this.OnCurrentBlock $this.Substance $this.WorkingSet
        return($result)
    }
    [bool]PSMoveNext(){
        $result = &$this.OnMoveNextBlock $this.Substance $this.WorkingSet
        return($result)
    }
    PSReset(){
        &$this.OnResetBlock $this.Substance $this.WorkingSet
    }

    [Array]ToArray(){
        $result = @()
        while($this.PSMoveNext()){
            $result += $this.PSCurrent()
        }
        return($result)
    }
}


<# 
# 場当たり的Comparer
#>
class PluggableComparer : Collections.Generic.IComparer[object] {
    hidden static [ScriptBlock]$AscendingBlock  = { param($left,$right) if( $left -eq $right ){ return 0 } elseif( $left -lt $right ){ return -1 } else {return 1 } }
    hidden static [ScriptBlock]$DescendingBlock = { param($left,$right) if( $left -eq $right ){ return 0 } elseif( $left -lt $right ){ return 1 } else {return -1 } }
    
    static [PluggableComparer]DefaultAscending(){
        return([PluggableComparer]::new([PluggableComparer]::AscendingBlock))
    }
    static [PluggableComparer]DefaultDescending(){
        return([PluggableComparer]::new([PluggableComparer]::DescendingBlock))
    }

    [ScriptBlock]$CompareBlock
    
    PluggableComparer(){
    }
    PluggableComparer([ScriptBlock]$comparerBlock){
        $this.CompareBlock = $comparerBlock
    }

    [int]Compare([object]$v1,[object]$v2){
        return((&$this.CompareBlock $v1 $v2))
    }
}


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
#  重複を無視する(が、重複数は保持する)コレクション
#
#   プロパティ
#       SortingComparer         Collections.IComparer { get; set }  ValuesSorted,ElementsSortedのソート順を決定するためのIComparer
#       ValuesOrdered           Collections.IEnumerator { get; }    追加順で値を返すEnumerator
#       ValuesSorted            Collections.IEnumerator { get; }    SortingComparer順で値を返すEnumerator
#       ElementsOrdered         Collections.IEnumerator { get; }    追加順で値と重複数([Bag]::ELEMENT_CLASSのインスタンス)を返すEnumerator
#       ElementsSorted          Collections.IEnumerator { get; }    SortingComparer順で値と重複数([Bag]::ELEMENT_CLASSのインスタンス)を返すEnumerator
#       Count                   int { get; }                        値の数
#       item[]                  int item[[int]$index] { get; }      追加順で指定した値の重複数($aBag.OccurrencesOf(ValuesOrderd[$index])と等価)
#       item[]                  int item[[object]$value]{ get }     指定した値の重複数($aBag.OccurrencesOf($value)と等価)
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
class Bag : handjive.Collections.EnumerableBase,handjive.IWrapper,handjive.Collections.IBag{
    static $ELEMENT_CLASS = [BagElement]
    hidden [Collections.Specialized.OrderedDictionary]$wpvSubstance
    hidden [Collections.Generic.SortedSet[object]]$wpvValueSet
    hidden [ValueHolder]$wpvSortingComparerHolder

    Bag() : base(){
        $this.Initialize()
        $this.SortingComparer = [PluggableComparer]::DefaultAscending()
    }
    Bag([Collections.Generic.IComparer[object]]$comparer){
        $this.Initialize()
        $this.SortingComparer = $comparer
    }
    Bag([Bag]$aBag) : base(){
        $this.Initialize()
        $this.SortingComparer = [PluggableComparer]::DefaultAscending()
        $this.SetAll($aBag)
    }
    Bag([Bag]$aBag,[Collections.Generic.IComparer[object]]$comparer) : base(){
        $this.Initialize()
        $this.SortingComparer = $comparer
        $this.SetAll($aBag)
    }
    Bag([object[]]$elements) : base(){
        $this.Initialize()
        $this.SortingComparer = [PluggableComparer]::DefaultAscending()
        $this.AddAll($elements)
    }
    Bag([object[]]$elements,[Collections.Generic.IComparer[object]]$comparer) : base(){
        $this.Initialize()
        $this.SortingComparer = $comparer
        $this.AddAll($elements)
    }

    hidden initialize(){
        $this.Substance = [Collections.Specialized.OrderedDictionary]::new()
        $this.wpvSortingComparerHolder = [ValueHolder]::new()
        $this.wpvSortingComparerHolder.WorkingSet.Receiver = $this
        $this.wpvSortingComparerHolder.AddSubjectChangedLister(@(),{ 
            param($args1,$args2,$workingset) 
            $receiver = $workingset.Receiver
            $receiver.buildValueSet($args1[0])
        })
    }

    hidden buildValueSet([object]$aComparer){
        $this.wpvValueSet = [Collections.Generic.SortedSet[object]]::new($aComparer)
        if( $this.wpvSubstance.Count -gt 0){
            $this.wpvSubstance.Keys.foreach{ $this.wpvValueSet.Add($_) }
        }
    }

    hidden [object]newElement(){
        return(([Bag]::ELEMENT_CLASS)::new())
    }


    hidden [object]get_Substance(){
        return($this.wpvSubstance)
    }
    hidden set_Substance([object]$aSubstance){
        $this.wpvSubstance = $aSubstance
    }

    [object]get_SortingComparer(){
        return($this.wpvSortingComparerHolder.Value)
    }
    set_SortingComparer([object]$aComparer){
        $this.wpvSortingComparerHolder.Value($aComparer)
    }

    [Collections.IEnumerator]get_ValuesSorted(){
        return($this.wpvValueSet.GetEnumerator())
    }
    [Collections.IEnumerator]get_ValuesOrdered(){
        return($this.Substance.Keys.GetEnumerator())
    }
    [System.Collections.IEnumerator]get_Values(){
        return($this.get_ValuesSorted())
    }

    [int]get_Count(){
        return($this.Substance.Count)
    }

    [int]get_Item([int]$index){
        return($this.Substance[$index])
    }
    [int]get_Item([object]$key){
        return($this.Substance[[object]$key])
    }

    [int]OccurrencesOf([object]$value){
        return($this.Substance[[object]$value])
    }

    [bool]Includes([object]$aValue){
        return($this.wpvValueSet.Contains($aValue))
    }

    hidden [Collections.IEnumerator]create_ElementsEnumerator(){        
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.valueEnumerator.Reset()
        }
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            return($workingset.valueEnumerator.MoveNext())
       }
       $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $elem = $substance.newElement()
            $elem.Value = $workingset.valueEnumerator.Current
            $elem.Occurrence = $this.Substance[[object]$elem.Value]
            return($elem)
       }
       return($enumerator)
    }

    [Collections.IEnumerator]get_ElementsSorted(){
        $enumerator = $this.create_ElementsEnumerator()
        $enumerator.WorkingSet.valueEnumerator = $this.wpvValueSet.GetEnumerator()
        $enumerator.PSReset()
        return($enumerator)
    }

    [Collections.IEnumerator]get_ElementsOrdered(){
        $enumerator = $this.create_ElementsEnumerator()
        $enumerator.WorkingSet.valueEnumerator = $this.Substance.Keys.GetEnumerator()
        $enumerator.PSReset()
        return($enumerator)
    }

    hidden [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return($this.ElementsOrdered)
    }
    

    Add([object]$aValue){
        if( $null -eq $this.Substance[[object]$aValue] ){
            $this.Substance.Add([object]$aValue,0)
        }
        ($this.Substance[[object]$aValue])++
        $this.wpvValueSet.Add($aValue)
    }
    AddAll([object[]]$values){
        $values.foreach{ $this.Add($_) }
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
}


class IndexedBagElement {
    [object]$Index
    [object]$Value
    [object]$Occurrence

    IndexedBagElement(){
    }
    IndexedBagElement([object]$index,[Bag]$value){
        $this.Index = $index
        $this.Values = $value
    }
}

class IndexedBag : handjive.Collections.EnumerableBase,handjive.Collections.IIndexedBag,handjive.IWrapper{ 
    static $ELEMENT_CLASS = [IndexedBagElement]
    static $DEFAULT_DICTIONARYCLASS = [Collections.Generic.SortedDictionary[object,Bag]]
    
    hidden [ScriptBlock]$wpvGetIndexBlock
    hidden [object]$BagType
    hidden [object]$wpvSubstance

    IndexedBag([object]$dictType,[object]$bagType){
        $this.GetIndexBlock = { $args[0] }
        $this.BagType = $bagType
        $this.wpvSubstance = $dictType::new()
    }
    IndexedBag(){
        $this.GetIndexBlock = { $args[0] }
        $this.BagType = [Bag]
        $this.wpvSubstance = [IndexedBag]::DEFAULT_DICTIONARYCLASS::new()
    }

    [object]newElement(){
        return(([IndexedBag]::ELEMENT_CLASS)::new())
    }

    [object]get_Substance(){
        return($this.wpvSubstance)
    }
    set_Substance([object]$substance){
        $this.wpvSubstance = $substance
    }
    [object]get_GetIndexBlock(){
        return($this.wpvGetIndexBlock)
    }
    set_GetIndexBlock([object]$scriptBlock){
        $this.wpvGetIndexBlock = $scriptBlock
    }
    [int]get_Count(){
        return $this.Substance.Count
    }
    [object[]]get_Item([int]$index){
        $enum = $this.Substance.Keys.GetEnumerator()
        $count = 0
        do{
            $enum.MoveNext()
        } until($count++ -eq $index)

        $values = $this.Substance[$enum.Current]
        return($values)
    }
    [object[]]get_Item([object]$key){
        return($this.Substance[$key])
    }
    set_Item([int]$index,[object[]]$aBag){
        $aKey = $this.Substance.Keys[$index]
        $this.Substance[$aKey] = [Bag]$aBag
    }
    set_Item([object]$key,[object[]]$aBag){
        $this.Substance[$key] = [Bag]$aBag
    }

    [System.Collections.IEnumerator]get_Values(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.WorkingSet.Comparer = [PluggableComparer]::new({
            param([object]$v1,[object]$v2)
            if( $v1.Value -lt $v2.Value ){
                return(-1)
            }
            elseif($v1.Value -eq $v2.Value ){
                return(0)
            }
            else{
                return(1)
            }
        })
        $enumerator.workingset.bagEnumeraorGenerateBlock = {
            param($subatance,$workingset)
            #$aSet = [Collections.Generic.SortedSet[object]]::new($workingset.Comparer)
            #$workingset.valueEnumerator.Current.foreach{ $aSet.Add($_) }
            #$workingset.bagEnumerator = $aSet.GetEnumerator()
            $workingset.bagEnumerator = $workingset.valueEnumerator.Current.PSGetEnumerator()
        }

        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)

            if( $workingset.initial ){
                $workingset.initial = $false
                if( !$workingset.valueEnumerator.MoveNext() ){
                    return($false)
                }
                &$workingset.bagEnumeraorGenerateBlock $substance $workingset
            }

            if( $workingset.bagEnumerator.MoveNext() ){
                return($true)
            }
            else{
                if( !$workingset.valueEnumerator.MoveNext() ){
                    return($false)
                }
                &$workingset.bagEnumeraorGenerateBlock $substance $workingset
                return($workingset.bagEnumerator.MoveNext())
            }
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            #return($workingset.Bags[0])
            $aValue = $workingset.bagEnumerator.Current
            if( $null -eq $aValue ){
                write-host 'NULL!!'
            }
            return($aValue)
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            [Collections.IEnumerator]$workingset.ValueEnumerator = $substance.Substance.Values.GetEnumerator()
            $workingset.initial = $true
        }

        $enumerator.PSReset()
        return($enumerator)
    }
    [Collections.IEnumerator]get_ValuesAndOccurrences(){
        return($this.Values)
    }
    [Collections.IEnumerator]get_IndexesAndValuesAndOccurrences(){
        $enumerator = [PluggableEnumerator]::new($this)
        [Collections.IEnumerator]$enumerator.WorkingSet.valueEnumerator = $this.Values
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            $stat = ([Collections.IEnumerator]$workingSet.valueEnumerator).MoveNext()
            return($stat)
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $vao = $workingSet.valueEnumerator.Current
            $anIndex = &$substance.GetIndexBlock $vao.Value
            $elem = $substance.newElement()
            $elem.Index = $anIndex
            $elem.Value = $vao.Value
            $elem.Occurrence = $vao.Occurrence
            
            return($elem)
        }
        return ($enumerator)
    }

    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return($this.IndexesAndValuesAndOccurrences)
    }

    Add([object]$value){
        $index = &$this.GetIndexBlock $value
        if( $null -eq $this.Substance[$index] ){
            $this.Substance.Add($index,$this.BagType::new())
        }
        ($this.SUbstance[$index]).Add($value)
    }
    AddAll([object[]]$values){
        $values.foreach{ $this.Add($_) }
    }

    Remove([object]$value){
        $index = &$this.GetIndexBlock $value
        if( ($this.Substance[$index]).Count -eq 1 ){
            $this.Substance.Remove($index)
            return
        }

        ($this.Substance[$index]).Remove($value)
    }
    RemoveAll([object[]]$values){
        $values.foreach{ $this.Remove($_) }
    }

<#    Set([IndexedBagElement]$element){
        $this.Substance[$element.Value] = $element.Occurrence
    }
    SetAll([BagElement[]]$elements){
        $elements.foreach{ $this.Set($_) }
    }
#>

    Purge([object]$anIndex){
        $this.Substance.Remove($anIndex)
    }
    PurgeAll([object[]]$indexes){
        $indexes.foreach{ $this.Purge($_) }
    }
}
<#
あ  →   あんぱん(3)
    　  あんぽんたん(1)
    　  あんかけ(2)
    　  あんちょび(2)

IndexedBag key='あ', Value=Bag( あんぱん(3),あんぽんたん(1),あんかけ(2),あんちょび(2) )
IndicesAndValues =  あ,あんぱん(3)
                    あ,あんぽんたん(1)
                    あ,あんかけ(2)
                    あ,あんちょび(2)
#>






