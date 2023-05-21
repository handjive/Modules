using namespace handjive.Collections

. "$PSScriptRoot\ConvertingFactory.ps1"

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
class Bag : IndexableEnumerableBase, IBag, ICloneable, IQuotable, IExtractable {
    static $VALUE_COMPARER_CLASS = [PluggableComparer]                # ValuesSorted用のComparer
    static $OCCURRENCES_VALUE_CLASS = [Collections.Generic.List[object]]

    hidden [Collections.ArrayList]$wpvElements
    hidden [Collections.Specialized.OrderedDictionary]$occurrences

    [ValueHolder]$ComparerHolder
    [HashTable]$Adaptors

    <#
    # Constructors
    #>
    Bag() : base(){
        $this.initialize($null)
    }
    Bag([Collections.Generic.IEnumerable[object]]$elements) : base(){
        $this.initialize($null)
        $this.AddAll($elements)
    }
    Bag([CombinedComparer]$valueComparer):base(){
        $this.initialize($valueComparer)
    }
    Bag([Collections.Generic.IEnumerable[object]]$elements,[CombinedComparer]$valueComparer):base(){
        $this.initialize($valueComparer)
        $this.AddAll($elements)
    }


    <#
    # Internal methods
    #>
    hidden initialize([CombinedComparer]$elementsComparer){
        $this.wpvElements = [Collections.ArrayList]::new()
        $this.occurrences = [Collections.Specialized.OrderedDictionary]::new()

        $thisType = $this.gettype()
        if( $null -eq $elementsComparer ){
            $elementsComparer = $thisType::VALUE_COMPARER_CLASS::new()
        }

        $this.ComparerHolder = [ValueHolder]::new($elementsComparer)
        $this.invalidateAdaptors()
    }

    <# 
    # Dependency handlers 
    #>
    hidden invalidateAdaptors(){
        $this.Adaptors = @{ ElementsOrdered=$null; 
            ValuesAndOccurrencesOrdered=$null; 
            ValuesAndElementsOrdered=$null;
        }
    }

    hidden ValuesChanged(){
        $this.Adaptors.Values.foreach{
            if( $null -ne $_ ){
                $_.InvalidateAllSubjects()
            }
        }
    }

    hidden rebuildOccurrences(){
        if( $this.wpvElements.Count -eq 0 ){
            return
        }
        
        $this.occurrences = [Collections.Specialized.OrderedDictionary]::new()
        $this.wpvElements.foreach{
            $this.addOccurrencesOf($_)
        }
    }

    hidden [object]GetSubjectUsingComparer([object]$value,[Collections.Generic.IComparer[object]]$comparer){
        if( $comparer -is [PluggableComparer] ){
            $subject = $comparer.GetSubject($value)
        }
        else{
            $subject = $value
        }

        return $subject
    }


    <#
    # Property implementations
    #>
    hidden [int]get_Count(){
        return $this.wpvElements.Count
    }

    hidden [int]get_CountOccurrences(){
        return $this.get_CountWithoutDuplicate()
    }

    hidden [int]get_CountWithoutDuplicate(){
        return $this.occurrences.Count
    }

    hidden [CombinedComparer]get_Comparer(){
        return $this.ComparerHolder.Value()
    }

    hidden [void]set_Comparer([CombinedComparer]$comparer){
        $this.invalidateAdaptors()
        $this.ComparerHolder.Value($comparer)
        $this.rebuildOccurrences()
        $this.ValuesChanged()
    }

