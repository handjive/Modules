using namespace handjive.Collections

class ConvertingFactoryInstaller{
    [Type]$Factory
    [Type]$ConvertTo

    ConvertingFactoryInstaller([Type]$convertTo,[Type]$factory){
        $this.Factory = $factory
        $this.ConvertTo = $convertTo
    }

    [Collections.Generic.Dictionary[Type,Type]]GetDictionary([Type]$target){
        return $null
    }

    InstallOn([Type]$target){
        $dict = $this.GetDictionary($target)
        if( $null -eq $dict[$this.ConvertTo] ){
            $dict.Add($this.ConvertTo,$this.Factory)
        }
        else{
            $dict[$this.ConvertTo] = $this.Factory
        }
    }

}

class QuoterInstaller : ConvertingFactoryInstaller {
    QuoterInstaller([Type]$quoteTo,[Type]$quoter) : base($quoteTo,$quoter){  }

    [Collections.Generic.Dictionary[Type,Type]]GetDictionary([Type]$target){
        return $target::QUOTERS
    }
}

class ExtractorInstaller : ConvertingFactoryInstaller{
    ExtractorInstaller([Type]$quoteTo,[Type]$quoter) : base($quoteTo,$quoter) {  }

    [Collections.Generic.Dictionary[Type,Type]]GetDictionary([Type]$target){
        return $target::EXTRACTORS
    }
}

class QuotingFactory : IQuoter{
    static [Type]$ConformanceType = $null
    static [ConvertingFactoryInstaller]Installer(){
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
    static [ConvertingFactoryInstaller]Installer(){
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
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$converter){ return $this.ThrowSubclassResponsibility() }

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
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$converter){ return $this.substance }

    [Collections.Generic.IEnumerable[object]]WithMaxBy([ScriptBlock]$keySelector){ return $this.substance }
    [Collections.Generic.IEnumerable[object]]WithMaxBy([string]$aspectName){ return $this.substance }
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

    [Collections.Generic.IEnumerable[object]]WithUnion([Bag]$bag){
        $aClone = $this.substance.Clone()
        $union = [Linq.Enumerable]::Union[object]($aClone,$bag)
        return $this.AdjustResult($union)
    }
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable){
        return $this.WithUnion($enumerable,{ $args[0] })
    }
    [Collections.Generic.IEnumerable[object]]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$converter){
        $aClone = $this.substance.Clone()
        $converted = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$converter)
        $union = [Linq.Enumerable]::Union[object]($aClone,$converted)
        return $this.AdjustResult($union)
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

class BagToEnumerableQuoter : BagToEnumerableFactory<#, IQuoter#>{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [QuoterInstaller]::new([Collections.Generic.IEnumerable[object]],[BagToEnumerableQuoter])
    }
    <#static [IQuoterInstaller]Installer(){
        return [QuoterInstaller]::new([Collections.Generic.IEnumerable[object]],[BagToEnumerableQuoter])
    }#>
    
    BagToEnumerableQuoter([Bag]$substance) : base($substance){}
}

class BagToBagQuoter : BagToEnumerableQuoter{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [QuoterInstaller]::new([Bag],[BagToBagQuoter])
    }

    BagToBagQuoter([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $newOne = [Bag]::new($result,$this.substance.Comparer)
        return $newOne
    }
}

class BagToSetQuoter : BagToEnumerableQuoter{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [QuoterInstaller]::new([Bag],[BagToSetQuoter])
    }

    BagToSetQuoter([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $newOne = [Collections.Generic.HashSet[object]]::new($result)
        return $newOne
    }
}

class BagToEnumerableExtractor : BagToEnumerableFactory<#,IExtractor#>{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [ExtractorInstaller]::new([Collections.Generic.IEnumerable[object]],[BagToEnumerableExtractor])
    }

    BagToEnumerableExtractor([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $this.substance.RemoveAll($result)
        return ($result)
    }
}

class BagToBagExtractor: BagToEnumerableExtractor{
    static [ConvertingFactoryInstaller]GetInstaller(){
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
class BagToSetExtractor : BagToEnumerableExtractor{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [ExtractorInstaller]::new([Collections.Generic.HashSet[object]],[BagToSetExtractor])
    }

    BagToSetExtractor([Bag]$substance) : base($substance){}

    [Collections.Generic.IEnumerable[object]]AdjustResult([Collections.Generic.IEnumerable[object]]$result){
        $result = ([BagToEnumerableExtractor]$this).AdjustResult($result)
        $newOne = [Collections.Generic.HashSet[object]]::new($result)
        #$this.substance.RemoveAll($result)
        return $newOne
    }
}

