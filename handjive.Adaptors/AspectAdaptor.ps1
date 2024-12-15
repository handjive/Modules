using module handjive.ValueHolder

class AspectAdaptor : ValueModel{
    [string]$Aspect

    hidden [void]Initialize(){
        ([ValueModel]$this).Initialize()
    }
    
    AspectAdaptor([object]$subject,[string]$aspect) : base($subject){
        $this.Aspect = $aspect
    }

    [object]ValueUsingSubject([object]$subject){
        # 対象AspectがEnumerableの類だった場合の対処として、結果をHashTable経由で受け取る
        $expStr = [String]::Format('param($subject,[HashTable]$ws) $ws.Add("Result",$subject.{0})',$this.Aspect)
        $exp = [ScriptBlock]::Create($expStr)
        $ws=@{}
        Invoke-Command -ScriptBlock $exp -ArgumentList @($this.Subject,$ws)
        return ($ws.Result)
    }
    ValueUsingSubject([object]$subject,[object]$value){
        $expStr = [String]::Format('param($subject,$value) $subject.{0} = $value',$this.Aspect)
        $exp = [ScriptBlock]::create($expStr)
        Invoke-Command -ScriptBlock $exp -ArgumentList @($this.Subject,$value)
    }
}
