<#
#　場当たり的なEnumerator
#
#  [PluggableEnumerator]::new(Enumerationの主体となるオブジェクト)
#
#　$penum.Substance         Enumerationの主体となるオブジェクト
#  $penum.Workingset        Enumerationを実行するために必要なｱﾚｺﾚを格納するための領域(HashTable)
#  $penum.OnCurrentBlock    Currentにアクセスされた時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnMoveNextBlock   MoveNext()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnResetBlock      Reset()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#  $penum.OnDisposeBlock    Dispose()が実行要求された時に実行されるScriptBlock(SubstanceとWorkingSetがパラメータとして渡される)
#>
#using module handjive.Adaptors
using namespace handjive.Collections

class PluggableEnumerator : EnumeratorBase,IPluggableEnumerator {
    <#
    # Collections.IEnumratorをCollections.Generic.IEnumeratorに偽装する
    # (いる?)
    #>
    hidden static [PluggableEnumerator]instantWrapSkelton(){
        $newOne = [PluggableEnumerator]::new()
        $newOne.OnMoveNextBlock = {
            param($substance,$workingset)
            return $substance.MoveNext()
        }
        $newOne.OnCurrentBlock = {
            param($substance,$workingset)
            return $substance.Current
        }
        $newOne.OnResetBlock = {
            param($substance,$workingset)
            $substance.Reset()
        }

        return $newOne
    }

    static [PluggableEnumerator]InstantWrapOn([Collections.IEnumerator]$enumerator){
        $newOne = [PluggableEnumerator]::instantWrapSkelton()
        $newOne.Substance = $enumerator
        $newOne.PSReset()
        return $newOne
    }
    static [PluggableEnumerator]InstantWrapOn([Collections.Generic.IEnumerator[object]]$enumerator){
        $newOne = [PluggableEnumerator]::instantWrapSkelton()
        $newOne.Substance = $enumerator
        $newOne.PSReset()
        return $newOne
    }
    static [PluggableEnumerator]InstantWrapOn([Collections.Generic.IEnumerable[object]]$enumerable){
        $newOne = [PluggableEnumerator]::instantWrapSkelton()
        $newOne.Substance = $enumerable.GetEnumerator()
        $newOne.PSReset()
        return $newOne
    }

    static [PluggableEnumerator]InstantWrapOn([object[]]$indexable){
        $newOne = [PluggableEnumerator]::new($indexable)
        $newOne.Workingset.Max = $indexable.Count -1
        $newOne.OnMoveNextBlock = {
            param($substance,$workingset)
            return( $workingset.Locator++ -lt $workingset.Max )
        }
        $newOne.OnCurrentBlock = {
            param($substance,$workingset)
            return($substance[$workingset.Locator])
        }
        $newOne.OnResetBlock = {
            param($substance,$workingset)
            $workingset.Locator = -1
        }            
        $newOne.PSReset()
        return($newOne)
    }


    <#
    # 空のEnumerator
    #>
    static [PluggableEnumerator]Empty(){
        return [EmptyEnumerator]::new()
    }

    hidden [object]$wpvSubstance
    hidden [HashTable]$wpvWorkingSet
    hidden [ScriptBlock]$wpvOnCurrentBlock  = { param([object]$substance,[HashTable]$workingset) }
    hidden [ScriptBlock]$wpvOnMoveNextBlock = { param([object]$substance,[HashTable]$workingset) return $false }
    hidden [ScriptBlock]$wpvOnResetBlock    = { param([object]$substance,[HashTable]$workingset) }
    hidden [ScriptBlock]$wpvOnDisposeBlock  = { param([object]$substance,[HashTable]$workingset,[bool]$disposing) }

    PluggableEnumerator() : base(){
        $this.wpvWorkingSet = @{}
    }
    PluggableEnumerator([object]$substance) : base(){
        $this.wpvSubstance = $Substance
        $this.wpvWorkingSet = @{}
    }

    <# Property Accessors #>
    [object]get_Substance(){
        return $this.wpvSubstance
    }
    set_Substance([object]$substance){
        $this.wpvSubstance = $substance
    }

    [object]get_OnMoveNextBlock(){
        return ($this.wpvOnMoveNextBlock)
    }
    set_OnMoveNextBlock([object]$aBlock){
        $this.wpvOnMoveNextBlock = $aBlock
    }

    [object]get_OnCurrentBlock(){
        return $this.wpvOnCurrentBlock
    }
    set_OnCurrentBlock([object]$aBlock){
        $this.wpvOnCurrentBlock = $aBlock
    }

    [object]get_OnResetBlock(){
        return($this.wpvOnResetBlock)
    }
    set_OnResetBlock([object]$aBlock){
        $this.wpvOnResetBlock = $aBlock
    }

    [object]get_OnDisposeBlock(){
        return $this.wpvOnDisposeBlock
    }
    set_OnDisposeBlock([object]$aBlock){
        $this.wpvOnDisposeBlock = $aBlock
    }

    [object]get_WorkingSet(){
        if( $null -eq $this.wpvWorkingSet ){
            $this.wpvWorkingSet = @{}
        }
        return($this.wpvWorkingSet)
    }

    <# EnumeratorBase Members #>
    PSDispose([bool]$disposing){
        &$this.OnDisposeBlock $this.Substance $this.WorkingSet $disposing
    }

    [object]PSCurrent(){
        $result = &$this.OnCurrentBlock $this.Substance $this.WorkingSet
        return($result)
    }
    [bool]PSMoveNext(){
        $result = &$this.OnMoveNextBlock $this.Substance $this.WorkingSet
        return($result)
    }
    PSReset(){
        &$this.OnResetBlock $this.Substance $this.WorkingSet
    }

    [object]Current(){
        return $this.PSCurrent()
    }
    [bool]MoveNext(){
        return $this.PSMoveNext()
    }
    Reset(){
        $this.PSReset()
    }

    [Array]ToArray(){
        $result = @()
        while($this.PSMoveNext()){
            $result += $this.PSCurrent()
        }
        return($result)
    }
    [Collections.ArrayList]ToArrayList(){
        $result = [Collections.ArrayList]::new()
        while($this.PSMoveNext()){
            $result.Add($this.PSCurrent())
        }
        return($result)
    }

    <#[EnumerableWrapper]ToEnumerable(){
        return ([EnumerableWrapper]::on($this))
    }#>
}

class EmptyEnumerator : PluggableEnumerator {
    EmptyEnumerator() : base($null){
    }

    <# Property Accessors #>
    [object]get_Substance(){
        return $null
    }
    set_Substance([object]$aSubstance){
    }

    [object]get_OnMoveNextBlock(){
        return({ return $false })
    }
    set_OnMoveNextBlock([object]$aBlock){
    }

    [object]get_OnCurrentBlock(){
        return({ return $null })
    }
    set_OnCurrentBlock([object]$aBlock){
    }

    [object]get_OnResetBlock(){
        return ({})
    }
    set_OnResetBlock([ScriptBlock]$aBlock){
    }

}