    hidden [IndexableEnumerableBase]get_Elements(){ 
        if( $null -eq $this.Adaptors.ElementsOrdered ){
            $ixa = [IndexAdaptor]::new($this)
            $ixa.GetSubjectBlock.Enumerable = { param($adaptor,$substance,$workingset) $adaptor.Subjects.Enumerable = $substance.wpvElements }
            $ixa.GetSubjectBlock.IntIndex   = { param($adaptor,$substance,$workingset) $adaptor.Subjects.IntIndex = $substance.wpvElements }
            $ixa.GetItemBlock.IntIndex = { 
                param($adaptor,$subject,$workingset,$index) $subject[$index] }
            $ixa.GetCountBlock.IntIndex = { param($adaptor,$subject,$workingset) $subject.Count }

            $this.Adaptors.ElementsOrdered = $ixa
        }
        $this.Adaptors.ElementsOrdered.InvalidateSubjects()
        return $this.Adaptors.ElementsOrdered
    }

    hidden [Collections.Generic.IEnumerable[object]]valuesAndOccurrencesEnumerable(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.WorkingSet.keys = $this.occurrences.keys.GetEnumerator()
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            $result =$workingset.keys.MoveNext()
            return($result)
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $key = $workingset.keys.Current
            if( $null -eq $key ){
                return (@{ Value=$null; Occurrence=0 })
            }
            else{
                $subject = $key
                $result = @{ Value=$subject; Occurrence=($substance.occurrences[$subject].Count); }
                return($result)
            }
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.keys = $substance.occurrences.keys.GetEnumerator()
        }

