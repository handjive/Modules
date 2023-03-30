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

    hidden [object]calcvalue([int]$value,[int]$step,[int]$stop,[scriptblock]$ifOutOfRange)
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
        while($this.MoveNext()){
            $result += $this.Current
        }
        return($result)
    }
}


<#
#  重複を無視する(が、重複数は保持する)コレクション
#>
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

class AbstractBag : handjive.Collections.EnumerableBase,handjive.IWrapper,handjive.Collections.IBag,Collections.IEnumerable{
    static $ELEMENT_CLASS = [BagElement]
    [Collections.IDictionary]$wpvSubstance

    AbstractBag() : base(){
    }
    AbstractBag([BagElement[]]$elements) : base(){
        $this.SetAll($elements)
    }

    [object]newElement(){
        return(([AbstractBag]::ELEMENT_CLASS)::new())
    }

    [object]get_Substance(){
        return($this.wpvSubstance)
    }
    set_Substance([object]$aSubstance){
        $this.wpvSubstance = $aSubstance
    }

    [System.Collections.IEnumerator]get_Values(){
        return($this.Substance.Keys.GetEnumerator())
    }

    [int]get_Count(){
        return($this.Substance.Count)
    }

    [Collections.IEnumerator]get_ValuesAndOccurrences(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.WorkingSet.keyEnumerator = $this.Substance.keys.GetEnumerator()
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $aKey = $workingset.keyEnumerator.Current
            $aValue = $substance[$aKey]
            $elem = $substance.newElement()
            $elem.Value = $aKey
            $elem.Occurrence = $aValue
            return($elem)
        }
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            return($workingset.keyEnumerator.MoveNext())
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.keyEnumerator.Reset()
        }

        return($enumerator)
    }
    
    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return($this.ValuesAndOccurrences)
    }
    
    [object]get_Item([int]$index){
        return($this.Substance.keys[$index])
    }
    set_Item([int]$index,[object]$value){
        $this.Substance[$index] = $value
    }

    [object]get_Item([object]$key){
        return($this.Substance[$key])
    }
    set_Item([object]$key,[object]$value){
        $this.Substance[$key] = $value
    }

    Add([object]$aValue){
        if( $null -eq $this.Substance[$aValue] ){
            $this.Substance[$aValue] = 0
        }
        ($this.Substance[$aValue])++
    }
    AddAll([object[]]$values){
        $values.foreach{ $this.Add($_) }
    }
    
  
    Remove([object]$aValue){
        if( $null -eq $this.Substance[$aValue] )
        {
            return
        }

        if( $this.Substance[$aValue] -eq 1 ){
            $this.Substance.Remove($aValue)
        }
        else{
            $this.Substance[$aValue]--
        }
    }
    RemoveAll([object[]]$values){
        $values.foreach{ $this.Remove($_) }
    }


    Set([BagElement]$element){
        $this.Substance[$element.Value] = $element.Occurrence
    }
    SetAll([BagElement[]]$elements){
        $elements.foreach{ $this.Set($_) }
    }


    Purge([object]$aValue){
        $this.Substance.Remove($aValue)
    }
    PurgeAll([object[]]$values){
        $values.foreach{ $this.Purge($_) }
    }
}

class OrderedBag : AbstractBag{
    OrderedBag(){
        $this.Substance = [System.Collections.Specialized.OrderedDictionary]::new()
    }
}

class SortedBag : AbstractBag{
    SortedBag(){
        $this.Substance = [System.Collections.Generic.SortedDictionary[object,object]]::new()
    }
}

class IndexedBagElement {
    [object]$Index
    [AbstractBag]$Value

    IndexedBagElement(){
    }
    IndexedBagElement([object]$index,[AbstractBag]$value){
        $this.Index = $index
        $this.Values = $value
    }
    [System.Collections.Generic.KeyValuePair[object,AbstractBag]]ToKeyValuePair(){
        return([System.Collections.Generic.KeyValuePair[object,AbstractBag]]::new($this.Index,$this.Value))
    }
}

class IndexedBag : handjive.IWrapper{
    [ScriptBlock]$GetIndexBlock

    hidden [object]$BagType
    hidden [AbstractBag]$wpvSubstance

    IndexedBag([object]$dictType,[object]$bagType){
        $this.GetIndexBlock = { $args[0] }
        $this.BagType = $bagType
        $this.wpvSubstance = $dictType::new()
    }

    [object]get_Substance(){
        return($this.wpvSubstance)
    }
    set_Substance([object]$substance){
        $this.wpvSubstance = $substance
    }

    Add([object]$value){
        $index = &$this.GetIndexBlock $value
        if( $null -eq $this.Substance[$index] ){
            $this.Substance[$index] = $this.BagType::new()
        }
        ($this.SUbstance[$index]).Add($value)
    }

