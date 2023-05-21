using namespace handjive.Collections

class QuoterInstaller : IQuoterInstaller {
    [Type]$wpvQuoter
    [Type]$wpvQuoteTo

    QuoterInstaller([Type]$quoteTo,[Type]$quoter){
        $this.QUoteTo = $quoteTo
        $this.Quoter = $quoter
    }

    [System.Type]get_Quoter()
    {
        return $this.wpvQuoter
    }
    [System.Type]get_QuoteTo(){
        return $this.wpvQuoteTo
    }

    <#InstallOn([IQuotable]$target){
        $dict = $target.gettype()::QUOTERS
        if( $null -eq $dict ){
            $target.gettype()::QUOTERS = [Collections.Generic.Dictionary[Type,object]]::new()
        }
        if( $null -eq $dict[$this.substanece] ){
            $dict.Add($this.substance::ConformanceType,$this.substance)
        }
    }#>
}

class ExtractorInstaller : IExtractorInstaller {
    [Type]$wpvExtractor
    [Type]$wpvExtractorTo

    QuoterInstaller([Type]$quoteTo,[Type]$quoter){
        $this.ExtractorTo = $quoteTo
        $this.Extractor = $quoter
    }

    [System.Type]get_Extractor()
    {
        return $this.wpvExtractor
    }
    [System.Type]get_ExtractTo(){
        return $this.wpvExtractorTo
    }
}

class QuotingFactory : IQuoter{
    static [Type]$ConformanceType = $null
    static [IQuoterInstaller]Installer(){
        throw "Subclass responsibility"
        return $null
    }

    [object]$substance

    QuotingFactory([object]$substance){
        $this.substance = $substance
    }
}

class ExtractingFactory : IExtractor{
    static [Type]$ConformanceType = $null
    static [IExtractorInstaller]Installer(){
        throw "Subclass responsibility"
        return $null
    }

    [object]$substance

    ExtractingFactory([object]$substance){
        $this.substance = $substance
    }
}


class BagToSomeConvertingFactory {
    static [Type]$PASSTHRU_FACTORY_TYPE = [BagThruFactory]
    [Bag]$substance

    BagToSomeConvertingFactory([Bag]$substance){
        $this.substance = $substance
    }
    
