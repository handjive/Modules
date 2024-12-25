#using namespace System.Collections.Specialized
using namespace System.Collections.Generic
using namespace System.Collections
using namespace handjive.Foundation

class DependencyListenerEntry : IDependencyListenerEntry{
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
class DependencyHolder : IDependencyHolder{
    [object] static $DefaultElementClass = [DependencyListenerEntry]

    [object]$ElementClass
    [hashtable]$WorkingSet = @{}
    [bool]$Supress = $false
    [Dictionary[string,List[object]]]$pvSubscribers 

    DependencyHolder(){
        #$this.entries = [Dictionary[string,List[DependencyListenerEntry]]]::new[string,List[DependencyListenerEntry]]()
    }

    hidden [Dictionary[string,List[object]]]get_Subscribers()
    {
        if( $null -eq $this.pvSubscribers ){
            $this.pvSubscribers = [Dictionary[string,List[object]]]::new()
        }
        return $this.pvSubscribers
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
        $dict = [Dictionary[string,List[object]]]::new()
        $dict.Add([string]$anEvent,[List[object]]::new())

        if( $null -eq $anEvent  ){
            return
        }
        
        $aKey = [string]$anEvent
        $aList = [List[object]]::new()
        
        if( -not ($this.Subscribers.Keys -contains $aKey) ){
            $this.Subscribers.Add($aKey,$aList)
        }
        else{
            $aList = $this.Subscribers[$aKey]
        }

        $elem = $this.NewElement()
        $elem.Listener = $listener
        $elem.ScriptBlock = $aBlock
        $aList.Add($elem)
    }

    hidden [object[]]Perform([enum]$anEvent,[object]$argArray,[hashtable]$workingset){
        if( $null -eq $anEvent  ){
            return @()
        }
        $aKey = [string]$anEvent
        $results = [ArrayList]::new()

        # イベントのサブスクライバがいなければ終了
        if( -not ($this.Subscribers.keys -contains $aKey) ){
            return $results
        }
        
        $anArray = $this.Subscribers[$aKey]
        if( $null -eq $anArray ){
            Write-Error 'HOGEEEE!!'
        }
        ($anArray).foreach{
            param([DependencyListenerEntry]$entry)
            $result = $entry.Perform($argarray,$workingset)
            if( $null -ne $result ){
                $results.Add($result)
            }
        }

        return($results)
    }

    [int]Count()
    {
        $result = 0
        $this.pvSubscribers.Values.foreach{
            $result = $result + $_.Count
        }
        return $result
    }
    
    [object[]]TriggerEvent([enum]$anEvent,[array]$parameters){ 
        $result = $null
        if( -not $this.Suppress ){
            $result = $this.Perform($anEvent,$parameters,$this.WorkingSet)
        }

        return $result 
    }

}
