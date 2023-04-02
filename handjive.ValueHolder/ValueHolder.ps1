using module handjive.LimitedList

class DependencyListenerEntry{
    [scriptBlock]$ScriptBlock
    [object[]]$AdditionalArguments

    DependencyListenerEntry(){

    }

    DependencyListenerEntry([scriptBlock]$aBlock,[object[]]$AdditionalArguments){
        $this.ScriptBlock = $aBlock
        $this.Arguments = $AdditionalArguments
    }

    [object]Perform([object]$arguments,[hashtable]$workingset){
        return (&$this.ScriptBlock $arguments $this.AdditionalArguments $workingset )
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
    
    Add([object[]]$additionalArgs,[scriptBlock]$aBlock){
        $elem = $this.NewElement()
        $elem.ScriptBlock = $aBlock
        $elem.AdditionalArguments = $additionalArgs
        $this.clients.Add($elem)
    }

    [object]Perform([object]$argArray,[hashtable]$workingset,[scriptBlock]$ifEmpty){
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

class ValueHolder{
    [object]$wpvSubject
    [DependencyHolder]$SubjectChangeValidator
    [DependencyHolder]$SubjectChangeListeners
    [HashTable]$WorkingSet
        
    ValueHolder(){
        $this.Initialize()
    }
    ValueHolder([object]$subject){
        $this.Initialize()
        $this.Subject($subject)
    }

    initialize()
    {
        $this.Subject($null)
        $this.WorkingSet = @{}
        $this.SubjectChangeValidator = [DependencyHolder]::new(1)
        $this.SubjectChangeListeners = [DependencyHolder]::new()
    }

    [object]Subject(){
        return ($this.wpvSubject)
    }
    Subject([object]$newSubject)
    {
        $this.wpvSubject = $newSubject
    }

    SetSubjectChangingValidator([object[]]$additionalArgs,[scriptBlock]$aBlock){
        $this.SubjectChangeValidator.Add($additionalArgs,$aBlock)
    }
    AddSubjectChangedLister($listener,[scriptBlock]$aBlock){
        $this.SubjectChangeListeners.Add($listener,$aBlock)
    }

    [bool]SubjectChanging($current,$new){
        return ($this.SubjectChangeValidator.Perform(@($current,$new),$this.WorkingSet,{$true}))
    }
    [object]SubjectChanged($newSubject){
        $this.SubjectChangeListeners.Perform(@( $newSubject ),$this.WorkingSet,{})
        return($newSubject)
    }
    [object]Value()
    {
        return ($this.Subject())
    }
    [object]Value([object]$newSubject){
        if( $this.SubjectChanging($this.Subject(),$newSubject) ){
            $this.Subject($newSubject)
            return ($this.SubjectChanged($newSubject))
        }
        else{
            return ($this.Subject())
        }
    }
}