    Remove([object]$value){
        $index = &$this.GetIndexBlock $value
        if( ($this.Substance[$index]).Count -eq 1 ){
            $this.Substance.Remove($index)
            return
        }

        ($this.Substance[$index]).Remove($value)
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

# OrderedDictionary/SortedDictionaryベースで再考
<#class Bag : System.Collections.ArrayList, handjive.Collections.IBag {
    [HashTable]$Substance

    Bag(){
        $this.Substance = @{}
    }

    [object[]]get_Values(){
        $values = $this.Substance.keys | Sort-Object
        return($values)
    }

    [Object]get_Item([int]$index){
        $keys = $this.Values
        return($keys[$index])
    }
    set_Item([int]$index,[Object]$value){
        throw 'Assignment by index does not supported.'
        $key = $this.get_Item($index)
        $this.Remove($key)
        $this.Add($value)
    }

    [int]get_Count(){
        return($this.Substance.Keys.Count)
    }

    Add([object]$var){
       if( $null -eq $this.Substance[$var] ){
            $this.Substance[$var] = @()
        }
        [array]($this.Substance[$var]) += @( $var )
    }
    AddAll([object[]]$vars){
        $vars.foreach{ $this.Add($_) }
    }

    Remove([object]$var){
        $this.Substance.Remove($var)
    }
    RemoveAll([object[]]$vars){
        $vars.foreach{ $this.Remove($_) }
    }

    [int]OccurrencesOf([object]$var){
        return(($this.Substance[$var]).Count)
    }

    [bool]Includes([object]$var){
        return( $null -ne $this.Substance[$var]) 
    }

    [object[]]get_ValuesAndOccurrences(){
        $result = @()
        $values = $this.Values
        $Values.foreach{
            $kvp =@{ value=$_; occurrences=$this.OccurrencesOf($_); }
            $result += $kvp
        }
        return($result)
    }
}

class IndexedBag : System.Collections.ArrayList,handjive.Collections.IKeyedBag{
    [ScriptBlock]$GetIndexBlock
    [HashTable]$Index

    IndexedBag() : base(){
        $this.GetIndexBlock = { $argv[0] }
        $this.Index = [ordered]@{}
    }

    [object]get_Item([object]$index){
        return($this.Index[$index])
    }
    [Object]get_Item([int]$index){
        $keys = $this.Index.Keys | Sort-object
        return($this.get_Item($keys[$index]))
    }

    [object[]]get_Indices(){
        return(($this.Index.Keys|Sort-Object))
    }
    [object[]]get_Values(){
        return($this.Index.Values.Values) #!!
    }
    [int]get_Count(){
        return($this.Index.Keys.Count)
    }
    [object[]]get_IndicesAndValues(){
        $result = @()
        $this.Keys.foreach{
            $key = $_
            ($this.Index[$_]).Values.foreach{
                $elem = @{} 
                $elem.Add('Value',$_)
                $elem.Add('Key',$key)
                $result += $elem
            }
        }
        return($result)
    }

    [object[]]get_IndicesAndValuesAndOccurrences(){
        $result = @()
        $this.Index.Keys.foreach{
            $key = $_
            $aBag = $this.Index[$_]
            $aBag.ValuesAndOccurrences.foreach{
                $elem = @{}
                $elem['key'] = $key
                $elem['Value'] = $_.Value
                $elem['Occurrences'] = $_.Occurrences
                $result += $elem
            }
        }
        return($result)
    }

    KeysAndValuesAndOccurrencesDo([ScriptBlock]$aBlock){
        $this.Index.Keys.foreach{
            $key = $_
            $aBag = $this.Index[$_]
            $aBag.ValuesAndOccurrences.foreach{
                $elem = @{}
                $elem['key'] = $key
                $elem['Value'] = $_.Value
                $elem['Occurrences'] = $_.Occurrences
                &$aBLock $elem
            }
        }
    }

    [int]IndicesOccurrencesOf([string]$index){
        return ($this.Index[$index].Count)
    }

    Add([object]$elem){
        $key = [string](&$this.GetIndexBlock $elem)
        if( $null -eq $this.Index[$key] ){
            $this.Index[$key] = [Bag]::new()
        }
        ($this.Index[$key]).Add($elem)
    }
    AddAll([object[]]$elements){
        $elements.foreach{
            $this.Add($_)
        }
    }

    Remove([object]$elem){
        $key = &$this.GetIndexBlock $elem
        ($this.Index[$key]).Remove($elem)
    }


}

class xhashtable : HashTable,handjive.Collections.IGetKeyBlock{
    [ScriptBlock]$GetKeyBlock

    xhashtable():base(){
        $this.psbase.GetKeyBlock = { $args[0] }
    }

    [object]get_GetKeyBlock(){
        return($this.psbase.GetKeyBlock)
    }
    set_GetKeyBlock([object]$aBlock){
        $this.psbase.GetKeyBlock = $aBlock
    }

    [Collections.ICollection]get_Keys(){
        $keys =([HashTable]$this).get_keys()
        return($keys)
    }

    [Collections.ICollection]get_Values(){
        $values = ([HashTable]$this).get_Values()
        return($values)
    }
    [Object]get_Item([Object]$key){
        $value = ([HashTable]$this).get_Item($key)
        return($value)
    }
    set_Item([Object]$key,[Object]$value){
        ([HashTable]$this).set_Item($key,$value)
    }

    Add([object]$elem){
        $key = &($this.psbase.GetKeyBlock) $elem
        if( $null -eq $this[$key] ){
            $this[$key] = @()
        }
        $this[$key] += $elem
    }
    AddAll([object[]]$vars){
        $vars.foreach{ $this.Add($_) }
    }

    Remove([object]$var){
        $key = &$this.psbase.GetKeyBlock $var
        $this.Remove($key)
    }
    RemoveAll([object[]]$vars){
        $vars.foreach{ $this.Remove($_) }
    }

    [int]OccurrencesOf([object]$elem){
        $key = &$this.psbase.GetKeyBlock $elem
        return(($this[$key]).Count)
    }

    [object]Includes([object]$elem){
        $key = &$this.psbase.GetKeyBlock $elem
        return( $null -ne $this[$key])
    }
}

class DerivedHT : HashTable{
    [ScriptBlock]$GetKeyBlock

    DerivedHT():base(){
        $this.GetKeyBlock = { $args[0] }
    }

    Add([object]$elem){
        if( $null -eq $this[$elem] ){
            $this[$elem] = @()
        }
        $this[$elem] += $elem
    }

    [int]OccurrencesOf([object]$elem){
        return(($this[$elem]).Count)
    }

    [object]Includes([object]$elem){
        return( $null -ne $this[$elem])
    }
}
#>




