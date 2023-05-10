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
        $comparer.SetDefaultAscendingByValue()
        return $comparer
    }
    static [BagValuesAndOccurrencesComparer]DefaultDescending(){
        $comparer = [BagValuesAndOccurrencesComparer]::new()
        $comparer.SetDefaultDescendingByValue()
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

class ConvertingFactory{
    static [Type]$ConformanceType = $null
    static InstallOn([Type]$type){
        throw "Subclass responsibility"
    }

    [Bag2]$substance

    ConvertingFactory([Bag2]$substance){
        $this.substance = $substance
    }
}

class BagToSetFactory : ConvertingFactory{
    static [Type]$ConformanceType = [Collections.Generic.HashSet[object]]
    static InstallOn([Type]$type){
        $type::InstallFactory([BagToSetFactory]::ConformanceType,[BagToSetFactory])
    }

    BagToSetFactory([Bag2]$substance) : base($substance){}

    hidden [Collections.Generic.HashSet[object]]createNewInstance([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = [Collections.Generic.HashSet[object]]::new($enumerable,$this.substance.SortingComparer.Elements)
        return $newOne
    }

    [Collections.Generic.HashSet[object]]WithAll(){
        $aSet = $this.createNewInstance($this.substance)
        return $aSet
    }

    [Collections.Generic.HashSet[object]]WithSelectionBy([ScriptBlock]$nominator){
        $selection = $this.substance.Where($nominator)
        $aSet = $this.createNewInstance($selection)
        return $aSet
    }

    [Collections.Generic.HashSet[object]]SplitSelectionBy([ScriptBlock]$nominator){
        $aSet = $this.WithSelectionBy($nominator)
        $this.substance.RemoveAll($aSet)
        return $aSet
    }
}

class BagToBagFactory : ConvertingFactory{
    static [Type]$ConformanceType = [Bag2]
    static InstallOn([Type]$type){
        $type::InstallFactory([BagToBagFactory]::ConformanceType,[BagToBagFactory])
    }

    BagToBagFactory([Bag2]$substance) : base($substance){}

    hidden [Bag2]createNewInstance([Collections.Generic.IEnumerable[object]]$enumerable){
        return ([Bag2]::new($enumerable,$this.substance.SortingComparer.Elements))
    }
    hidden [Bag2]createNewInstance(){
        return ([Bag2]::new($this.substance.SortingComparer.Elements))
    }

    [Bag2]WithAll(){
        return $this.substance.Clone()
    }

    [Bag2]WithSelectionBy([ScriptBlock]$nominator){
        $selection = $this.substance.Where($nominator)
        $newOne = $this.CreateNewInstance($selection)
        return $newOne
    }

    [Bag2]SplitSelectionBy([ScriptBlock]$nominator){
        $newOne = $this.WithSelectionBy($nominator)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }

    [Bag2]WithIntersectBy([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){
        $selection = [Linq.Enumerable]::IntersectBy[object,object]($this.substance.ValuesAndElements,$enumerable,$keySelector)
        $newOne = $this.createNewInstance()
        $selection.foreach{
            $newOne.AddAll($_.Elements)
        }
        return $newOne
    }
    [Bag2]WithIntersect([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = $this.WithIntersectBy($enumerable,{ $args[0].Value })
        return $newOne
    }

    [Bag2]SplitIntersectBy([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){
        $newOne = $this.WithIntersectBy($enumerable,$keySelector)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }

    [Bag2]SplitIntersect([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = $this.WithIntersect($enumerable)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }

    [Bag2]WithExceptBy([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){
        $selection = [Linq.Enumerable]::ExceptBy[object,object]($this.substance.ValuesAndElements,$enumerable,$keySelector)
        $newOne = $this.createNewInstance()
        $selection.foreach{
            $newOne.AddAll($_.Elements)
        }
        return $newOne
    }

    [Bag2]WithExcept([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = $this.WithExceptBy($enumerable,{ $args[0].Value })
        return $newOne
    }

    [Bag2]SplitExcept([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = $this.WithExcept($enumerable)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }
    [Bag2]SplitExceptBy([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){
        $newOne = $this.WithExceptBy($enumerable,$keySelector)
        $this.substance.RemoveAll($newOne)
        return $newOne
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
    static $vAoComparerClass = [BagValuesAndOccurrencesComparer]    # ValuesAndOccurrencesSorted用のComparer
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
        if( $null -eq $vAoComparer ){
            $vAoComparer = $thisType::vAoComparerClass::new()
        }

        #$vAoComparer.GetSubjectBlock = $valueComparer.GetSubjectBlock
        #SuppressDependentsDo
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
            $this.Adaptors = @{ ElementsSorted=$null; ElementsOrdered=$null; 
                                ValuesAndOccurrencesSorted=$null; ValuesAndOccurrencesOrdered=$null; 
                                ValuesAndElementsSorted=$null; ValuesAndElementsOrdered=$null;
                            }
        }
        else{
            $this.Adaptors.ElementsSorted = $null
            $this.Adaptors.ValuesAndOccurrencesSorted=$null
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
        return $this.get_ElementsOrdered()
    }

    hidden [IndexableEnumerableBase]get_ElementsOrdered(){ 
        if( $null -eq $this.Adaptors.ElementsOrdered ){
            $ixa = [IndexAdaptor]::new([EnumerableWrapper]::On($this.wpvElements))
            $ixa.GetEnumeratorBlock = { param($subject,$workingset,$results) 
                $results.Value = [PluggableEnumerator]::InstantWrapOn($subject.GetEnumerator()) }
            $ixa.GetItemBlock.Int = { param($subject,$workingset,$index) 
                $subject.Substance[$index] }
            $ixa.GetCountBlock = { param($subject,$workingset,$index) $subject.Substance.Count }
            $this.Adaptors.ElementsOrdered = $ixa
        }
        return $this.Adaptors.ElementsOrdered
    }

    hidden [IndexableEnumerableBase]get_ElementsSorted(){
        if( $null -eq $this.Adaptors.ElementsSorted ){
            #$keySelector = $this.SortingComparer.Values.GetSubjectBlock
            $comparer = $this.SortingComparer.Elements
            $values = [EnumerableWrapper]::On($this.wpvElements)
            $sorted = [Linq.Enumerable]::OrderBy[object,object]($values,[func[object,object]]{ $args[0] },$comparer)
            $list = [Collections.Generic.List[object]]::new($sorted)
            $ixa = [IndexAdaptor]::new($list)
            $ixa.GetItemBlock.Int = { param($subject,$workingset,$index) $subject[$index] }
            $ixa.GetCountBlock = { param($subject,$workingset,$index) $subject.Count }
            $this.Adaptors.ElementsSorted = $ixa
        }
        return $this.Adaptors.ElementsSorted
    }

    hidden [Collections.Generic.IEnumerable[object]]basicValuesAndOccurrences(){
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
        return $this.get_ValuesAndOccurrencesSorted()
    }

    hidden [IndexableEnumerableBase]get_ValuesAndOccurrencesOrdered(){
        if( $null -eq $this.Adaptors.ValuesAndOccurrencesOrdered ){
            $ordered = $this.basicValuesAndOccurrences()
            $aList = [Collections.Generic.List[object]]::new($ordered)
            $ixa = [IndexAdaptor]::new($aList)
            $ixa.GetItemBlock.Int = { param($subject,$workingset,[int]$index) $subject[$index] }
            $ixa.GetCountBlock = { param($subject,$workingset) $subject.Count }
            $this.Adaptors.ValuesAndOccurrencesOrdered = $ixa
        }
        return $this.Adaptors.ValuesAndOccurrencesOrdered
    }

    hidden [IndexableEnumerableBase]get_ValuesAndOccurrencesSorted(){
        if( $null -eq $this.Adaptors.ValuesAndOccurrencesSorted ){
            $comparer = $this.SortingComparer.ValuesAndOccurrences
            $sorted = [Linq.Enumerable]::OrderBy[object,object]($this.basicValuesAndOccurrences(),[func[object,object]]{ $args[0] },$comparer)
            $aList = [Collections.Generic.List[object]]::new($sorted)
            $ixa = [IndexAdaptor]::new($aList)
            $ixa.GetItemBlock.Int = { param($subject,$workingset,[int]$index) $subject[$index] }
            $ixa.GetCountBlock = { param($subject,$workingset) $subject.Count }
            $this.Adaptors.ValuesAndOccurrencesSorted = $ixa
        }
        return $this.Adaptors.ValuesAndOccurrencesSorted
    }

    hidden [PluggableEnumerator]basicValuesAndElements(){
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

        return($enumerator)
    }

    hidden [IndexableEnumerableBase]get_ValuesAndElements(){
        return $this.get_ValuesAndElementsOrdered()
    }

    hidden [IndexableEnumerableBase]get_ValuesAndElementsOrdered(){
        if( $null -eq $this.Adaptors.ValuesAndElementsOrdered ){
            $ixa = [IndexAdaptor]::new($this.basicValuesAndElements().ToEnumerable())
            $aList = [Collections.Generic.List[object]]::new($this.basicValuesAndElements().ToEnumerable())
            $ixa.WorkingSet.elemArray = $aList
            $ixa.GetItemBlock.Int = { param($subject,$workingset,[int]$index) 
                $workingset.elemArray[[int]$index] }
            $ixa.GetCountBlock = { param($subject,$workingset) $subject.Count }
            $this.Adaptors.ValuesAndElementsOrdered = $ixa
        }
        return $this.Adaptors.ValuesAndElementsOrdered
    }

    hidden [IndexableEnumerableBase]get_ValuesAndElementsSorted(){
        if( $null -eq $this.Adaptors.ValuesAndElementsSorted ){
            $comparer = $this.SortingComparer.ValuesAndOccurrences
            $sorted = [Linq.Enumerable]::OrderBy[object,object]($this.basicValuesAndElements().ToEnumerable(),[func[object,object]]{ $args[0] },$comparer)
            $aList = [Collections.Generic.List[object]]::new($sorted)
            $ixa = [IndexAdaptor]::new($aList)
            
            $ixa.GetItemBlock.Int = { param($subject,$workingset,[int]$index) $subject[$index] }
            $ixa.GetCountBlock = { param($subject,$workingset) $subject.Count }
            $this.Adaptors.ValuesAndElementsSorted = $ixa
        }
        return $this.Adaptors.ValuesAndElementsSorted
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
    <#[Collections.Generic.HashSet[object]]ToSet(){
        $aSet = [Collections.Generic.HashSet[object]]::new($this,$this.SortingComparer.Values)
        return $aSet
    }#>

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
