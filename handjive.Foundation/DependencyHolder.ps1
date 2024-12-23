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
    [OrderedDictionary]$subscribers = [OrderedDictionary]::new()
    [hashtable]$WorkingSet = @{}
    [bool]$Supress = $false

    DependencyHolder(){
        $this.subscribers = [OrderedDictionary]::new()
    }
    DependencyHolder([int]$limit){
        $this.subscribers = [OrderedDictionary]::new()
    }

    [object]NewElement(){
        if( $null -eq $this.ElementClass ){
            $this.ElementClass = [DependencyHolder]::DefaultElementClass
        }
        return ($this.ElementClass::new())
    }
    
    Add([object]$anEvent,[scriptBlock]$aBlock)
    {
        $this.Add($anEvent,$null,$aBlock)
    }

    Add([object]$anEvent,[object]$listener,[scriptBlock]$aBlock)
    {
        [ArrayList]$entries = @()
        
        if( -not ($this.subscribers.Keys -contains ([string]$anEvent) ) ){
            $this.subscribers.Add(([string]$anEvent),($entries = [ArrayList]::new()))
        }
        else{
            $entries = $this.subscribers[([int]$anEvent)]
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
        if( -not ($this.subscribers.keys -contains ([string]$anEvent)) ){
            return $null
        }
        
        $anArray = $this.subscribers[([string]$anEvent)]
        if( $null -eq $anArray  ){
            Write-Error "HOGEEEE!!"
        }
        ($anArray).foreach{
            $entry = [DependencyListenerEntry]$_
            $result.Add($entry.Perform($argarray,$workingset))
        }

        return($result)
    }

    [int]Count()
    {
        return ($this.subscribers.Count)
    }
    
    [object[]]TriggerEvent([object]$anEvent,[array]$parameters){ 
        $result = @()
        if( -not $this.Suppress ){
            $result = $this.Perform($anEvent,$parameters,$this.WorkingSet)
        }

        return $result 
    }

}
