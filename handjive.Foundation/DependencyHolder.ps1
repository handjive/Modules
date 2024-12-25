#using namespace System.Collections.Specialized
using namespace System.Collections.Generic
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
    [hashtable]$WorkingSet = @{}
    [bool]$Supress = $false
    [Dictionary[string,List[DependencyListenerEntry]]]$entries 

    DependencyHolder(){
        #$this.entries = [Dictionary[string,List[DependencyListenerEntry]]]::new[string,List[DependencyListenerEntry]]()
        $this.entries = [Dictionary[string,List[DependencyListenerEntry]]]::new()
    }

    hidden [object]NewElement(){
        if( $null -eq $this.ElementClass ){
            $this.ElementClass = [DependencyHolder]::DefaultElementClass
        }
        return ($this.ElementClass::new())
    }
    
    Add([enum]$anEvent,[scriptBlock]$aBlock)
    {
        $this.Add($anEvent,$null,$aBlock)
    }

    Add([enum]$anEvent,[object]$listener,[scriptBlock]$aBlock)
    {
        if( $null -eq $anEvent  ){
            return
        }
        Write-Debug "Event=$anEvent, listener=$listener, Block={ $aBlock }"
        Write-Debug "this=$this"

        if( $null -eq $this.entries ){
            return
        }

        [List[DependencyListenerEntry]]$aList = [List[DependencyListenerEntry]]::new()
        
        if( -not ($this.entries.Keys -contains ([string]$anEvent) ) ){
            $this.entries.Add(([string]$anEvent),$aList)
        }
        else{
            Write-Debug ($null -eq $this.entries)
            $aList = $this.entries[([string]$anEvent)]
            Write-Debug ($null -eq $aList)
        }

        $elem = $this.NewElement()
        $elem.Listener = $listener
        $elem.ScriptBlock = $aBlock
        $aList.Add($elem)
    }

    hidden [object[]]Perform([enum]$anEvent,[object]$argArray,[hashtable]$workingset){
        $result = [ArrayList]::new()
        if( $null -eq $anEvent  ){
            return $result
        }
        
        Write-Debug "this=$this"
        if( $null -eq $this.entries ){
            return $result
        }

        # イベントのサブスクライバがいなければ終了
        if( -not ($this.entries.keys -contains ([string]$anEvent)) ){
            return $result
        }
        
        Write-Debug ([string]$anEvent)
        Write-Debug ($null -eq $this.entries)

        $anArray = $this.entries[([string]$anEvent)]
        if( $null -eq $anArray ){
            Write-Error 'HOGEEEE!!'
        }
        ($anArray).foreach{
            $entry = [DependencyListenerEntry]$_
            $result = $entry.Perform($argarray,$workingset)
            if( $null -ne $result ){
                $result.Add($result)
            }
        }

        return($result)
    }

    [int]Count()
    {
        return ($this.entries.Count)
    }
    
    [object[]]TriggerEvent([enum]$anEvent,[array]$parameters){ 
        $result = @()
        if( -not $this.Suppress ){
            $result = $this.Perform($anEvent,$parameters,$this.WorkingSet)
        }

        return $result 
    }

}
