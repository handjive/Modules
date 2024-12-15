class DependencyListenerEntry{
    [object]$Listener
    [scriptBlock]$ScriptBlock
    [object[]]$AdditionalArguments

    DependencyListenerEntry(){

    }

    DependencyListenerEntry([object]$Listener,[scriptBlock]$aBlock,[object[]]$AdditionalArguments){
        $this.Listener = $Listener
        $this.ScriptBlock = $aBlock
        $this.Arguments = $AdditionalArguments
    }

    [object]Perform([object]$arguments,[hashtable]$workingset){
        return (&$this.ScriptBlock $this.listener $arguments $this.AdditionalArguments $workingset )
    }
}
class DependencyHolder{
    [object] static $DefaultElementClass = [DependencyListenerEntry]

    [object]$ElementClass
    [Collections.ArrayList]$clients

    DependencyHolder(){
        $this.clients = [Collections.ArrayList]::new()
    }
    DependencyHolder([int]$limit){
        $this.clients = [LimitedList]::new($limit)
    }

    [object]NewElement(){
        if( $null -eq $this.ElementClass ){
            $this.ElementClass = [DependencyHolder]::DefaultElementClass
        }
        return ($this.ElementClass::new())
    }
    
    Add([object]$listener,[scriptBlock]$aBlock){
        $elem = $this.NewElement()
        $elem.Listener = $listener
        $elem.ScriptBlock = $aBlock
        $this.clients.Add($elem)
    }

    [object]Perform([object]$argArray,[hashtable]$workingset,[ScriptBLock]$ifEmpty){
        $lastResult = $null
        if( $this.Count() -eq 0 ){
            return &$ifEmpty
        }
        $this.clients.foreach{
            $lastResult = $_.Perform($argArray,$workingset)
        }

        return($lastResult)
    }

    [object]Perform([object]$argArray,[hashtable]$workingset){
        return($this.Perform($argArray,$workingset,{}))
    }

    [int]Count()
    {
        return ($this.clients.Count)
    }
}
