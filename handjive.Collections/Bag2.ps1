using namespace handjive.Collections


<#
# Bag.ValuesAndOccurrencesSorted用のComperer
# Default2種
#>
class BagValuesAndOccurrencesComparer : PluggableComparer{
    <# Sort by Occurrence, Value's Subject Ascening #>
    static $DefaultAscendingBlock = { 
        param($left,$right,$comparer) 

        $leftValueSubject = &$comparer.SubjectUsingValueBlock $left.Value
        $rightValueSubject = &$comparer.SubjectUsingValueBlock $right.Value

        if( $left.Occurrence -eq $right.Occurrence ){
            if( $leftValueSubject -eq $rightValueSubject ){ return 0 } elseif( $leftValueSubject -lt $rightValueSubject ){ return -1 } else{ return 1 }
        }
        elseif( $left.Occurrence -lt $right.Occurrence ){ return -1 } else{ return 1 }
    }

    <# Sort by Occurrence, Value's Subject Descening #>
    static $DefaultDescendingBlock = {  
        param($left,$right,$comparer) 

        $leftValueSubject = &$comparer.SubjectUsingValueBlock $left.Value
        $rightValueSubject = &$comparer.SubjectUsingValueBlock $right.Value

        if( $left.Occurrence -eq $right.Occurrence ){
            if( $leftValueSubject -eq $rightValueSubject ){ return 0 } elseif( $leftValueSubject -lt $rightValueSubject ){ return 1 } else{ return -1 }
        }
        elseif( $left.Occurrence -lt $right.Occurrence ){ return 1 } else{ return -1 }
    }

    static [BagValuesAndOccurrencesComparer]DefaultAscending(){
        $comparer = [BagValuesAndOccurrencesComparer]::new()
        $comparer.CompareBlock = [BagValuesAndOccurrencesComparer]::DefaultAscendingBlock
        return $comparer
    }
    static [BagValuesAndOccurrencesComparer]DefaultDescending(){
        $comparer = [BagValuesAndOccurrencesComparer]::new()
        $comparer.CompareBlock = [BagValuesAndOccurrencesComparer]::DefaultDescendingBlock
        return $comparer
    }

    [ScriptBlock]$SubjectUsingValueBlock = { $args[0] }

    BagValuesAndOccurrencesComparer() : base(){
        $this.SetDefaultAscending()
    }

    [object]subjectUsingValue([object]$elem){
        return &$this.SubjectUsingValueBlock $elem.Value
    }
    
    SetDefaultAscending(){
        $this.CompareBlock = ($this.gettype())::DefaultAscendingBlock
    }

    SetDefaultDescending(){
        $this.CompareBlock = ($this.gettype())::DefaultDescendingBlock
    }
}

<#
    $aBag[int] → $aBag.elements[int]
    $aBag.Count→ $aBag.elements.Count
    $aBag.GetEnumerator()→ $aBag.elements.GetEnumerator()
    
    $aBag.ValuesOrdered → IndexAdaptor
    $aBag.ValuesOrdered[int] → $aBag.occurrences.keys[int]
    $aBag.ValuesOrdered.GetEnumerator()
    
    $aBag.ValuesSorted → IndexAdaptor
    $aBag.ValuesSorted[int]
    $aBag.ValuesSorted.GetEnumerator()

    $aBag.ValuesAndOccurrences → IndexAdaptor
    $aBag.ValuesAndOccurrencesSorted → IndexAdaptor
#>
class Bag2 : handjive.Collections.IndexableEnumerableBase, handjive.Collections.IBag2{
    static $vAoComparerClass = [BagValuesAndOccurrencesComparer]    # ValuesAndOccurrencesSorted用のComparer
    static $valueComparerClass = [PluggableComparer]                # ValuesSorted用のComparer

    [Collections.ArrayList]$elements
    [Collections.Specialized.OrderedDictionary]$occurrences

    [HashTable]$SortingComparer
    [HashTable]$Adaptors

