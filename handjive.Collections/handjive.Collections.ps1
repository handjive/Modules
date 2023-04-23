using module handjive.ValueHolder
using module handjive.ChainScript
using namespace handjive.Collections

<#
# 一定範囲の整数値
#
# [Interval]::new(1,100,2)      1~100、増分2の整数(1,3,5,7....)
# [Interval]::new(-100,100,10)  -100~100、増分10の整数(-100,-90,-80...80,90,100)
#
# while($anInterval.MoveNext(){ $anInterval.Current }
# $anInterval.foreach{ ------ }
#>
class Interval : EnumerableBase, Collections.IEnumerator{
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
    Collections.Generic.IEnumerator<object>のCollections.Generic.IEnumerable<object>へのWrapper
#>
class EnumerableWrapper : EnumerableBase[object]{
    static [EnumerableWrapper]On([Collections.Generic.IEnumerator[object]]$Subject){
        $newOne = [EnumerableWrapper]::new($Subject)
        return ($newOne)
    }

    [Collections.Generic.IEnumerator[object]]$Subject

    EnumerableWrapper([Collections.Generic.IEnumerator[object]]$Subject){
        $this.Subject = $Subject
    }

    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return $this.Subject
    }

}

<#
#　場当たり的なEnumerator
#
#  [PluggableEnumerator]::new(Enumerationの主体となるオブジェクト)
#
#　$penum.Substance         Enumerationの主体となるオブジェクト
#  $penum.Workingset        Enumerationを実行するために必要なｱﾚｺﾚを格納するための領域(HashTable)
#  $penum.OnCurrentBlock    Currentにアクセスされた時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnMoveNextBlock   MoveNext()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnResetBlock      Reset()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnDisposeBlock    Dispose()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#>

class PluggableEnumerator : EnumeratorBase,IPluggableEnumerator {
    <#
    # Collections.IEnumratorをCollections.Generic.IEnumeratorに偽装する
    # (いる?)
    #>
    static [PluggableEnumerator]InstantWrapOn([Collections.IEnumerator]$enumerator){
        $newOne = [PluggableEnumerator]::new($enumerator)
        $newOne.OnMoveNextBlock = {
            param($substance,$workingset)
            return $substance.MoveNext()
        }
        $newOne.OnCurrentBlock = {
            param($substance,$workingset)
            return $substance.Current
        }
        $newOne.OnResetBlock = {
            param($substance,$workingset)
            $substance.Reset()
        }
        return $newOne
    }
    static [PluggableEnumerator]InstantWrapOn([Collections.IEnumerable]$enumerable){
        return [PluggableEnumerator]::InstantWrapOn($enumerable.GetEnumerator())
    }

    <#
    # 空のEnumerator
    #>
    static [PluggableEnumerator]Empty(){
        return [EmptyEnumerator]::new()
    }

    hidden [object]$wpvSubstance
    hidden [HashTable]$wpvWorkingSet
    hidden [ScriptBlock]$wpvOnCurrentBlock  = { param([object]$substance,[HashTable]$workingset) }
    hidden [ScriptBlock]$wpvOnMoveNextBlock = { param([object]$substance,[HashTable]$workingset) return $false }
    hidden [ScriptBlock]$wpvOnResetBlock    = { param([object]$substance,[HashTable]$workingset) }
    hidden [ScriptBlock]$wpvOnDisposeBlock  = { param([object]$substance,[HashTable]$workingset,[bool]$disposing) }

    PluggableEnumerator([object]$substance) : base(){
        $this.wpvSubstance = $Substance
        $this.wpvWorkingSet = @{}
    }

    <# Property Accessors #>
    [object]get_Substance(){
        return $this.wpvSubstance
    }
    set_Substance([object]$substance){
        $this.wpvSubstance = $substance
    }

    [object]get_OnMoveNextBlock(){
        return ($this.wpvOnMoveNextBlock)
    }
    set_OnMoveNextBlock([object]$aBlock){
        $this.wpvOnMoveNextBlock = $aBlock
    }

    [object]get_OnCurrentBlock(){
        return $this.wpvOnCurrentBlock
    }
    set_OnCurrentBlock([object]$aBlock){
        $this.wpvOnCurrentBlock = $aBlock
    }

    [object]get_OnResetBlock(){
        return($this.wpvOnResetBlock)
    }
    set_OnResetBlock([object]$aBlock){
        $this.wpvOnResetBlock = $aBlock
    }

    [object]get_OnDisposeBlock(){
        return $this.wpvOnDisposeBlock
    }
    set_OnDisposeBlock([object]$aBlock){
        $this.wpvOnDisposeBlock = $aBlock
    }

