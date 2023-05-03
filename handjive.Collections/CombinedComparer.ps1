using module handjive.ValueHolder
using module handjive.ChainScript

using namespace handjive.Collections

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

class PluggableComparer : CombinedComparer,IPluggableComparer{
    hidden static [ScriptBlock]$DefaultAscendingBlock  = { param($left,$right) if( $left -eq $right ){ return 0 } elseif( $left -lt $right ){ return -1 } else {return 1 } }
    hidden static [ScriptBlock]$DefaultDescendingBlock = { param($left,$right) if( $left -eq $right ){ return 0 } elseif( $left -lt $right ){ return 1 } else {return -1 } }

    static [PluggableComparer]DefaultAscending(){
        $newOne = [PluggableComparer]::new()
        $newOne.SetDefaultAscending()
        return $newOne
    }
    static [PluggableComparer]DefaultDescending(){
        $newOne = [PluggableComparer]::new()
        $newOne.SetDefaultDescending()
        return $newOne
    }
    static [PluggableComparer]GetSubjectBlock([ScriptBlock]$getSubjectBlock){
        $newOne = [PluggableComparer]::new()
        $newOne.SetDefaultAscending()
        $newOne.GetSubjectBlock = $getSubjectBlock
        return $newOne
    }

    [ValueHolder]$CompareBlockHolder
    [ScriptBlock]$GetSubjectBlock = { return $args[0] }
    
    PluggableComparer() : base(){
        $this.initialize()
        $this.SetDefaultAscending()
    }
    PluggableComparer([ScriptBlock]$getSubjectBlock) : base(){
        $this.initialize()
        $this.SetDefaultAscending()
        $this.GetSubjectBlockHolder.Subject = $getSubjectBlock
    }

    PluggableComparer([ScriptBlock]$comparerBlock,[ScriptBlock]$getSubjectBlock) : base(){
        $this.Initialzie()
        $this.SetDefaultAscending()
        $this.GetSubjectBlockHolder.Subject = $getSubjectBlock
    }

    hidden initialize(){
        $this.CompareBlockHolder = [ValueHolder]::new()
    }
    
    hidden [object]get_CompareBlock(){
        return $this.CompareBlockHolder.Value()
    }
    
    hidden set_CompareBlock([object]$aBlock){
        $this.CompareBlockHolder.Value($aBlock)
    }

    SetDefaultAscending(){
        $this.CompareBlock = ($this.GetType())::DefaultAscendingBlock
    }
    SetDefaultDescending(){
        $this.CompareBlock = ($this.GetType())::DefaultDescendingBlock
    }

    hidden [object]GetSubject([object]$anObject){
        return &$this.GetSubjectBlock $anObject
    }

    hidden [int]PSCompare([object]$left,[object]$right){
        $leftSubject = $this.GetSubject($left)
        $rightSubject = $this.GetSubject($right)
        if( ($null -eq $leftSubject) -and ($null -eq $rightSubject )){
            return 0
        }
        elseif( $null -eq $leftSubject ){
            return -1
        }
        elseif( $null -eq $rightSubject ){
            return 1
        }
        else{
            return((&$this.CompareBlock $leftSubject $rightSubject))
        }
    }

    hidden [bool]PSEquals([object]$left,[object]$right){
        $leftSubject = $this.GetSubject($left)
        $rightSubject = $this.GetSubject($right)        
        if( ($null -eq $leftSubject) -and ($null -eq $rightSubject )){
            return $true
        }
        elseif( ($null -eq $leftSubject) -or ($null -eq $rightSubject) ){
            return $false
        }
        else{
            $result = $leftSubject -eq $rightSubject
            return($result)
        }
    }
    
    hidden [int]PSGetHashCode([object]$obj){
        $aSubject = $this.GetSubject($obj)
        if( $null -eq $aSubject ){
            return 0
        }
        else{
            $hash = $aSubject.GetHashCode()
            return($hash);
        }
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
    AspectComparer([string]$aspect) : base(){
        $this.Aspect = $aspect
        $this.GetSubjectBlock = [ScriptBlock]::Create([String]::Format('return($args[0].{0})',$this.Aspect))
        $this.SetDefaultAscending()
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
