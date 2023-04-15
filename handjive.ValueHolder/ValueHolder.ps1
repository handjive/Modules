using module handjive.LimitedList

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

class ValueModel : handjive.IValueModel[object]{
    hidden [object]$wpvSubject

    ValueModel(){
    }
    ValueModel([object]$Subject){
        $this.wpvSubject = $Subject
    }

    [object]get_Subject(){
        return($this.wpvSubject)
    }
    set_Subject([object]$Subject){
        $oldSubject = $this.wpvSubject
        $this.wpvSubject = $Subject
        $this.SubjectChanged($oldSubject,$Subject)
    }
    
    [object]ValueUsingSubject([object]$aSubject){
        return $aSubject
    }
    ValueUsingSubject([object]$Subject,[object]$aValue){
        $this.Subject = $aValue
    }

    [object]Value(){
        return $this.ValueUsingSubject($this.Subject)
    }
    Value([object]$aValue){
        if( $this.ValueChanging($this.Value(),$aValue) ){
            $this.ValueUsingSubject($this.Subject,$aValue)
            $this.ValueChanged()
        }
    }
    
    SubjectChanged([object]$old,[object]$new){
    }

    [bool]ValueChanging([object]$Subject,[object]$aValue){
        return $true
    }
    ValueChanged(){
    }
}

class ValueHolder{
    [object]$wpvSubject
    [DependencyHolder]$ValueChangeValidator
    [DependencyHolder]$ValueChangedListeners
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
        $this.ValueChangeValidator = [DependencyHolder]::new(1)
        $this.ValueChangedListeners = [DependencyHolder]::new()
    }

    [object]Subject(){
        return ($this.wpvSubject)
    }
    Subject([object]$newSubject)
    {
        $this.wpvSubject = $newSubject
    }

    SetValueChangingValidator([object]$listener,[scriptBlock]$aBlock){
        $this.ValueChangeValidator.Add($listener,$aBlock)
    }
    AddValueChangedListener([object]$listener,[scriptBlock]$aBlock){
        $this.ValueChangedListeners.Add($listener,$aBlock)
    }

    [bool]ValueChanging($current,$new){
        return ($this.ValueChangeValidator.Perform(@($current,$new),$this.WorkingSet,{$true}))
    }
    [object]ValueChanged($newSubject){
        $this.ValueChangedListeners.Perform(@( $newSubject ),$this.WorkingSet,{})
        return($newSubject)
    }
    [object]Value()
    {
        return ($this.Subject())
    }
    [object]ValueOr([ScriptBlock]$complementBlock){
        if( $null -eq ($result = $this.Value()) ){
            return(&$complementBlock)
        }
        else{
            return($result)
        }
    }

    [object]Value([object]$newSubject){
        if( $this.ValueChanging($this.Subject(),$newSubject) ){
            $this.Subject($newSubject)
            return ($this.ValueChanged($newSubject))
        }
        else{
            return ($this.Subject())
        }
    }
}


