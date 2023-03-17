#using module handjive.ObjectList
#using module handjive.misc

<#
    最大数が決まっていて、最大数を超えて要素を追加すると古いものが消えていくList

    (パフォーマンスを考えて、いちいち消すのを辞めたかったけど、
     item[]のオーバーライドが出来そうにないので単純ないちいち消去で…)
#>
class LimitedList : Collections.ArrayList{
    [int]$guaranteeSize
    [int]$threshold         # 現状未使用
    [scriptBlock]$OnElementPushout = {}

    LimitedList([int]$guaranteeSize) : base(){
        $this.OnElementPushout = {}
        $this.guaranteeSize = $guaranteeSize
        $this.threshold = $guaranteeSize
    }
    LimitedList([int]$guaranteeSize,$threshold) : base(){
        $this.guaranteeSize = $guaranteeSize
        $this.threshold = $threshold
    }

    Add([object]$object){
        if( $this.Count -ge $this.guaranteeSize){
            Invoke-Command -ScriptBlock $this.OnElementPushout -ArgumentList $this[0]
            $this.RemoveAt(0)
        }
        ([Collections.ArrayList]$this).Add($object)
    }
    AddAll([object[]]$vars){
        $vars.foreach{ $this.Add($_) }
    }
    <#
    [object[]]Values([scriptblock]$enumerator){
        for($i = 0; $i -lt $this.Count; $i++){
            &$enumerator $this[$i]
        }
        return ($this[0..($this.Count-1)])
    }#>

    [object[]]Values(){
        return ($this.GetRange(0,$this.Count))
    }
}