    [object]get_WorkingSet(){
        if( $null -eq $this.wpvWorkingSet ){
            $this.wpvWorkingSet = @{}
        }
        return($this.wpvWorkingSet)
    }

    <# EnumeratorBase Members #>
    PSDispose([bool]$disposing){
        &$this.OnDisposeBlock $this.Substance $this.WorkingSet $disposing
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

    [object]Current(){
        return $this.PSCurrent()
    }
    [bool]MoveNext(){
        return $this.PSMoveNext()
    }
    Reset(){
        $this.PSReset()
    }

    [Array]ToArray(){
        $result = @()
        while($this.PSMoveNext()){
            $result += $this.PSCurrent()
        }
        return($result)
    }
    [Collections.ArrayList]ToArrayList(){
        $result = [Collections.ArrayList]::new()
        while($this.PSMoveNext()){
            $result.Add($this.PSCurrent())
        }
        return($result)
    }

    [EnumerableWrapper]ToEnumerable(){
        return ([EnumerableWrapper]::on($this))
    }
}

class EmptyEnumerator : PluggableEnumerator {
    EmptyEnumerator() : base(){
    }

    <# Property Accessors #>
    [object]get_Substance(){
        return $null
    }
    set_Substance([object]$aSubstance){
    }

    [object]get_OnMoveNextBlock(){
        return({ return $false })
    }
    set_OnMoveNextBlock([object]$aBlock){
    }

    [object]get_OnCurrentBlock(){
        return({ return $null })
    }
    set_OnCurrentBlock([object]$aBlock){
    }

    [object]get_OnResetBlock(){
        return ({})
    }
    set_OnResetBlock([ScriptBlock]$aBlock){
    }

}


<# 
# 場当たり的Comparer
#
# Collections.Icomparer
# Collections.Generic.IComparer<object>
# Collections.IEqualityComparer
# Collections.Generic.IEqualityComparer<object
# の全部に返事する
#
# 比較対象にGetSubjectBlockを適用した結果で比較を実行(CompreはCompareBlockの評価結果)、その結果を返す
# GetSubjectBlockもCompareBlockも指定しない場合は、対象をそのまま比較・昇順
#>

class PluggableComparer : CombinedComparer{
    hidden static [ScriptBlock]$DefaultAscendingBlock  = { param($left,$right) if( $left -eq $right ){ return 0 } elseif( $left -lt $right ){ return -1 } else {return 1 } }
    hidden static [ScriptBlock]$DefaultDescendingBlock = { param($left,$right) if( $left -eq $right ){ return 0 } elseif( $left -lt $right ){ return 1 } else {return -1 } }
    
    static [PluggableComparer]GetSubjectBlock([ScriptBlock]$getSubjectBlock){
        $newOne = [PluggableComparer]::new()
        $newOne.DefaultAscending()
        $newOne.GetSubjectBlock = $getSubjectBlock
        return $newOne
    }

    [ScriptBlock]$CompareBlock
    [ScriptBlock]$GetSubjectBlock = { return $args[0] }
    
    PluggableComparer() : base(){
        $this.DefaultAscending()
    }
    PluggableComparer([ScriptBlock]$getSubjectBlock) : base(){
        $this.DefaultAscending()
        $this.GetSubjectBlock = $getSubjectBlock
    }

    PluggableComparer([ScriptBlock]$comparerBlock,[ScriptBlock]$getSubjectBlock) : base(){
        $this.DefaultAscending()
        $this.GetSubjectBlock = $getSubjectBlock
    }

    DefaultAscending(){
        $this.CompareBlock = ($this.GetType())::DefaultAscendingBlock
    }
    DefaultDescending(){
        $this.CompareBlock = ($this.GetType())::DefaultDescendingBlock
    }

    hidden [object]GetSubject([object]$anObject){
        return &$this.GetSubjectBlock $anObject
    }

    hidden [int]PSCompare([object]$left,[object]$right){
        $leftSubject = $this.GetSubject($left)
        $rightSubject = $this.GetSubject($right)
        return((&$this.CompareBlock $leftSubject $rightSubject))
    }

    hidden [bool]PSEquals([object]$left,[object]$right){
        $leftSubject = $this.GetSubject($left)
        $rightSubject = $this.GetSubject($right)        
        return($leftSubject -eq $rightSubject)
    }
    
    hidden [int]PSGetHashCode([object]$obj){
        $aSubject = $this.GetSubject($obj)
        return($aSubject.GetHashCode());
    }
    
    [int]Compare([object]$left,[object]$right){
        $result = $this.PSCompare($left,$right)
        return($result)
    }
    
    [bool]Equals([object]$left,[object]$right){
        return($this.PSEquals($left,$right))
    }

