using namespace handjive.Collections


<#
# Bag.ValuesAndOccurrencesSorted用のComperer
# Default2種
#>
class BagValuesAndOccurrencesComparer : PluggableComparer{
    <# Sort by Occurrence, Value's Subject Ascening #>
    static $DefaultAscendingBlock = { 
        param($left,$right,$comparer) 

        $leftkey = $comparer.subjectUsingValue($left)
        $rightKey = $comparer.subjectUsingValue($right)

        if( $leftkey -lt $rightkey ){
            return -1
        }
        elseif( $leftkey -gt $rightkey ){
            return 1
        }
        elseif( $leftkey -eq $rightkey ){
            return 0 
        }
    }

    <# Sort by Occurrence, Value's Subject Descening #>
    static $DefaultDescendingBlock = {  
        param($left,$right,$comparer) 

        $leftkey = $comparer.subjectUsingValue($left)
        $rightKey = $comparer.subjectUsingValue($right)

        if( $leftkey -lt $rightkey ){
            return 1
        }
        elseif( $leftkey -gt $rightkey ){
            return -1
        }
        elseif( $leftkey -eq $rightkey ){
            return 0 
        }
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
        return &$this.SubjectUsingValueBlock $elem
    }
    
    SetDefaultAscending(){
        $this.SetDefaultAscendingByValue()
    }
    SetDefaultAscendingByValue(){
        $this.CompareBlock = ($this.gettype())::DefaultAscendingBlock
        $this.SubjectUsingValueBlock = { $args[0].Value }
    }
    SetDefaultAscendingByOccurrence(){
        $this.CompareBlock = ($this.gettype())::DefaultAscendingBlock
        $this.SubjectUsingValueBlock = { $args[0].Occurrence }
    }

    SetDefaultDescending(){
        $this.SetDefaultDescendingByValue()
    }
    SetDefaultDescendingByValue(){
        $this.CompareBlock = ($this.gettype())::DefaultDescendingBlock
        $this.SubjectUsingValueBlock = { $args[0].Value }
    }
    SetDefaultDescendingByOccurrence(){
        $this.CompareBlock = ($this.gettype())::DefaultDescendingBlock
        $this.SubjectUsingValueBlock = { $args[0].Occurrence }
    }
}

class SortingComparerHolder : handjive.Collections.ISortingComparerHolder{
    hidden [Bag2]$substance
    hidden [ValueHolder]$wpvValues
    hidden [ValueHolder]$wpvValuesAndOccurrences

    SortingComparerHolder([Bag2]$substance){
        $this.substance = $substance

        $this.wpvValues = [ValueHolder]::new()
        $this.wpvValues.AddValueChangedListener($substance,{ param($substance,$args1,$args2) $substance.OnValuesComparerChanged() } )

        $this.wpvValuesAndOccurrences = [ValueHolder]::new()
        $this.wpvValues.AddValueChangedListener($substance,{ param($substance,$args1,$args2) $substance.OnValuesAndOccurrencesComparerChanged() } )
    }

    [CombinedComparer]get_Values(){
        return $this.wpvValues.Value()
    }
    set_Values([CombinedComparer]$comparer){
        $this.wpvValues.Value($comparer)
    }
    [CombinedComparer]get_ValuesAndOccurrences(){
        return $this.wpvValuesAndOccurrences.Value()
    }
    set_ValuesAndOccurrences([CombinedComparer]$comparer){
        $this.wpvValuesAndOccurrences.Value($comparer)
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

    [SortingComparerHolder]$SortingComparer
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
        $this.occurrences = [Collections.Specialized.OrderedDictionary]::new()

        $thisType = $this.gettype()
        if( $null -eq $valueComparer ){
            $valueComparer = $thisType::valueComparerClass::new()
        }
        if( $null -eq $vAoComparer ){
            $vAoComparer = $thisType::vAoComparerClass::new()
        }

        #$vAoComparer.GetSubjectBlock = $valueComparer.GetSubjectBlock
        #SuppressDependentsDo
        $this.SortingComparer = [SortingComparerHolder]::new($this)
        $this.SortingComparer.Values = $valueComparer
        $this.SortingComparer.ValuesAndOccurrences = $vAoComparer
        #$this.SortingComparer.Values.SuppressDependentsDo({  })
        #$this.SortingComparer.ValuesAndOccurrences.SuppressDependentsDo({  })
        
        if( $valueComparer -is [PluggableComparer] ){
            $valueComparer.CompareBlockHolder.AddValueChangedListener($this,{ param($listener,$args1,$args2) $listener.ValuesChanged() })
        }
        if( $vAoComparer -is [PluggableComparer] ){
            $vAoComparer.CompareBlockHolder.AddValueChangedListener($this,{ param($listener,$args1,$args2) $listener.ValuesChanged() })
        }
    
        $this.ValuesChanged()
    }

    <# 
    # Dependency handlers 
    #>
    hidden OnValuesComparerChanged(){
        $this.rebuildOccurrences()
        $this.ValuesChanged()
    }
    
    hidden OnValuesAndOccurrencesComparerChanged(){
        #write-host 'OnValuesAndOccurrencesComparerChanged()'
    }

    hidden ValuesChanged(){
        if( $null -eq $this.Adaptors ){
            $this.Adaptors = @{ ValuesSorted=$null; ValuesOrdered=$null; ValuesAndOccurrencesSorted=$null; ValuesAndOccurrencesOrdered=$null; }
        }
        else{
            $this.Adaptors.ValuesSorted = $null
            $this.Adaptors.ValuesAndOccurrencesSorted=$null
        }
        # = @{ ValuesSorted=$null; ValuesOrdered=$null; ValuesAndOccurrencesSorted=$null; ValuesAndOccurrencesOrdered=$null; }
    }

