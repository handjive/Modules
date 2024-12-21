using namespace System.Collections.Specialized
using namespace System.Collections

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
    [OrderedDictionary]$subscribers = [OrderedDictionary]::new()

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
    
    Add([object]$anEvent,[object]$listener,[scriptBlock]$aBlock)
    {
        [ArrayList]$entries = @()
        
        if( -not ($this.subscribers.Keys -contains $anEvent ) ){
            $this.subscribers.Add($anEvent,($entries = [ArrayList]::new()))
        }
        else{
            $entries = $this.subscribers[$anEvent]
        }

        $elem = $this.NewElement()
        $elem.Listener = $listener
        $elem.ScriptBlock = $aBlock
        $entries.Add($elem)
    }

    [object[]]Perform([object]$anEvent,[object]$argArray,[hashtable]$workingset){
        $result = [ArrayList]::new()

        Write-Debug $anEvent.gettype()
        # イベントのサブスクライバがいなければ終了
        if( -not ($this.subscribers.keys -contains $anEvent) ){
            return $null
        }

        ($this.subscribers[$anEvent]).foreach{
            $entry = [DependencyListenerEntry]$_
            $result.Add($entry.Perform($argarray,$workingset))
        }

        return($result)
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
