using namespace handjive.Collections

. "$PSScriptRoot\ConvertingFactory.ps1"

class SortingComparerHolder : handjive.Collections.ISortingComparerHolder{
    hidden [Bag2]$substance
    hidden [ValueHolder]$wpvElements
    hidden [ValueHolder]$wpvValuesAndOccurrences

    SortingComparerHolder([Bag2]$substance){
        $this.substance = $substance

        $this.wpvElements = [ValueHolder]::new()
        $this.wpvElements.AddValueChangedListener($substance,{ param($substance,$args1,$args2) $substance.OnElementsComparerChanged() } )

        $this.wpvValuesAndOccurrences = [ValueHolder]::new()
        $this.wpvValuesAndOccurrences.AddValueChangedListener($substance,{ param($substance,$args1,$args2) $substance.OnValuesAndOccurrencesComparerChanged() } )
    }

    [CombinedComparer]get_Elements(){
        return $this.wpvElements.Value()
    }
    set_Elements([CombinedComparer]$comparer){
        $this.wpvElements.Value($comparer)
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
class Bag2 : handjive.Collections.IndexableEnumerableBase, handjive.Collections.IBag2 ,ICloneable {
    static [Collections.Generic.Dictionary[Type,object]]$Factories=[Collections.Generic.Dictionary[Type,object]]::new()
    static InstallFactory([Type]$aType,[Object]$factoryClass){
        $factoryDictionary = [Bag2]::Factories
        if( $null -eq $factoryDictionary[$aType] ){
            $factoryDictionary.Add($aType,$factoryClass)
        }
        else{
            [String]::Format('{0}: Factory class for a type [{1}], already installed.',[Bag2].Name,$aType.Name) | write-warning 
        }
            
    }
    static $valueComparerClass = [PluggableComparer]                # ValuesSorted用のComparer

    hidden [Collections.ArrayList]$wpvElements
    hidden [Collections.Specialized.OrderedDictionary]$occurrences

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
    hidden initialize([CombinedComparer]$elementsComparer,[CombinedComparer]$vAoComparer){
        $this.wpvElements = [Collections.ArrayList]::new()
        $this.occurrences = [Collections.Specialized.OrderedDictionary]::new()

        $thisType = $this.gettype()
        if( $null -eq $elementsComparer ){
            $elementsComparer = $thisType::valueComparerClass::new()
        }

        $this.SortingComparer = [SortingComparerHolder]::new($this)
        $this.SortingComparer.Elements = $elementsComparer
        $this.SortingComparer.ValuesAndOccurrences = $vAoComparer
        
        if( $elementsComparer -is [PluggableComparer] ){
            $elementsComparer.CompareBlockHolder.AddValueChangedListener($this,{ param($listener,$args1,$args2) $listener.ValuesChanged() })
        }
        if( $vAoComparer -is [PluggableComparer] ){
            $vAoComparer.CompareBlockHolder.AddValueChangedListener($this,{ param($listener,$args1,$args2) $listener.ValuesChanged() })
        }
    
        $this.ValuesChanged()
    }

    <# 
    # Dependency handlers 
    #>
    hidden OnElementsComparerChanged(){
        $this.rebuildOccurrences()
        $this.ValuesChanged()
    }
    
    hidden OnValuesAndOccurrencesComparerChanged(){
        #write-host 'OnValuesAndOccurrencesComparerChanged()'
    }

    hidden ValuesChanged(){
        if( $null -eq $this.Adaptors ){
            $this.Adaptors = @{ ElementsOrdered=$null; 
                                ValuesAndOccurrencesOrdered=$null; 
                                ValuesAndElementsOrdered=$null;
                            }
        }
        else{
            $this.Adaptors.ValuesAndElementsOrdered=$null
        }
        # = @{ ValuesSorted=$null; ValuesOrdered=$null; ValuesAndOccurrencesSorted=$null; ValuesAndOccurrencesOrdered=$null; }
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

    hidden [IndexableEnumerableBase]get_Elements(){ 
        if( $null -eq $this.Adaptors.ElementsOrdered ){
            $ixa = [IndexAdaptor]::new($this)
            $ixa.GetSubjectBlock.Enumerable = { param($adaptor,$substance,$workingset) $substance.wpvElements }
            $ixa.GetSubjectBlock.IntIndex   = { param($adaptor,$substance,$workingset) $substance.wpvElements }
            $ixa.GetItemBlock.IntIndex = { 
                param($adaptor,$subject,$workingset,$index) $subject[$index] }
            $ixa.GetCountBlock.IntIndex = { param($adaptor,$subject,$workingset) $subject.Count }

            $this.Adaptors.ElementsOrdered = $ixa
        }
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
                $adaptor.subjects.Enumerable = $substance.valuesAndOccurrencesEnumerable() 
            }
            $ixa.GetSubjectBlock.IntIndex = { 
                param($adaptor,$substance,$workingset)
                $adaptor.subjects.IntIndex = $substance.valuesAndOccurrencesEnumerable() 
            }
            $ixa.GetItemBlock.IntIndex = { 
                param($adaptor,$subject,$workingset,[int]$index) 
                $adaptor.ElementAtFromEnumerable($index,$subject) 
            }
            $ixa.GetCountBlock.IntIndex = { 
                param($adaptor,$subject,$workingset) 
                $adaptor.CountFromEnumerable($subject) 
            }
            $this.Adaptors.ValuesAndOccurrencesOrdered = $ixa
        }
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
                $adaptor.ElementAtFromEnumerable($index,$subject) 
            }
            $ixa.GetCountBlock.IntIndex = { 
                param($adaptor,$subject,$workingset) 
                $adaptor.CountFromEnumerable($subject) 
            }
            $this.Adaptors.ValuesAndElementsOrdered = $ixa
        }
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
        $subject = $this.SortingComparer.Elements.GetSubject($value)
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
        $subject = $this.SortingComparer.Elements.GetSubject($value)
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
    }
    AddAll([Collections.IEnumerable]$elements){
        $elements.foreach{
            $this.Add([object]$_)
        }
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
        $newOne.rebuildOccurrences()
        return $newOne
    }


    <#
    # Methods: Converting
    #>
    [object]To([Type]$aType){
        $aFactory = ($this.gettype())::Factories[$aType]
        return $aFactory::new($this)
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
}

[BagToBagFactory]::InstallOn([Bag2])
[BagToSetFactory]::InstallOn([Bag2])