    hidden [object]ThrowSubclassResponsibility(){
        throw([String]::Format('{0}: Subclass responsibility.',$this.name))
        return $null
    }

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        return $result
    }

    <# Sublass responsibilities #>

    [Collections.Generic.IEnumerable[object]]WithSelection([ScriptBlock]$nominator){ return $this.ThrowSubclassResponsibility() }

    [Collections.Generic.IEnumerable[object]]WithIntersect([Bag]$bag2){ return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithIntersect([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    
    [Collections.Generic.IEnumerable[object]]WithExcept([Bag]$bag2){ return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithExcept([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    
    [Collections.Generic.IEnumerable[object]]WithUnion([Bag]$bag2){ return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable,[Collections.Generic.IEqualityComparer[object]]$comparer){ return $this.ThrowSubclassResponsibility() }

    [Collections.Generic.IEnumerable[object]]WithMaxBy([Type]$aType,[ScriptBlock]$keySelector){ return return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithMaxBy([Type]$aType,[string]$aspectName){ return $this.ThrowSubclassResponsibility() }

    [Collections.Generic.IEnumerable[object]]WithMinBy([Type]$aType,[ScriptBlock]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [Collections.Generic.IEnumerable[object]]WithMinBy([Type]$aType,[string]$aspectName){ return $this.ThrowSubclassResponsibility() }

    <# May works as is... #>
    [Collections.Generic.IEnumerable[object]]WithMaxBy([ScriptBlock]$keySelector){ return ($this.WithMaxBy([object],$keySelector))}
    [Collections.Generic.IEnumerable[object]]WithMaxBy([string]$aspectName){ return ($this.WithMaxBy([object],$aspectName)) }

    [Collections.Generic.IEnumerable[object]]WithMinBy([ScriptBlock]$keySelector){ return ($this.WithMinBy([object],$keySelector))}
    [Collections.Generic.IEnumerable[object]]WithMinBy([string]$aspectName){ return ($this.WithMinBy([object],$aspectName)) }
}

class BagThruFactory : BagToSomeConvertingFactory{
    BagThruFactory([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]WithSelectionBy([ScriptBlock]$nominator){ return $this.substance }
    
    [Collections.Generic.IEnumerable[object]]WithIntersect([Bag]$bag2){ return $this.substance }
    [Collections.Generic.IEnumerable[object]]WithIntersect([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){ return $this.substance }
    [Collections.Generic.IEnumerable[object]]WithIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.substance }
    
    [Collections.Generic.IEnumerable[object]]WithExcept([Bag]$bag2){ return $this.substance }
    [Collections.Generic.IEnumerable[object]]WithExcept([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){ return $this.substance }
    [Collections.Generic.IEnumerable[object]]WithExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.substance }
    
    [Collections.Generic.IEnumerable[object]]WithUnion([Bag]$bag2){ return $this.substance}
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.substance }
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable,[Collections.Generic.IEqualityComparer[object]]$comparer){ return $this.substance }

    [Collections.Generic.IEnumerable[object]]WithMinBy([ScriptBlock]$keySelector){ return $this.substance }
    [Collections.Generic.IEnumerable[object]]WithMinBy([string]$aspectName){ return $this.substance }
}

class BagToEnumerableFactory : BagToSomeConvertingFactory{
    BagToEnumerableFactory([Bag]$substance) : base($substance){}
 
    [Collections.Generic.IEnumerable[object]]WithSelectionBy([ScriptBlock]$nominator){
        $aClone = $this.substance.Clone()
        $selection = [Linq.Enumerable]::Where[object]($aClone,[func[object,bool]]$nominator)
        return $this.AdjustResult($selection)
    }

    [Collections.Generic.IEnumerable[object]]WithIntersect([Bag]$aBag){
        $keys = [Linq.Enumerable]::Select[object,object]($aBag.ValuesAndElements,[func[object,object]]{ $args[0].Value })
        $aClone = $this.Substance.Clone()
        $aClone.Comparer = $aBag.Comparer
        $intersect = [Linq.Enumerable]::IntersectBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $intersect.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [Collections.Generic.IEnumerable[object]]WithIntersect([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aClone = $this.substance.Clone()
        $intersect = [Linq.Enumerable]::IntersectBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $intersect.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [Collections.Generic.IEnumerable[object]]WithIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        return $this.WithIntersect($enumerable,{ $args[0] })
    }

    [Collections.Generic.IEnumerable[object]]WithExcept([Bag]$aBag){
        $keys = [Linq.Enumerable]::Select[object,object]($aBag.ValuesAndOccurrences,[func[object,object]]{ $args[0].Value })
        $aClone = $this.substance.Clone()
        $aClone.Comparer = $aBag.Comparer
        $except = [Linq.Enumerable]::ExceptBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $except.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [Collections.Generic.IEnumerable[object]]WithExcept([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aClone = $this.substance.Clone()
        $except = [Linq.Enumerable]::ExceptBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $except.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [Collections.Generic.IEnumerable[object]]WithExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        return $this.WithExcept($enumerable,{ $args[0] })
    }

    [object]WithMaxBy([Type]$aType,[ScriptBlock]$keySelector){
        $execFrame = '[Linq.Enumerable]::MaxBy[object,{0}]($args[0],[func[object,{0}]]$args[1])'
        $executer = [ScriptBlock]::create([String]::Format($execFrame,$aType))
        $aClone = $this.substance.Clone()
        $result = &$executer $aClone $keySelector
        return $this.AdjustResult(@($result))
    }
    [object]WithMaxBy([Type]$aType,[string]$aspectName){ 
        return $this.WithMaxBy($aType,[AspectComparer]::new($aspectName).GetSubjectBlock)
    }

    [object]WithMinBy([Type]$aType,[ScriptBlock]$keySelector){
        $execFrame = '[Linq.Enumerable]::MinBy[object,{0}]($args[0],[func[object,{0}]]$args[1])'
        $executer = [ScriptBlock]::create([String]::Format($execFrame,$aType))
        $aClone = $this.substance.Clone()
        $result = &$executer $aClone $keySelector
        return $this.AdjustResult(@($result))
    }
    [object]WithMinBy([Type]$aType,[string]$aspectName){ 
        return $this.WithMinBy($aType,[AspectComparer]::new($aspectName).GetSubjectBlock)
    }

}

class BagToEnumerableQuoter : BagToEnumerableFactory, IQuoter{
    static [IQuoterInstaller]Installer(){
        return [QuoterInstaller]::new([Collections.Generic.IEnumerable[object]],[BagToEnumerableQuoter])
    }
    
    BagToEnumerableQuoter([Bag]$substance) : base($substance){}
}

class BagToBagQuoter : BagToEnumerableQuoter{
    static [IQuoterInstaller]Installer(){
        return [QuoterInstaller]::new([Bag],[BagToBagQuoter])
    }

    BagToBagQuoter([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $newOne = [Bag]::new($result,$this.substance.Comparer)
        return $newOne
    }
}

class BagToSetQuoter : BagToEnumerableQuoter{
    static [IQuoterInstaller]Installer(){
        return [IQuoterInstaller]::new([Bag],[BagToSetQuoter])
    }

    BagToSetQuoter([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $newOne = [Collections.Generic.HashSet[object]]::new($result)
        return $newOne
    }
}

class BagToEnumerableExtractor : BagToEnumerableFactory,IExtractor{
    static [IExtractorInstaller]Installer(){
        return [ExtractorInstaller]::new([Collections.Generic.IEnumerable[object]],[BagToEnumerableExtractor])
    }

    BagToEnumerableExtractor([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $this.substance.RemoveAll($result)
        return ($result)
    }
}

class BagToBagExtractor: BagToEnumerableExtractor{
    static [IExtractorInstaller]Installer(){
        return [ExtractorInstaller]::new([Bag],[BagToSetExtractor])
    }

    BagToBagExtractor([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $result = ([BagToEnumerableExtractor]$this).AdjustResult($result)
        $newOne = [Bag]::new($result)
        #$this.substance.RemoveAll($result)
        return $newOne
    }
}
class BagToSetExtractor : BagToSetQuoter, IExtractor{
    static [IExtractorInstaller]Installer(){
        return [ExtractorInstaller]::new([Collections.Generic.HashSet[object]],[BagToSetExtractor])
    }

    BagToSetExtractor([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $result = ([BagToSetQuoter]$this).AdjustResult($result)
        $newOne = [Collections.Generic.HashSet[object]]::new($result)
        #$this.substance.RemoveAll($result)
        return $newOne
    }
}