        return($enumerator.ToEnumerable())
    }

    hidden [IndexableEnumerableBase]get_ValuesAndOccurrences(){
        if( $null -eq $this.Adaptors.ValuesAndOccurrencesOrdered ){
            $ixa = [IndexAdaptor]::new($this)
            $ixa.GetSubjectBlock.Enumerable = { 
                param($adaptor,$substance,$workingset)
                $adaptor.Subjects.Enumerable = $substance.valuesAndOccurrencesEnumerable() 
            }
            $ixa.GetSubjectBlock.IntIndex = { 
                param($adaptor,$substance,$workingset)
                $adaptor.Subjects.IntIndex = $substance.valuesAndOccurrencesEnumerable() 
            }
            $ixa.GetItemBlock.IntIndex = { 
                param($adaptor,$subject,$workingset,[int]$index) 
                $adaptor.ElementAtIndexFromEnumerable($index,$subject) 
            }
            $ixa.GetCountBlock.IntIndex = { 
                param($adaptor,$subject,$workingset) 
                $adaptor.CountFromEnumerable($subject) 
            }
            $this.Adaptors.ValuesAndOccurrencesOrdered = $ixa
        }
        $this.Adaptors.ValuesAndOccurrencesOrdered.InvalidateAllSubjects()
        return $this.Adaptors.ValuesAndOccurrencesOrdered
    }

    hidden [Collections.Generic.IEnumerable[object]]valuesAndElementsEnumerable(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.WorkingSet.keyEnumerator = $this.occurrences.keys.GetEnumerator()
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            $result = $workingset.keyEnumerator.MoveNext()
            return $result
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            $key = $workingset.keyEnumerator.Current
            if( $null -eq $key ){
                return @{ Value=$null; Elements=@(); }
            }
            return @{ Value=$key; Elements=($substance.occurrences[[object]$key]); }
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $workingset.keyEnumerator.Reset()
        }

        return($enumerator.ToEnumerable())
    }

    hidden [IndexableEnumerableBase]get_ValuesAndElements(){
        if( $null -eq $this.Adaptors.ValuesAndElementsOrdered ){
            $ixa = [IndexAdaptor]::new($this)
            $ixa.GetSubjectBlock.Enumerable = { 
                param($adaptor,$substance,$workingset)
                $adaptor.subjects.Enumerable = $substance.valuesAndElementsEnumerable() 
            }
            $ixa.GetSubjectBlock.IntIndex = { 
                param($adaptor,$substance,$workingset)
                $adaptor.subjects.IntIndex = $substance.valuesAndElementsEnumerable() 
            }
            $ixa.GetItemBlock.IntIndex = { 
                param($adaptor,$subject,$workingset,[int]$index) 
                $adaptor.ElementAtIndexFromEnumerable($index,$subject) 
            }
            $ixa.GetCountBlock.IntIndex = { 
                param($adaptor,$subject,$workingset) 
                $adaptor.CountFromEnumerable($subject) 
            }
            $this.Adaptors.ValuesAndElementsOrdered = $ixa
        }
        $this.Adaptors.ValuesAndElementsOrdered.InvalidateAllSubjects()
        return $this.Adaptors.ValuesAndElementsOrdered
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

    [object[]]OccurrenceElementsOf([object]$value){
        return($this.occurrences[[object]$value])
    }


    <#
    # Methods: Add/Remove/Clear
    #>
    hidden addOccurrencesOf([object]$value){
        $subject = $this.GetSubjectUsingComparer($value,$this.Comparer)
        if( $null -eq ($this.occurrences[[object]$subject]) ){
            $occurs = [Bag]::OCCURRENCES_VALUE_CLASS::new()
            $occurs.Add($value)
            $this.occurrences.Add($subject,$occurs)
        }
        else{
            ($this.occurrences[[object]$subject]).Add($value)
        }
    }
    hidden removeOccurrencesOf([object]$value){
        $subject = $this.GetSubjectUsingComparer($value,$this.Comparer)
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
        $this.wpvElements.Add($elem)
        $this.addOccurrencesOf($elem)
        $this.ValuesChanged()
    }
    AddAll([Collections.Generic.IEnumerable[object]]$elements){
        $elements.foreach{
            $this.Add([object]$_)
        }
        $this.invalidateAdaptors()
    }
    AddAll([Collections.IEnumerable]$elements){
        $elements.foreach{
            $this.Add([object]$_)
        }
        $this.invalidateAdaptors()
    }

    Remove([object]$elem){
        $this.removeOccurrencesOf($elem)
        $this.wpvElements.Remove($elem)
        $this.ValuesChanged()
    }
    RemoveAll([Collections.Generic.IEnumerable[object]]$elements){
        $elements.foreach{
            $this.Remove($_)
        }
    }
    RemoveAll([Collections.IEnumerable]$elements){
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
    PurgeAll([Collections.IEnumerable]$elements){
        $elements.foreach{
            $this.Purge($_)
        }
    }

    Clear(){
        $this.wpvElements.Clear()
        $this.occurrences.Clear()
    }

    [object]Clone(){
        $newOne = $this.gettype()::new()
        $newOne.wpvElements = $this.wpvElements.Clone()
        $newOne.Comparer = $this.Comparer
        $newOne.rebuildOccurrences()
        $newOne.ValuesChanged()

        return $newOne
    }

    <#
    # Subclass repsponsibilities about: IndexableEnumerableBase 
    #>
    hidden [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return [PluggableEnumerator]::InstantWrapOn($this.wpvElements)
    }

    hidden [object]PSGetItem_IntIndex([int]$index){
        return $this.wpvElements[$index]
    }

    hidden PSSetItem_IntIndex([int]$index,[object]$value){
        $old = $this.wpvElements[$index]
        $this.Remove($old)
        $this.wpvElements[$index] = $value
        $this.addOccurrencesOf($value)
    }

    <#
    # Methods: Converting
    #>
    <#obsolete![object]To([Type]$aType){
        $aFactory = ($this.gettype())::Factories[$aType]
        return $aFactory::new($this)
    }#>

    [object]QuoteTo([Type]$aType){
        $aFactory = $this.gettype()::QUOTERS[$aType]
        return $aFactory
    }

    [object]ExtractTo([Type]$aType){
        $aFactory = $this.gettype()::EXTRACTORS[$aType]
        return $aFactory
    }
}

<#
[BagToEnumerableFactory]::InstallOn([Bag])
[BagToBagFactory]::InstallOn([Bag])
[BagToSetFactory]::InstallOn([Bag])
#>