    [int]GetHashCode([object]$obj){
        return($this.PSGetHashCode($obj))
    }
}

class AspectComparer : PluggableComparer{
    [string]$Aspect
<#    hidden [object]GetSubject([object]$anObject){
        $aValue = $anObject.($this.Aspect)
        if( $null -eq $aValue ){
            throw [String]::format('Invalid Aspect "{0}" for "{1}"',$this.Aspect,$anObject.Gettype())
        }

        return($aValue)
    }#>

    <#AspectComparer([ScriptBlock]$comparerBlock,[string]$aspect) : base($comparerBlock,{ return $args[0] }){
        $this.Aspect = $aspect
    }#>
    AspectComparer([string]$aspect) : base({ return $args[0]}){
        $this.Aspect = $aspect
        $this.GetSubjectBlock = [ScriptBlock]::Create([String]::Format('return($args[0].{0})',$this.Aspect))
        $this.DefaultAscending()
    }
    
    [string]ToString(){
        if( $null -eq $this.CompareBlock ){
            return([String]::Format('{0}()',$this.gettype().Name))
        }
        $type = switch( $this.CompareBlock.gethashcode() ){
            ([AspectComparer]::DefaultAscendingBlock.GetHashCode()){
                'Default-Ascending'
            }
            ([AspectComparer]::DefaultDescendingBlock.GetHashCode()){
                'Default-Descending'
            }
            default{
                'Custom'
            }
        }
        return([String]::Format('{0}({1}:"{2}")',$this.gettype().Name,$type,$this.Aspect))
    }
}

<#
#    Collections.IComparerとCollections.Generic.IComparer[]を均すためのWrapper
#    ex. Collections.Specialized.OrderdDictionaryとCollections.Generic.SortedDictionary[]のComparerを共通に使える
#>
class CombinedComparerWrapper : CombinedComparer,handjive.IWrapper{
    hidden [object]$wpvSubstance

    CombinedComparerWrapper([Collections.Generic.IComparer[object]]$cmpr){
        $this.Substance = $cmpr
    }
    CombinedComparerWrapper([Collections.IComparer]$cmpr){
        $this.Substance = $cmpr
    }

    <# Members of handjive.IWrapper #>
    hidden [object]get_Substance(){
        return $this.wpvSubstance
    }
    hidden set_Substance([object]$subject){
        $this.wpvSubstance = $subject
    }

    <# SubclassResponsibilities of CompinedComparer #>
    [int]PSCompare([object]$left,[object]$right){
        return $this.Substance.Compare($left,$right)
    }
    [bool]PSEquals([object]$left,[object]$right){
        return(($this.Substance.Compare($left,$right) -eq 0));
    }
    [int]PSGetHashCode([object]$obj){
        return $obj.GetHashCode()
    }
}


<#
# コレクションをなんかした結果を取り出すアダプタ
# (Select-Objectでいい? -> PSObjectにWrapされない)
#>
class CollectionPluggableAdaptor : EnumerableBase,ICollectionAdaptor{
    [object]$Subject
    [ScriptBlock]$GetValueBlock = { $args[0] }

    CollectionPluggableAdaptor([object]$Subject,[ScriptBlock]$getValueBlock){
        $this.Subject = $Subject
        $this.GetValueBlock = $getValueBlock
    }

    [Collections.Generic.IEnumerable[object]]get_Values(){
        $enumr = [PluggableEnumerator]::new($this)
        $enumr.workingset.valueEnumerator = $this.Subject.GetEnumerator()
        $enumr.OnMoveNextBlock = {
            param($subject,$workingset)
            return($workingset.valueEnumerator.MoveNext())
        }
        $enumr.OnCurrentBlock = {
            param($subject,$workingset)
            return (&$subject.GetValueBlock $workingset.valueEnumerator.Current)
        }
        $enumr.OnResetBlock = {
            param($subject,$workingset)
            $workingset.valueEnumerator.Reset()
        }

        return $enumr.ToEnumerable()
    }
}
<# 
　コレクションから特定プロパティを取り出すアダプタ
#>
class CollectionAspectAdaptor : ICollectionAdaptor{
    [AspectAdaptor]$aspectAdaptor

    CollectionAspectAdaptor([object]$subject,[string]$aspect){
        $this.aspectAdaptor = [AspectAdaptor]::new($subject,$aspect)
    }

    hidden [object]GetAspectValue([object]$anObj){
        return ($this.aspectAdaptor.ValueUsingSubject($anObj))
    }

