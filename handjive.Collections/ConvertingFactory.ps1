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
(だいたいLinq.Enumerableと一緒)
WithWhere,WithSelect,WithSelectMany,WithMax,WithMinの処理対象はElements。
必要があればgetSubjectBlockを指定する。

WithIntersect,WithExcept,WithUnionの処理対象はValuesAndOccurrences。
これにgetSubjectBlocを指定可能なオーバーライドは用意していない(多分意味がないと思うんで…)

    using namespace System.Collections.Generic

    [IEnumerable[object]]WithWhere([ScriptBlock]$nominator)
    [IEnumerable[object]]WithWhere([ScriptBlock]$getSubjectBlock,[ScriptBlock]$nominator)
    [IEnumerable[object]]WithSelect([ScriptBlock]$operator)
    [IEnumerable[object]]WithSelect([ScriptBlock]$getSubjectBlock,[ScriptBlock]$operator)

    [IEnumerable[object]]WithSelectMany([ScriptBlock]$operator)
    [IEnumerable[object]]WithSelectMany([ScriptBlock]$getSubjectBlock,[ScriptBlock]$operator)
    [IEnumerable[object]]WithSelectMany([ScriptBlock]$getSubjectBlock,[ScriptBlock]$colectionSelector,[ScriptBlock]$resultSelector)
    
    [IEnumerable[object]]WithMaxBy([Type]$aType,[ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMaxBy([ScriptBlock]$getSubjectBlock,[Type]$aType,[ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMaxBy([ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMaxBy([Type]$aType,[string]$aspectName)
    [IEnumerable[object]]WithMaxBy([string]$aspectName)

    [IEnumerable[object]]WithMinBy([Type]$aType,[ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMinBy([ScriptBlock]$keySelector)
    [IEnumerable[object]]WithMinBy([Type]$aType,[string]$aspectName)
    [IEnumerable[object]]WithMinBy([string]$aspectName)

    [IEnumerable[object]]WithIntersect([Bag]$bag)
    [IEnumerable[object]]WithIntersect([IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector)
    [IEnumerable[object]]WithIntersectByValues([IEnumerable[object]]$enumerable)
    
    [IEnumerable[object]]WithExcept([Bag]$bag)
    [IEnumerable[object]]WithExcept([IEnumerable[object]]$enumerable,[func[object,object]]$keySelector)
    [IEnumerable[object]]WithExceptByValues([IEnumerable[object]]$enumerable)
    
    [IEnumerable[object]]WithUnion([Bag]$bag)
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable)
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable,[ScriptBlock]$converter)
#>

using namespace System.Collections.Generic

class ConvertingFactoryInstaller{
    [Type]$Factory
    [Type]$ConvertTo

    ConvertingFactoryInstaller([Type]$convertTo,[Type]$factory){
        $this.Factory = $factory
        $this.ConvertTo = $convertTo
    }

    [Dictionary[Type,Type]]GetDictionary([Type]$target){
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

    [Dictionary[Type,Type]]GetDictionary([Type]$target){
        return $target::QUOTERS
    }
}

class ExtractorInstaller : ConvertingFactoryInstaller{
    ExtractorInstaller([Type]$quoteTo,[Type]$quoter) : base($quoteTo,$quoter) {  }

    [Dictionary[Type,Type]]GetDictionary([Type]$target){
        return $target::EXTRACTORS
    }
}



class BagToSomeConvertingFactory {
    [Bag]$substance

    BagToSomeConvertingFactory([Bag]$substance){
        $this.substance = $substance
    }
    
    hidden [object]ThrowSubclassResponsibility(){
        throw([String]::Format('{0}: Subclass responsibility.',$this.gettype().name))
        return $null
    }

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        return $result
    }

    <# Sublass responsibilities #>

    [IEnumerable[object]]WithWhere([ScriptBlock]$nominator){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithWhere([BagEnumerableType]$enumType,[ScriptBlock]$nominator){ return $this.ThrowSubclassResponsibility() }
    
    <#
    [IEnumerable[object]]WithSelect([ScriptBlock]$operator){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithSelect([ScriptBlock]$getSubjectBlock,[ScriptBlock]$operator){ return $this.ThrowSubclassResponsibility() }

    [IEnumerable[object]]WithSelectMany([ScriptBlock]$operator){ return $this.ThrowSubclassResponsibility() }
#   [IEnumerable[object]]WithSelectMany([ScriptBlock]$colectionSelector,[ScriptBlock]$resultSelector){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithSelectMany([ScriptBlock]$getSubjectBlock,[ScriptBlock]$operator){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithSelectMany([ScriptBlock]$getSubjectBlock,[ScriptBlock]$colectionSelector,[ScriptBlock]$resultSelector){ return $this.ThrowSubclassResponsibility() }
    #>

    [IEnumerable[object]]WithMaxBy([Type]$aType,[ScriptBlock]$keySelector){ return return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithMaxBy([Type]$aType,[string]$aspectName){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithMaxBy([BagEnumerableType]$enumType,[Type]$aType,[ScriptBlock]$keySelector){ return return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithMaxBy([BagEnumerableType]$enumType,[Type]$aType,[string]$aspectName){ return $this.ThrowSubclassResponsibility() }

    [IEnumerable[object]]WithMinBy([Type]$aType,[ScriptBlock]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithMinBy([Type]$aType,[string]$aspectName){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithMinBy([BagEnumerableType]$enumType,[Type]$aType,[ScriptBlock]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithMinBy([BagEnumerableType]$enumType,[Type]$aType,[string]$aspectName){ return $this.ThrowSubclassResponsibility() }

    <# May works as is... #>
    [IEnumerable[object]]WithMaxBy([ScriptBlock]$keySelector){ return ($this.WithMaxBy([object],$keySelector))}
    [IEnumerable[object]]WithMaxBy([string]$aspectName){ return ($this.WithMaxBy([object],$aspectName)) }

    [IEnumerable[object]]WithMinBy([ScriptBlock]$keySelector){ return ($this.WithMinBy([object],$keySelector))}
    [IEnumerable[object]]WithMinBy([string]$aspectName){ return ($this.WithMinBy([object],$aspectName)) }

    <#
    # 集合操作の対象はValuesAndOccurrencesのみ(Setとして)
    #>
    [IEnumerable[object]]WithIntersect([Bag]$bag2){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithIntersect([IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithIntersectByValues([IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    
    [IEnumerable[object]]WithExcept([Bag]$bag2){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithExcept([IEnumerable[object]]$enumerable,[func[object,object]]$keySelector){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithExceptByValues([IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    
    [IEnumerable[object]]WithUnion([Bag]$bag2){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable){ return $this.ThrowSubclassResponsibility() }
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable,[ScriptBlock]$converter){ return $this.ThrowSubclassResponsibility() }
}


class BagToEnumerableFactory : BagToSomeConvertingFactory{
    BagToEnumerableFactory([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([BagEnumerableType]$enumType,[IEnumerable[object]]$imResult,[Bag]$aBag){
        $result = switch($enumType){
            ValuesAndOccurrences {
                $values = [Linq.Enumerable]::Select[object,object]($imResult,[func[object,object]]{ $args[0].Value })
                $selection = [Linq.Enumerable]::IntersectBy[object,object]($aBag.ValuesAndElements,$values,[func[object,object]]{ $args[0].Value })
                [Linq.Enumerable]::SelectMany[object,object]($selection,[func[object,IEnumerable[object]]]{ $args[0].Elements })
                break
            }
            ValuesAndElements {
                [Linq.Enumerable]::SelectMany[object,object]($imResult,[func[object,IEnumerable[object]]]{ $args[0].Elements })
                break
            }
            default{
                $imResult
            }
        }
        return $this.AdjustResult($result)
    }

    <#
    # 指定条件に一致する要素の取り出し
    #>
    [IEnumerable[object]]WithWhere([BagEnumerableType]$enumType,[ScriptBlock]$nominator){
        $aClone = $this.substance.Clone()
        $subject = $aClone.GetEnumerable($enumType)
        $selection = [Linq.Enumerable]::Where[object]($subject,[func[object,bool]]$nominator)
        return $this.AdjustResult($enumType,$selection,$aClone)
    }
    [IEnumerable[object]]WithWhere([ScriptBlock]$nominator){
        return $this.WithWhere([BagEnumerableType]::Elements,$nominator)
    }

    <#
    # 最大と判定された要素の取り出し
    #>
    [object]WithMaxBy([BagEnumerableType]$enumType,[Type]$aType,[ScriptBlock]$keySelector){
        $execFrame = '[Linq.Enumerable]::MaxBy[object,{0}]($args[0],[func[object,{0}]]$args[1])'
        $executer = [ScriptBlock]::create([String]::Format($execFrame,$aType))
        $aClone = $this.substance.Clone()
        $subject = $aClone.GetEnumerable($enumType)
        $result = &$executer $subject $keySelector
        return $this.AdjustResult($enumType,@($result),$aClone)
    }
    [object]WithMaxBy([Type]$aType,[ScriptBlock]$keySelector){
        return $this.WithMaxBy([BagEnumerableType]::Elements,$aType,$keySelector)
    }
    [object]WithMaxBy([BagEnumerableType]$enumType,[Type]$aType,[string]$aspectName){ 
        return $this.WithMaxBy($enumType,$aType,[AspectComparer]::new($aspectName).GetSubjectBlock)
    }
    [object]WithMaxBy([Type]$aType,[string]$aspectName){ 
        return $this.WithMaxBy([BagEnumerableType]::Elements,$aType,$aspectName)
    }

    <#
    # 最小と判定された要素の取り出し
    #>
    [object]WithMinBy([BagEnumerableType]$enumType,[Type]$aType,[ScriptBlock]$keySelector){
        $execFrame = '[Linq.Enumerable]::MinBy[object,{0}]($args[0],[func[object,{0}]]$args[1])'
        $executer = [ScriptBlock]::create([String]::Format($execFrame,$aType))
        $aClone = $this.substance.Clone()
        $subject = $aClone.GetEnumerable($enumType)
        $result = &$executer $subject $keySelector
        return $this.AdjustResult(@($result))
    }
    [object]WithMinBy([Type]$aType,[ScriptBlock]$keySelector){
        return $this.WithMinBy([BagEnumerableType]::Elements,$aType,$keySelector)
    }
    [object]WithMinBy([BagEnumerableType]$enumType,[Type]$aType,[string]$aspectName){ 
        return $this.WithMinBy($enumType,$aType,[AspectComparer]::new($aspectName).GetSubjectBlock)
    }
    [object]WithMinBy([Type]$aType,[string]$aspectName){ 
        return $this.WithMinBy([BagEnumerableType]::Elements,$aType,$aspectName)
    }

    [IEnumerable[object]]WithIntersect([Bag]$aBag){
        $keys = [Linq.Enumerable]::Select[object,object]($aBag.ValuesAndElements,[func[object,object]]{ $args[0].Value })
        $aClone = $this.Substance.Clone()
        $aClone.Comparer = $aBag.Comparer
        $intersect = [Linq.Enumerable]::IntersectBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $intersect.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [IEnumerable[object]]WithIntersect([IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aClone = $this.substance.Clone()
        $intersect = [Linq.Enumerable]::IntersectBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $intersect.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [IEnumerable[object]]WithIntersectByValues([IEnumerable[object]]$enumerable){
        return $this.WithIntersect($enumerable,{ $args[0] })
    }

    [IEnumerable[object]]WithExcept([Bag]$aBag){
        $keys = [Linq.Enumerable]::Select[object,object]($aBag.ValuesAndOccurrences,[func[object,object]]{ $args[0].Value })
        $aClone = $this.substance.Clone()
        $aClone.Comparer = $aBag.Comparer
        $except = [Linq.Enumerable]::ExceptBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $except.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [IEnumerable[object]]WithExcept([IEnumerable[object]]$enumerable,[ScriptBlock]$keySelector){
        $keys = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$keySelector)
        $aClone = $this.substance.Clone()
        $except = [Linq.Enumerable]::ExceptBy[object,object]($aClone.ValuesAndElements,$keys,[func[object,object]]{ $args[0].Value })
        $elements = $except.foreach{ $_.Elements }
       
        return $this.AdjustResult($elements)
    }
    [IEnumerable[object]]WithExceptByValues([IEnumerable[object]]$enumerable){
        return $this.WithExcept($enumerable,{ $args[0] })
    }

    [IEnumerable[object]]WithUnion([Bag]$bag){
        $aClone = $this.substance.Clone()
        $union = [Linq.Enumerable]::Union[object]($aClone,$bag)
        return $this.AdjustResult($union)
    }
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable){
        return $this.WithUnion($enumerable,{ $args[0] })
    }
    [IEnumerable[object]]WithUnion([IEnumerable[object]]$enumerable,[ScriptBlock]$converter){
        $aClone = $this.substance.Clone()
        $converted = [Linq.Enumerable]::Select[object,object]($enumerable,[func[object,object]]$converter)
        $union = [Linq.Enumerable]::Union[object]($aClone,$converted)
        return $this.AdjustResult($union)
    }
}

<#
# Extractorが対応できない、不定要素を返すことが想定されるFactory
#>
class EnhancedBagToEnumerableFactory : BagToEnumerableFactory{
    EnhancedBagToEnumerableFactory([Bag]$substance) : base($substance){}

    <#
    # 各要素の評価結果取り出し
    #>
    [IEnumerable[object]]WithSelect([BagEnumerableType]$enumType,[ScriptBlock]$operator){
        $aClone = $this.substance.Clone()
        $subject = $aClone.GetEnumerable($enumType)
        $selection = [Linq.Enumerable]::Select[object,object]($subject,[func[object,object]]$operator)
        return $this.AdjustResult($selection)
    }
    [IEnumerable[object]]WithSelect([ScriptBlock]$operator){
        return $this.WithSelect([BagEnumerableType]::Elements,$operator)
    }

    <#
    # 要素中の集合を射影
    #>
    [IEnumerable[object]]WithSelectMany([BagEnumerableType]$enumType,[ScriptBlock]$collectionSelector){
        $aClone = $this.substance.Clone()
        $subject = $aClone.GetEnumerable($enumType)
        $selection = [Linq.Enumerable]::SelectMany[object,object]($subject,[func[object,IEnumerable[object]]]$collectionSelector)
        return $this.AdjustResult($selection)
    }
    [IEnumerable[object]]WithSelectMany([ScriptBlock]$collectionSelector){
        return $this.WithSelectMany([BagEnumerableType]::ValuesAndElements,$collectionSelector)
    }
    [IEnumerable[object]]WithSelectMany([BagEnumerableType]$enumType,[ScriptBlock]$collectionSelector,[ScriptBlock]$resultSelector){
        $aClone = $this.substance.Clone()
        $subject = $aClone.GetEnumerable($enumType)
        $selection = [Linq.Enumerable]::SelectMany[object,object,object]($subject,[func[object,IEnumerable[object]]]$collectionSelector,[func[object,object,object]]$resultSelector)
        return $this.AdjustResult($selection)
    }
}

class BagToEnumerableQuoter : EnhancedBagToEnumerableFactory<#, IQuoter#>{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [QuoterInstaller]::new([IEnumerable[object]],[BagToEnumerableQuoter])
    }
    <#static [IQuoterInstaller]Installer(){
        return [QuoterInstaller]::new([IEnumerable[object]],[BagToEnumerableQuoter])
    }#>
    
    BagToEnumerableQuoter([Bag]$substance) : base($substance){}
}

class BagToBagQuoter : EnhancedBagToEnumerableFactory{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [QuoterInstaller]::new([Bag],[BagToBagQuoter])
    }

    BagToBagQuoter([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        $newOne = [Bag]::new($result,$this.substance.Comparer)
        return $newOne
    }
}

class BagToSetQuoter : EnhancedBagToEnumerableFactory{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [QuoterInstaller]::new([HashSet[object]],[BagToSetQuoter])
    }

    BagToSetQuoter([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        $newOne = [HashSet[object]]::new($result)
        return $newOne
    }
}

class BagToListQuoter : EnhancedBagToEnumerableFactory{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [QuoterInstaller]::new([List[object]],[BagToListQuoter])
    }

    BagToListQuoter([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        $newOne = [List[object]]::new($result)
        return $newOne
    }
}

class BagToEnumerableExtractor : BagToEnumerableFactory<#,IExtractor#>{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [ExtractorInstaller]::new([IEnumerable[object]],[BagToEnumerableExtractor])
    }

    BagToEnumerableExtractor([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        $this.substance.RemoveAll($result)
        return ($result)
    }
}

class BagToBagExtractor: BagToEnumerableExtractor{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [ExtractorInstaller]::new([Bag],[BagToBagExtractor])
    }

    BagToBagExtractor([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        $result = ([BagToEnumerableExtractor]$this).AdjustResult($result)
        $newOne = [Bag]::new($result)
        #$this.substance.RemoveAll($result)
        return $newOne
    }
}
class BagToSetExtractor : BagToEnumerableExtractor{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [ExtractorInstaller]::new([HashSet[object]],[BagToSetExtractor])
    }

    BagToSetExtractor([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        $result = ([BagToEnumerableExtractor]$this).AdjustResult($result)
        $newOne = [HashSet[object]]::new($result)
        #$this.substance.RemoveAll($result)
        return $newOne
    }
}

class BagToListExtractor : BagToEnumerableExtractor{
    static [ConvertingFactoryInstaller]GetInstaller(){
        return [ExtractorInstaller]::new([List[object]],[BagToListExtractor])
    }

    BagToListExtractor([Bag]$substance) : base($substance){}

    [IEnumerable[object]]AdjustResult([IEnumerable[object]]$result){
        $result = ([BagToEnumerableExtractor]$this).AdjustResult($result)
        $newOne = [List[object]]::new($result)
        return $newOne
    }
}
