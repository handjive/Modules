class AspectAdaptor : ValueAdaptor{
    [string]$Aspect

    AspectAdaptor([object]$subject,[string]$aspect) : base($subject){
        $this.Aspect = $aspect
    }

    hidden [void]Initialize(){
        ([ValueAdaptor]$this).Initialize()
        Write-Debug "Initializing in AspectAdaptor"

        #([ValueModel]$this).Initialize()
    }
    
    [object]ValueUsingSubject(){
        # 対象AspectがEnumerableの類だった場合の対処として、結果をHashTable経由で受け取る
        $expStr = [String]::Format('param($subject,[HashTable]$ws) $ws.Add("Result",$subject.{0})',$this.Aspect)
        $exp = [ScriptBlock]::Create($expStr)
        $ws=@{}
        Invoke-Command -ScriptBlock $exp -ArgumentList @($this.Subject,$ws)
        return ($ws.Result)
    }
    ValueUsingSubject([object]$value){
        $expStr = [String]::Format('param($subject,$value) $subject.{0} = $value',$this.Aspect)
        $exp = [ScriptBlock]::create($expStr)
        Invoke-Command -ScriptBlock $exp -ArgumentList @($this.Subject,$value)
    }
}
