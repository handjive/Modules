using module handjive.ValueHolder
using module handjive.Foundation
using module handjive.ChainScript

using namespace handjive.Collections

<#
# コレクションをなんかした結果を取り出すアダプタ
# (Select-Objectでいい? -> PSObjectにWrapされない)
#>
class CollectionPluggableAdaptor : EnumerableBase,ICollectionAdaptor{
    [object]$Subject
    [ScriptBlock]$GetValueBlock = { $args[0] }

    CollectionPluggableAdaptor([object]$Subject,[ScriptBlock]$getValueBlock){
        $this.Subject = $Subject
        $this.GetValueBlock = $getValueBlock
    }

    [Collections.Generic.IEnumerable[object]]get_Values(){
        $enumr = [PluggableEnumerator]::new($this)
        $enumr.workingset.valueEnumerator = $this.Subject.GetEnumerator()
        $enumr.OnMoveNextBlock = {
            param($subject,$workingset)
            return($workingset.valueEnumerator.MoveNext())
        }
        $enumr.OnCurrentBlock = {
            param($subject,$workingset)
            return (&$subject.GetValueBlock $workingset.valueEnumerator.Current)
        }
        $enumr.OnResetBlock = {
            param($subject,$workingset)
            $workingset.valueEnumerator.Reset()
        }

        return $enumr.ToEnumerable()
    }
}
<# 
　コレクションから特定プロパティを取り出すアダプタ
#>
class CollectionAspectAdaptor : ICollectionAdaptor{
    [AspectAdaptor]$aspectAdaptor

    CollectionAspectAdaptor([object]$subject,[string]$aspect){
        $this.aspectAdaptor = [AspectAdaptor]::new($subject,$aspect)
    }

    hidden [object]GetAspectValue([object]$anObj){
        return ($this.aspectAdaptor.ValueUsingSubject($anObj))
    }

    [Collections.Generic.IEnumerable[object]]get_Values(){
        $enumr = [PluggableEnumerator]::new($this)
        $enumr.workingset.valueEnumerator = $this.Subject.GetEnumerator()
        $enumr.OnMoveNextBlock = {
            param($subject,$workingset)
            return($workingset.valueEnumerator.MoveNext())
        }
        $enumr.OnCurrentBlock = {
            param($subject,$workingset)
            $elem = $workingset.valueEnumerator.Current
            return $subject.GetAspectValue($elem)
        }
        $enumr.OnResetBlock = {
            param($subject,$workingset)
            $workingset.valueEnumerator.Reset()
        }
        return $enumr.ToEnumerable()
    }
}