class ConvertingFactory {
    static [Type]$ConformanceType = $null
    static InstallOn([Type]$type){
        throw "Subclass responsibility"
    }

    [object]$substance

    ConvertingFactory([object]$substance){
        $this.substance = $substance
    }
}

class BagToSomeConvertingFactory : ConvertingFactory{
    static [ConvertingFactory]$PASSTHRU_FACTORY = [BagThruFactory]

    BagToSomeConvertingFactory([Bag2]$substance) : base($substance){}
    
    hidden [object]ThrowSubclassResponsibility(){
        throw([String]::Format('{0}: Subclass responsibility.',$this.name))
        return $null
    }

    [object]WithSelection([ScriptBlock]$nominator){ return $null }

    [object]WithIntersect([Bag2]$bag2){ return $this.ThrowSubclassResponsibility() }
    [object]WithIntersect([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [object]WithIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    
    [object]WithExcept([Bag2]$bag2){ return $this.ThrowSubclassResponsibility() }
    [object]WithExcept([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [object]WithExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    
    [object]WithUnion([Bag2]$bag2){ return $this.ThrowSubclassResponsibility() }
    [object]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    [object]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable,[Collections.Generic.IEqualityComparer[object]]$comparer){ return $this.ThrowSubclassResponsibility() }
}

class BagThruFactory : BagToSomeConvertingFactory{
    BagThruFactory([Bag2]$substance) : base($substance){}

    [object]WithSelectionBy([ScriptBlock]$nominator){ return $this.substance }
    
    [object]WithIntersect([Bag2]$bag2){ return $this.substance }
    [object]WithIntersect([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){ return $this.substance }
    [object]WithIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.substance }
    
    [object]WithExcept([Bag2]$bag2){ return $this.substance }
    [object]WithExcept([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){ return $this.substance }
    [object]WithExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.substance }
    
    [object]WithUnion([Bag2]$bag2){ return $this.substance}
    [object]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable){ return $this.substance }
    [object]WithUnion([Collections.Generic.IEnumerable[object]]$enumerable,[Collections.Generic.IEqualityComparer[object]]$comparer){ return $this.substance }
}

class BagToSetFactory : ConvertingFactory{
    static [Type]$ConformanceType = [Collections.Generic.HashSet[object]]
    static InstallOn([Type]$type){
        $type::InstallFactory([BagToSetFactory]::ConformanceType,[BagToSetFactory])
    }

    BagToSetFactory([Bag2]$substance) : base($substance){}

    hidden [Collections.Generic.HashSet[object]]createNewInstance([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = [Collections.Generic.HashSet[object]]::new($enumerable,$this.substance.Comparer)
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

class BagToEnumerableFactory : ConvertingFactory{
    static [Type]$ConformanceType = [Collections.Generic.IEnumerable[object]]
    static InstallOn([Type]$type){
        $type::InstallFactory([BagToEnumerableFactory]::ConformanceType,[BagToEnumerableFactory])
    }

    BagToEnumerableFactory([Bag2]$substance) : base($substance){}
 
    [Collections.Generic.IEnumerable[object]]WithSelectionBy([ScriptBlock]$nominator){
        $selection = [Linq.Enumerable]::Where[object]($this.substance,[func[object,bool]]$nominator)
        return $selection
    }
    [Collections.Generic.IEnumerable[object]]WithIntersect([Bag2]$aBag){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aBag = $this.Substance.Clone()
        $aBag.Comparer = [PluggableComparer]::new($keySelector)
        $selection = [Linq.Enumerable]::IntersectBy[object,object]($aBag.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        return $selection
    }
    [Collections.Generic.IEnumerable[object]]WithIntersect([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aBag = $this.Substance.Clone()
        $aBag.Comparer = [PluggableComparer]::new($keySelector)
        $selection = [Linq.Enumerable]::IntersectBy[object,object]($aBag.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        return $selection
    }
    [Collections.Generic.IEnumerable[object]]WithIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        $selection = [Linq.Enumerable]::IntersectBy[object,object]($this.substance.ValuesAndElements,$enumerable,[func[object,object]]{ $args[0].Value })
        return $selection
    }
    [Collections.Generic.IEnumerable[object]]WithExcept([Bag2]$enumerable,[ScriptBlock]$keySelector){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aBag = $this.substance.Clone()
        $aBag.Comparer = [PluggableComparer]::new($keySelector)
        $selection = [Linq.Enumerable]::ExceptBy[object,object]($aBag.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        return $selection
    }
    [Collections.Generic.IEnumerable[object]]WithExcept([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aBag = $this.substance.Clone()
        $aBag.Comparer = [PluggableComparer]::new($keySelector)
        $selection = [Linq.Enumerable]::ExceptBy[object,object]($aBag.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        return $selection
    }
    [Collections.Generic.IEnumerable[object]]ExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        $selection = [Linq.Enumerable]::ExceptBy[object,object]($this.substance.ValuesAndElements,$enumerable,[func[object,object]]{ $args[0].Value })
        return $selection
    }
}

class BagToBagFactory : ConvertingFactory{
    static [Type]$ConformanceType = [Bag2]
    static InstallOn([Type]$type){
        $type::InstallFactory([BagToBagFactory]::ConformanceType,[BagToBagFactory])
    }

    hidden [ConvertingFactory]$helper

    BagToBagFactory([Bag2]$substance) : base($substance){
        $this.helper = [BagToEnumerableFactory]::new($substance)
    }

    hidden [Bag2]createNewInstance([Collections.Generic.IEnumerable[object]]$enumerable){
        return ([Bag2]::new($enumerable,$this.substance.Comparer))
    }
    hidden [Bag2]createNewInstance(){
        return ([Bag2]::new($this.substance.Comparer))
    }

    [Bag2]WithAll(){
        return $this.substance.Clone()
    }

    [Bag2]WithSelectionBy([ScriptBlock]$nominator){
        $selection = $this.helper.SelectionBy($nominator)
        $newOne = $this.CreateNewInstance($selection)
        return $newOne
    }

    [Bag2]SplitSelectionBy([ScriptBlock]$nominator){
        $newOne = $this.WithSelectionBy($nominator)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }

    [Bag2]WithIntersectBy([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $selection = $this.helper.IntersectBy($enumerable,$keySelector)
        $newOne = $this.createNewInstance()
        $selection.foreach{
            $newOne.AddAll($_.Elements)
        }
        return $newOne
    }

    [Bag2]WithIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        $selection = $this.helper.IntersectByValues($enumerable)
        $newOne = $this.createNewInstance()
        $selection.foreach{
            $newOne.AddAll($_.Elements)
        }
        return $newOne
    }

    [Bag2]SplitIntersectBy([Collections.Generic.IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){
        $newOne = $this.WithIntersectBy($enumerable,$keySelector)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }

    [Bag2]SplitIntersectByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = $this.WithIntersectByValues($enumerable)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }

    [Bag2]WithExceptBy([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $selection = $this.helper.ExceptBy($enumerable,$keySelector)
        $newOne = $this.createNewInstance()
        $selection.foreach{
            $newOne.AddAll($_.Elements)
        }
        return $newOne
    }

    [Bag2]WithExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        $selection = $this.helper.ExceptByValues($enumerable)
        $newOne = $this.creatNewInstance()
        $selection.foreach{
            $newOne.AddAll($_.Elements)
        }
        return $newOne
    }

    [Bag2]SplitExceptByValues([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = $this.WithExceptByValues($enumerable)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }
    [Bag2]SplitExceptBy([Collections.Generic.IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $newOne = $this.WithExceptBy($enumerable,$keySelector)
        $this.substance.RemoveAll($newOne)
        return $newOne
    }
}
