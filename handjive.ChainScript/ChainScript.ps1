<#
    { do something... } → exit
                        → perform[+1] { do something }  → perform[-1]
                                                        → perform[+1]


    script arguments context                                                        
#>

enum ChainFlow{
    Forward
    Backward
    Stay
    Ready
    Terminate
    Next
}
class ChainScriptElement{
    [ScriptBlock]$Block
    [HashTable]$Arguments = @{}
    [HashTable]$Context = @{}

}

class ChainScript{
    static [object]$DEFAULT_ELEMENT = [ChainScriptElement]

    [Collections.ArrayList]$chain = [Collections.ArrayList]::new()
    [int]$depth = 0
    [HashTable]$workingset = @{}
    [ScriptBlock]$GetValueBlock = {}
    [ScriptBlock]$ResetBlock = {}
    [ScriptBlock]$InitializeBlock = {}
    [ScriptBlock]$GivingUP = { 100 }

    [object]NewElement(){
        $elem = [ChainScript]::DEFAULT_ELEMENT::new()
        $this.AddChain($elem)
        return $elem
    }
    AddChain([ChainScriptElement]$elem){
        $this.chain.Add($elem)
    }
    
    Initialize(){
        &$this.InitializeBlock $this
    }
    Reset(){
        &$this.ResetBlock $this
    }
    GetValue(){
        &$this.GetValueBlock $this
    }

    [bool]Perform(){
        $loopCount = 0
        do{            
            $control = @{}
            $elem = $this.chain[$this.depth]
            &($elem.Block) $elem.context $this.workingset $control $this.depth

            switch([string]([ChainFlow]$control.Flow)){
                Terminate { return($false)  }
                Forward   { $this.depth++   }
                Backward  { $this.depth--   }
                Next      { $this.depth = 0 }
                Ready     { 
                    $loopCount = 0
                    return($true)   
                }
            }
        }
        until( $loopCount++ -ge (&$this.Givingup) )
        throw 'Terminate because Too many loops. If you realy want, Set "Givingup" you need.'
        return($false)
    }
}