    [Collections.Generic.IEnumerator[object]]get_Values(){
        $enumr = [PluggableEnumerator]::new($this)
        $enumr.workingset.valueEnumerator = $this.Subject.GetEnumerator()
        $enumr.OnMoveNextBlock = {
            param($subject,$workingset)
            return($workingset.valueEnumerator.MoveNext())
        }
        $enumr.OnCurrentBlock = {
            param($subject,$workingset)
            $elem = $workingset.valueEnumerator.Current
            return $subject.GetAspectValue($elem)
        }
        $enumr.OnResetBlock = {
            param($subject,$workingset)
            $workingset.valueEnumerator.Reset()
        }
        return $enumr
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
# TODO: SortingComparerが機能してない? 
#
#  重複を無視する(が、重複数は保持する)コレクション
#　(格納対象オブジェクトはICompareable.CompareTo()に答える必要あり)
#
#   プロパティ
#       SortingComparer         Collections.IComparer { get; set }  ValuesSorted,ElementsSortedのソート順を決定するためのIComparer
#       ValuesOrdered           Collections.IEnumerator { get; }    追加順で値を返すEnumerator
#       ValuesSorted            Collections.IEnumerator { get; }    SortingComparer順で値を返すEnumerator。
#                                                                   比較の結果同じ(-eq)と判定されたオブジェクトは集約されてしまう。ValueOrderdの結果と食い違う事になるので注意。
#                                                                   (ValuesOrderdで返されるオブジェクトがValuesSortedには含まれない、という状況が起きる)
#       ElementsOrdered         Collections.IEnumerator { get; }    追加順で値と重複数([Bag]::ELEMENT_CLASSのインスタンス)を返すEnumerator
#       ElementsSorted          Collections.IEnumerator { get; }    SortingComparer順で値と重複数([Bag]::ELEMENT_CLASSのインスタンス)を返すEnumerator
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
class Bag : handjive.IWrapper,IBag{
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
        $this.SetAll($aBag)
    }
    Bag([Bag]$aBag,[CombinedComparer]$comparer){
        $this.Initialize($comparer)
        $this.SetAll($aBag)
    }
    <#Bag([object[]]$elements){
        $this.Initialize([PluggableComparer]::New())
        $this.AddAll($elements)
    }
    Bag([object[]]$elements,[CombinedComparer]$comparer){
        $this.Initialize($comparer)
        $this.AddAll($elements)
    }
    Bag([Collections.Generic.IEnumerator[object]]$enumerator){
        $this.Initialize([PluggableComparer]::New())
        $this.AddAll($enumerator)
    }
    Bag([Collections.Generic.IEnumerator[object]]$enumerator,[CombinedComparer]$comparer){
        $this.Initialize($comparer)
        $this.AddAll($enumerator)
    }#>
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
        $this.wpvValueSet = ([Bag]::VALUESET_CLASS)::new(<#[Collections.Generic.IComparer[object]]#>$aComparer)
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

    [Collections.Generic.IEnumerable[object]]get_ElementsSorted(){
        $enumerator = $this.create_ElementsEnumerator()
        $enumerator.WorkingSet.valueEnumerator = $this.basicValuesSorted()
        $enumerator.PSReset()
        return($enumerator.ToEnumerable())
    }

    [Collections.Generic.IEnumerable[object]]get_ElementsOrdered(){
        $enumerator = $this.create_ElementsEnumerator()
        $enumerator.WorkingSet.valueEnumerator = $this.basicValuesOrdered()
        $enumerator.PSReset()
        return($enumerator.ToEnumerable())
    }

    <#hidden [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        $enumerator = $this.get_ElementsOrdered()
        return($enumerator)
    }#>
    
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
        $result = [Linq.Enumerable]::IntersectBy[object,object]([EnumerableWrapper]::on($this.ValuesSorted),$values,[Func[object,object]]$comparer.GetSubjectBlock)
      
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
        $result = [Linq.Enumerable]::Except([EnumerableWrapper]::on($this.ValuesSorted),$enumerable,$comparer)
        $result.foreach{
            $this.basicAdd($newDict,$_)
        }
        return($newDict)
    }

    ExceptWith([Collections.Generic.IEnumerable[object]]$enumerable,[CombinedComparer]$comparer){
        $this.Substance = $this.basicExceptWith($enumerable,$comparer)
    }
}


class IndexedBagElement : BagElement{
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

    [Collections.Generic.IEnumerator[object]]get_Indexes(){
        $enumr = [PluggableEnumerator]::new($this)
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
        return $enumr
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

    [Collections.Generic.IEnumerator[object]]get_ElementsSorted(){
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
    [Collections.Generic.IEnumerator[object]]get_ElementsOrdered(){
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

    Add([object]$value){
        ([Bag]$this).Add($value)

        $index = $this.GetIndexOf($value)
        if( $null -eq $this.wpvIndexDictionary[$index] ){
            # ComparerがCombinedComparerじゃなかったらWrapする?(できる?)
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