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