    <#
    # Constructors
    #>
    Bag2() : base(){
        $this.initialize($null,$null)
    }
    Bag2([Collections.Generic.IEnumerable[object]]$elements) : base(){
        $this.initialize($null,$null)
        $this.AddAll($elements)
    }
    Bag2([CombinedComparer]$valueComparer):base(){
        $this.initialize($valueComparer,$null)
    }
    Bag2([Collections.Generic.IEnumerable[object]]$elements,[CombinedComparer]$valueComparer):base(){
        $this.initialize($valueComparer,$null)
        $this.AddAll($elements)
    }


    <#
    # Internal methods
    #>
    hidden initialize([CombinedComparer]$valueComparer,[CombinedComparer]$vAoComparer){
        $this.elements = [Collections.ArrayList]::new()

        if( $null -eq $valueComparer ){
            $this.occurrences = [Collections.Specialized.OrderedDictionary]::new()
        }
        else{
            $this.occurrences = [Collections.Specialized.OrderedDictionary]::new($valueComparer)
        }

        $thisType = $this.gettype()
        if( $null -eq $valueComparer ){
            $valueComparer = $thisType::valueComparerClass::new()
        }
        if( $null -eq $vAoComparer ){
            $vAoComparer = $thisType::vAoComparerClass::new()
        }

        $vAoComparer.GetSubjectBlock = $valueComparer.GetSubjectBlock
        $this.SortingComparer = @{
            Values = $valueComparer;
            ValuesAndOccurrences = $vAoComparer;
        }
        
        if( $valueComparer -is [PluggableComparer] ){
            $valueComparer.CompareBlockHolder.AddValueChangedListener($this,{ param($listener,$args1,$args2) $listener.ValuesChanged() })
        }
        if( $vAoComparer -is [PluggableComparer] ){
            $vAoComparer.CompareBlockHolder.AddValueChangedListener($this,{ param($listener,$args1,$args2) $listener.ValuesChanged() })
        }
        $this.ValuesChanged()
    }

    hidden ValuesChanged(){
        $this.Adaptors = @{ ValuesSorted=$null; ValuesOrdered=$null; ValuesAndOccurrencesSorted=$null; ValuesAndOccurrencesOrdered=$null; }
    }


    <#
    # Property implementations
    #>
    hidden [int]get_Count(){
        return $this.elements.Count
    }

    hidden [int]get_CountOccurrences(){
        return $this.get_CountWithoutDuplicate()
    }

    hidden [int]get_CountWithoutDuplicate(){
        <#
        # なんでpsbase介さないとCountが取れないのか理解できんものの…
        # (メソッドサーチのしくじりが原因? ベースクラスをIndexableEnumerableBaseにしたら解消した…)
        #>
        return $this.occurrences.Count
    }

    hidden [Collections.Generic.IEnumerable[object]]get_Values(){ 
        return $this.ValuesOrdered()
    }

    hidden [Collections.Generic.IEnumerable[object]]get_ValuesOrdered(){ 
        if( $null -eq $this.Adaptors.ValuesOrdered ){
            $ixa = [IndexAdaptor]::new($this.occurrences)
            $ixa.GetSubjectBlock = { param($substance,$workingset,$results) $results.Value = $substance.keys }
            $ixa.GetEnumeratorBlock = { param($subject,$workingset,$results) $results.Value = [PluggableEnumerator]::InstantWrapOn($subject.GetEnumerator()) }
            $this.Adaptors.ValuesOrdered = $ixa
        }
        return $this.Adaptors.ValuesOrdered
    }

