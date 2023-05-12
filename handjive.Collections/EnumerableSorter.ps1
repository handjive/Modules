using namespace handjive.Collections

class SortCondition{
    static [string]$CONDITION_FORMAT = '([adAD])(:)(.+)' 

    static [SortCondition]FromString([string]$condString){
        if( $condString -match [SortCondition]::CONDITION_FORMAT ){
            #[ScriptBlock]::Create([String]::Format('return($args[0].{0})',$this.Aspect))

            $direct = if( 'A','a' -contains $Matches[1][0] ){ 'Ascending' } else{ 'Descending' }
            $cond = $Matches[3].Trim()
            if( $cond[0] -eq '{' ){
                $sb = [ScriptBlock]::Create($cond)
                $result = [SortCondition]::new((&$sb),$direct) # 外側の{}外しに一度評価
            }
            else{
                $result = [SortCondition]::new($cond,$direct)
            }
            return $result
        }
        else{
            throw ([String]::Format('{0}: Invalid Condition format "{1}"',[SortCondition].Name,$condString))
        }
    }

    static [SortCondition]Ascending([object]$condition){
        $newOne = [SortCondition]::new($condition,'Ascending')
        return $newOne
    }
    static [SortCondition]Descending([object]$condition){
        $newOne = [SortCondition]::new($condition,'Descending')
        return $newOne
    }

    [object]$condition
    [String]$direction

    SortCondition([object]$condition,[String]$direction){
        if( 'Ascending','Descending' -notcontains $direction ){
            throw ([String]::Format('{0}: Invalid sort direction "{1}" specified.',$this.gettype().Name,$direction))
        }
        $this.condition = $condition
        $this.direction = $direction
    }

    [ScriptBlock]ToKeySelector(){
        if( $this.Condition -is [String] ){
            return ([AspectComparer]::new($this.Condition).GetSubjectBlock)
        }
        else{
            return $this.Condition
        }
    }
}

<#
# Linq.Enumerable.OrderBy,ThenByを使用したソーター
#>
class EnumerableSorter : handjive.IWrapper {
    hidden [object]$wpvSubstance
    hidden [System.Linq.IOrderedEnumerable[object]]$sorted
    
    [Collections.Generic.IEnumerable[object]]$Subject
    [Collections.Generic.IComparer[object]]$Comparer
    [ScriptBlock]$GetSubjectBlock = { $args[0] }    # Substance -eq Subject

    EnumerableSorter([object]$substance){
        $this.wpvSubstance = $substance
    }

    <# Property accessors #>
    hidden [object]get_Substance(){
        return $this.wpvSubstance
    }
    hidden set_Substance([object]$substance){
        $this.wpvSubstance = $substance
    }

    <# Private methods #>
    hidden [Collections.Generic.IEnumerable[object]]SubjectUsingSubstance(){
        $this.Subject = &$this.GetSubjectBlock $this.Substance
        return $this.Subject
    }

    hidden [System.Linq.IOrderedEnumerable[object]]primarySort([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector,[string]$direction){
        if( $direction -eq 'Ascending' ){
            $result = [Linq.Enumerable]::OrderBy[object,object]($enumerable,[func[object,object]]$keySelector)
        }
        else{
            $result = [Linq.Enumerable]::OrderByDescending[object,object]($enumerable,[func[object,object]]$keySelector)
        }
        return $result

    }

    hidden [System.Linq.IOrderedEnumerable[object]]secondarySort([System.Linq.IOrderedEnumerable[object]]$enumerable,[ScriptBlock]$keySelector,[string]$direction){
        if( $direction -eq 'Ascending' ){
            $result = [Linq.Enumerable]::ThenBy[object,object]($enumerable,[func[object,object]]$keySelector)
        }
        else{
            $result = [Linq.Enumerable]::ThenByDescending[object,object]($enumerable,[func[object,object]]$keySelector)
        }
        return $result
    }

    hidden [Collections.Generic.IComparer[object]]comparerForDirection([String]$direction){
        $adjusted = &$this.ComparerAdjustBlock $direction $this.Comparer
        return $adjusted
    }

    <# Public Methods#>

    <# 
    # ソート対象とソートオーダーをSortConditionで指定するソート
    #
    # ex.
    # $sorted = $sorter.Sort(([SortCondition]::Descending('a'),[SortCondition]::Ascending({ $args[0].b }),[SortCondition]::Descending('c')))
    #>
    [System.Linq.IOrderedEnumerable[object]]Sort([SortCondition[]]$condition){
        $conditionList = [Collections.Generic.List[SortCondition]]::new($condition)
        $aCondition = $conditionList[0]
        $conditionList.RemoveAt(0)
        $this.sorted = $this.primarySort($this.SubjectUsingSubstance(),$aCondition.ToKeySelector(),$aCondition.direction)

        $conditionList.foreach{
            $aCondition = $args[0]
            $this.sorted = $this.secondarySort($this.sorted,$aCondition.ToKeySelector(),$aCondition.direction)
        }

        return $this.sorted
    }

    <#
    # 'a|d:FieldName','a|d:{...}'形式でソートオーダーが指定できるソート
    #
    # ex.
    # $sorted2 = $sorter.Sort(('a:a','a:{ $args[0].b }','d:c'))
    #>
    [System.Linq.IOrderedEnumerable[object]]Sort([string[]]$condition){
        $scArray = $condition | StreamAdaptor -Inject ([Collections.ArrayList]::new()) -into { 
                                                    param([Collections.ArrayList]$result,$elem) 
                                                    $result.Add([SortCondition]::FromString($elem))|out-null
                                                    $result }
        return $this.Sort([SortCondition[]]$scArray)
    }

}