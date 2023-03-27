<#
    重複を無視する(が、重複数は保持する)コレクション

    Values
    Includes
    OccurrencesOf
    [[int]$index] (keys[$index]を返す)
    Add
    AddAll
    Remove
    RemoveAll
    Count

#>

class ValuesAndOccurrencesEnumerator : Collections.IEnumerator{
    [Collections.IDictionary]$Substance
    [Collections.IEnumerator]$keyEnumerator

    ValuesAndOccurrencesEnumerator([AbstractBag]$aBag){
        $this.Substance = $aBag.Substance
        $this.keyEnumerator = $this.Substance.keys.GetEnumerator()
    }
    
    [object]get_Current(){
        $aKey = $this.keyEnumerator.Current
        $aValue = $this.Substance[$aKey]
        
        return(@{ Value=$aKey; Occurrences = $aValue.Count; })
    }
    
    [bool]MoveNext(){
        return($this.keyEnumerator.MoveNext())
    }
    
    Reset(){
        $this.keyEnumerator.Reset()
    }
}

class AbstractBag : handjive.IWrapper,handjive.Collections.IBag{
    [Collections.IDictionary]$wpvSubstance

    [object]get_Substance(){
        return($this.wpvSubstance)
    }
    set_Substance([object]$aSubstance){
        $this.wpvSubstance = $aSubstance
    }

    [System.Collections.IEnumerator]get_Values(){
        return($this.Substance.Keys.GetEnumerator())
    }
    <#[object[]]get_Values(){
        return($this.Substance.Keys)
    }#>
    [int]get_Count(){
        return($this.Substance.Count)
    }
    [Collections.IEnumerator]get_ValuesAndOccurrences(){
        $enumrator = [ValuesAndOccurrencesEnumerator]::new($this)
        return($enumrator)
    }
    
    [object]get_Item([int]$index){
        return($this.Substance[$index])
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
            $this.Substance[$aValue] = [Collections.ArrayList]::new()
        }
        ($this.Substance[$aValue]).Add($aValue)
    }
    Remove([object]$aValue){
        $this.Substance.Remove($aValue)
    }
}

class OrderedBag : AbstractBag{
    OrderedBag(){
        $this.Substance = [System.Collections.Specialized.OrderedDictionary]::new()
    }
}


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




