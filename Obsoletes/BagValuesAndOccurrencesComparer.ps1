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
