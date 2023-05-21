<#
Bagの集合操作実装を動機とした変換オブジェクト生成クラス一式

BagをLinq.Enumerable等の集合操作で変換する機能が欲しかったが、どの程度までを範囲(対象とする変換後オブジェクトの種類、変換操作)とするか決めきれなかった。
そのためそれぞれを分離し、Bagの変更無しに後付け変更可能な構造を取ることにした。
(当初、interfaceによる制約で必要な実装を規定しようと試みたものの、Powershellクラスがinterface明示メソッドを記述できないため上手くいかずその方法を放棄、
お約束ベースになってしまった。本当に無理なのかね?)

以下、お約束:

・Bag(或いは、この方法を取る他のクラス)はstatic変数QUOTERS/EXTRACTORS(変換対象のTypeをKey、変換処理クラスのTypeをValueとする辞書)を持つ。
・BagはメソッドQuoteTo([Type])でQuoterを、ExtractTo([Type])でExtractorを取り出すことができ、実行可能な変換操作はQuoter/Extractorの実装に分離する。
・Quoter/Extractorは、Bagの辞書に自身をインストールするメソッド[QuoterInstaller]GetInstaller()/[ExtractorInstaller]GetInstaller()を実装する。
(Bagの辞書構造はQuoterInstaller/ExtractorInstallerが知っている)

Quoter/Extractorの違いは以下の通り。
Quoter: 元オブジェクトに影響を与えずに何らかの処理を加えた結果で新しいオブジェクトを生成する処理の集合
Extractor: 元オブジェクトに何らかの処理を加えた結果で新しいオブジェクトを生成し、元オブジェクトからその要素を取り除く処理の集合

実装している集合操作は以下の通りで、それぞれIEnumerable[object],Bag,HashSet[object]に変換可能。
("WithSelectionBy"→Whereを除いて、だいたいLinq.Enumerableと一緒)

    using namespace System.Collections.Generic

    [IEnumerable[object]]WithSelectionBy([ScriptBlock]$nominator)

    [IEnumerable[object]]WithIntersect([Bag]$bag)
    [IEnumerable[object]]WithIntersect([IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector)
    [IEnumerable[object]]WithIntersectByValues([IEnumerable[object]]$enumerable)
    
    [IEnumerable[object]]WithExcept([Bag]$bag)
    [IEnumerable[object]]WithExcept([IEnumerable[object]]$enumerable,[func[object,object]]$keySelector)
    [IEnumerable[object]]WithExceptByValues([IEnumerable[object]]$enumerable)
    
    [IEnumerable[object]]WithUnion([Bag]$bag)
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable)
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable,[ScriptBlock]$converter)

    [IEnumerable[object]]WithMaxBy([Type]$aType,[ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMaxBy([Type]$aType,[string]$aspectName)

    [IEnumerable[object]]WithMinBy([Type]$aType,[ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMinBy([Type]$aType,[string]$aspectName)

    [IEnumerable[object]]WithMaxBy([ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMaxBy([string]$aspectName)

    [IEnumerable[object]]WithMinBy([ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMinBy([string]$aspectName)

#>


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

<#class QuotingFactory : IQuoter{
    static [Type]$ConformanceType = $null
    static [ConvertingFactoryInstaller]GetInstaller(){
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
    static [ConvertingFactoryInstaller]GetInstaller(){
        throw "Subclass responsibility"
        return $null
    }

    [object]$substance

    ExtractingFactory([object]$substance){
        $this.substance = $substance
    }
}
#>

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

    [Collections.Generic.IEnumerable[object]]WithSelectionBy([ScriptBlock]$nominator){ return $this.ThrowSubclassResponsibility() }

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