    hidden [Collections.Generic.IEnumerable[object]]get_ValuesSorted(){
        if( $null -eq $this.Adaptors.ValuesSorted ){
            $keySelector = $this.SortingComparer.Values.GetSubjectBlock
            $comparer = $this.SortingComparer.Values
            $values = ([PluggableEnumerator]::InstantWrapOn($this.occurrences.keys)).ToEnumerable()
            $sorted = [Linq.Enumerable]::OrderBy[object,object]($values,[func[object,object]]{ $args[0] },$comparer)
            $list = [Collections.Generic.List[object]]::new($sorted)
            $ixa = [IndexAdaptor]::new($list)
            $this.Adaptors.ValuesSorted = $ixa
        }
        return $this.Adaptors.ValuesSorted
    }

    hidden [Collections.Generic.IEnumerable[object]]basicValuesAndOccurrences(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.WorkingSet.keys = $this.occurrences.keys.GetEnumerator()
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            return($workingset.keys.MoveNext())
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $key = $workingset.keys.Current
            if( $null -eq $key ){
                return (@{ Value=$null; Occurrence=0 })
            }
            else{
                $subject = $key
                return(@{ Value=$subject; Occurrence=($substance.occurrences[$subject].Count); })
            }
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.keys.Reset()
        }

        return($enumerator.ToEnumerable())
    }

    hidden [IndexAdaptor]basicValuesAndOccurrencesIndexAdaptor(){
        $ixa = [IndexAdaptor]::new($this)
        $ixa.GetEnumeratorBlock = {
            param($subject,$workingset,$result)
            $enumerator = [PluggableEnumerator]::new($this)
            $enumerator.WorkingSet.vAoEnumerator = $workingset.vAoEnumerator
            $enumerator.OnMoveNextBlock = {
                param($substance,$workingset)
                return($WorkingSet.vAoEnumerator.MoveNext())
            }
            $enumerator.OnCurrentBlock = {
                param($substance,$workingset)
                return($WorkingSet.vAoEnumerator.Current)
            }
            $enumerator.OnResetBlock = {
                param($substance,$workingset)
                $workingset.vAoEnumerator.Reset()
            }
            $enumerator.PSReset()
            $result.Value = $enumerator
        }
        $ixa.GetItemBlock.Int = {
            param($subject,$workingset,[int]$index)
            return($workingset.vAoArray[$index])
        }
        $ixa.GetCountBlock = {
            param($subject,$workingset)
            return($workingset.vAoArray.Count)
        }
            
        
        return $ixa
    }

    hidden [Collections.Generic.IEnumerable[object]]get_ValuesAndOccurrences(){
        return $this.get_ValuesAndOccurrencesSorted()
    }

    hidden [Collections.Generic.IEnumerable[object]]get_ValuesAndOccurrencesOrdered(){
        $ixa = $this.basicValuesAndOccurrencesIndexAdaptor()
        $valuesAndOccurrences = $this.basicValuesAndOccurrences()
        $ixa.WorkingSet.vAoEnumerator = $valuesAndOccurrences.GetEnumerator()
        $ixa.WorkingSet.vAoArray = [Collections.Generic.List[object]]::new($valuesAndOccurrences)
        $this.Adaptors.ValuesAndOccurrencesOrdered = $ixa
        return $this.Adaptors.ValuesAndOccurrencesOrdered
    }

    hidden [Collections.Generic.IEnumerable[object]]get_ValuesAndOccurrencesSorted(){
        if( $null -eq $this.Adaptors.ValuesAndOccurrencesSorted ){
            $comparer = $this.SortingComparer.ValuesAndOccurrences
            $sorted = [Linq.Enumerable]::OrderBy[object,object]($this.basicValuesAndOccurrences(),[func[object,object]]{ $args[0] },$comparer)
            $ixa = $this.basicValuesAndOccurrencesIndexAdaptor()
            $ixa.WorkingSet.vAoEnumerator = ([Collections.Generic.List[object]]::new($sorted)).GetEnumerator()
            #$ixa.WorkingSet.vAoEnumerator = $sorted.GetEnumerator()
            $ixa.WorkingSet.vAoArray = [Collections.Generic.List[object]]::new($sorted)

            $this.Adaptors.ValuesAndOccurrencesSorted = $ixa
        }
        return $this.Adaptors.ValuesAndOccurrencesSorted
    }


    <#
    # Methods: 
    #>
    [int]OccurrencesOf([object]$elem){
        return $this.occurrences[[object]$elem].Count
    }
    
    [bool]Includes([object]$elem){
        return ($null -ne $this.occurrences[[object]$elem])
    }

    [object[]]OccurrenceValuesOf([object]$elem){
        return($this.occurrences[[object]$elem])
    }


    <#
    # Methods: Add/Remove/Clear
    #>
    hidden addOccurrencesOf([object]$value){
        $subject = $value
        if( $null -eq ($this.occurrences[[object]$subject]) ){
            $occurs = [Collections.ArrayList]::new()
            $occurs.Add($value)
            $this.occurrences.Add($subject,$occurs)
        }
        else{
            ($this.occurrences[[object]$subject]).Add($value)
        }
    }
    hidden removeOccurrencesOf([object]$value){
        $subject = $value
        if( $null -eq $this.occurrences[[object]$subject] ){
            return
        }
        if( $this.occurrences[[object]$value].Count -eq 1 ){
            $this.occurrences.Remove([object]$subject)
        }
        else{
            $occur = $this.occurrences[[object]$subject]
            $occur.Remove($value)
        }
    }

    Add([object]$elem){
        $this.elements.Add($elem)
        $this.addOccurrencesOf($elem)
        $this.ValuesChanged()
    }
    AddAll([Collections.Generic.IEnumerable[object]]$elements){
        $elements.foreach{
            $this.Add([object]$_)
        }
    }

    Remove([object]$elem){
        $this.removeOccurrencesOf($elem)
        $this.elements.Remove($elem)
        $this.ValuesChanged()
    }
    RemoveAll([Collections.Generic.IEnumerable[object]]$elements){
        $elements.foreach{
            $this.Remove($_)
        }
    }
    Purge([object]$elem){
        if( $null -ne $this.occurrences[$elem] ){
            $this.occurrences[[object]$elem] = 1
            $this.Remove($elem)
            $this.ValuesChanged()
        }
    }
    PurgeAll([Collections.Generic.IEnumerable[object]]$elements){
        $elements.foreach{
            $this.Purge($_)
        }
    }

    Clear(){
        $this.elements.Clear()
        $this.occurrences.Clear()
    }

    <#
    # Methods: Converting
    #>
    [Collections.Generic.HashSet[object]]ToSet(){
        $aSet = [Collections.Generic.HashSet[object]]::new($this.occurrences.Keys,$this.SortingComparer.Values)
        return $aSet
    }

    <#
    # Methods: Filtering    
    # BagにDistinctは要るのか問題。
    # (ValuesAndOccurrencesが既にDistinctぢゃね?)
    # Iteration(Select,Collect,Detect,InjectIntoとかはStremAdaptorでいいきもしなくもなくもなくない
    # どう分けたらいいんﾀﾞﾛｶ…?
    #>
    [Collections.Generic.IEnumerable[object]]DistinctBy([func[object,object]]$keySelector){
        $result = [Linq.Enumerable]::DistinctBy[object,object]($this,$keySelector)
        return $result
    }
    
    [Collections.Generic.IEnumerable[object]]Where([func[object,bool]]$nominator){
        $result = [Linq.Enumerable]::Where[object]($this,$nominator)
        return $result
    }


    <#
    # Subclass repsponsibilities about: IndexableEnumerableBase 
    #>
    hidden [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return [PluggableEnumerator]::InstantWrapOn($this.elements)
    }

    hidden [object]PSGetItem_IntIndex([int]$index){
        return $this.elements[$index]
    }

    hidden PSSetItem_IntIndex([int]$index,[object]$value){
        $old = $this.elements[$index]
        $this.Remove($old)
        $this.elements[$index] = $value
        $this.addOccurrencesOf($value)
    }


}