    hidden rebuildOccurrences(){
        if( $this.elements.Count -eq 0 ){
            return
        }
        
        $this.occurrences = [Collections.Specialized.OrderedDictionary]::new()
        $this.elements.foreach{
            $this.addOccurrencesOf($_)
        }
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
        return $this.occurrences.Count
    }

    hidden [IndexableEnumerableBase]get_Values(){ 
        return $this.ValuesOrdered()
    }

    hidden [IndexableEnumerableBase]get_ValuesOrdered(){ 
        if( $null -eq $this.Adaptors.ValuesOrdered ){
            $ixa = [IndexAdaptor]::new([EnumerableWrapper]::On($this.elements))
            #$ixa.GetSubjectBlock = { param($substance,$workingset,$results) 
            #    $results.Value = $substance.keys }
            $ixa.GetEnumeratorBlock = { param($subject,$workingset,$results) 
                $results.Value = [PluggableEnumerator]::InstantWrapOn($subject.GetEnumerator()) }
            $ixa.GetItemBlock.Int = { param($subject,$workingset,$index) 
                $subject.Substance[$index] }
            $ixa.GetCountBlock = { param($subject,$workingset,$index) $subject.Substance.Count }
            $this.Adaptors.ValuesOrdered = $ixa
        }
        return $this.Adaptors.ValuesOrdered
    }

    hidden [IndexableEnumerableBase]get_ValuesSorted(){
        if( $null -eq $this.Adaptors.ValuesSorted ){
            #$keySelector = $this.SortingComparer.Values.GetSubjectBlock
            $comparer = $this.SortingComparer.Values
            $values = [EnumerableWrapper]::On($this.elements)
            $sorted = [Linq.Enumerable]::OrderBy[object,object]($values,[func[object,object]]{ $args[0] },$comparer)
            $list = [Collections.Generic.List[object]]::new($sorted)
            $ixa = [IndexAdaptor]::new($list)
            $ixa.GetItemBlock.Int = { param($subject,$workingset,$index) 
                $subject[$index] }
            $this.Adaptors.ValuesSorted = $ixa
            $ixa.GetCountBlock = { param($subject,$workingset,$index) $subject.Count }
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
            $workingset.keys = $substance.occurrences.keys.GetEnumerator()
        }

        return($enumerator.ToEnumerable())
    }

    hidden [IndexableEnumerableBase]basicValuesAndOccurrencesIndexAdaptor(){
        $ixa = [IndexAdaptor]::new($this)
        $ixa.GetEnumeratorBlock = {
            param($subject,$workingset,$result)
            $enumerator = [PluggableEnumerator]::new($this)
            $enumerator.WorkingSet.vAoEnumerator = $workingset.vAoEnumerator
            $enumerator.OnMoveNextBlock = {
                param($substance,$workingset)
                $result = $WorkingSet.vAoEnumerator.MoveNext()
                return($result)
            }
            $enumerator.OnCurrentBlock = {
                param($substance,$workingset)
                $result = $WorkingSet.vAoEnumerator.Current
                return($result)
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

    hidden [IndexableEnumerableBase]get_ValuesAndOccurrences(){
        return $this.get_ValuesAndOccurrencesSorted()
    }

    hidden [IndexableEnumerableBase]get_ValuesAndOccurrencesOrdered(){
        if( $null -eq $this.Adaptors.ValuesAndOccurrencesOrdered ){
            $ixa = $this.basicValuesAndOccurrencesIndexAdaptor()
            $valuesAndOccurrences = $this.basicValuesAndOccurrences()
            $ixa.WorkingSet.vAoEnumerator = $valuesAndOccurrences.GetEnumerator()
            $ixa.WorkingSet.vAoArray = [Collections.Generic.List[object]]::new($valuesAndOccurrences)
            $this.Adaptors.ValuesAndOccurrencesOrdered = $ixa
        }
        return $this.Adaptors.ValuesAndOccurrencesOrdered
    }

    hidden [IndexableEnumerableBase]get_ValuesAndOccurrencesSorted(){
        if( $null -eq $this.Adaptors.ValuesAndOccurrencesSorted ){
            $comparer = $this.SortingComparer.ValuesAndOccurrences
            $sorted = [Linq.Enumerable]::OrderBy[object,object]($this.basicValuesAndOccurrences(),[func[object,object]]{ $args[0] },$comparer)
            #$sorted = [Linq.Enumerable]::OrderBy[object,object]($this.basicValuesAndOccurrences(),[func[object,object]]{ $args[0].Value }).ThenBy({ $args[0].Occurrence })
            $ixa = $this.basicValuesAndOccurrencesIndexAdaptor()
            $aList = [Collections.Generic.List[object]]::new($sorted)
            $ixa.WorkingSet.vAoArray = $aList
            $ixa.WorkingSet.vAoEnumerator = $aList.GetEnumerator()
            #$ixa.WorkingSet.vAoEnumerator = [PluggableEnumerator]::new($sorted)
            #$ixa.WorkingSet.vAoEnumerator = ([Collections.Generic.List[object]]::new($sorted)).GetEnumerator()
            #$ixa.WorkingSet.vAoEnumerator = $sorted.GetEnumerator()

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
        $subject = $this.SortingComparer.Values.GetSubject($value)
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
        $subject = $this.SortingComparer.Values.GetSubject($value)
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
        $aSet = [Collections.Generic.HashSet[object]]::new($this,$this.SortingComparer.Values)
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

