#using module handjive.LimitedList

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

class ValueModel : handjive.IValueModel[object]{
    hidden [DependencyHolder]$SubjectChangingListeners
    hidden [DependencyHolder]$SubjectChangedListeners
    hidden [bool]$SuppressDependents = $false
    hidden [object]$wpvSubject
    
    [HashTable]$WorkingSet

    hidden [void]Initialize(){
        $this.Workingset = @{}
        $this.SubjectChangingListeners = [DependencyHolder]::new(1)
        $this.SubjectChangedListeners = [DependencyHolder]::new()
    }

    ValueModel(){
        $this.Initialize()
    }
    ValueModel([object]$Subject){
        $this.wpvSubject = $Subject
        $this.Initialize()
    }

    [object]get_Subject(){
        return($this.wpvSubject)
    }
    set_Subject([object]$Subject){
        if( $this.SubjectChanging($this.Subject,$Subject) ){
            $oldSubject = $this.wpvSubject
            $this.wpvSubject = $Subject
            $this.SubjectChanged($oldSubject,$Subject)
        }
    }
    
    SuppressDependentsDo([ScriptBlock]$aBlock){
        $this.SuppressDependents = $true
        try{
            &$aBlock
        }
        finally{
            $this.SuppressDependents = $false
        }
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
            $this.ValueChanged($aValue)
        }
    }
    SetSubjectChangingValidator([object]$listener,[scriptBlock]$aBlock){
        $this.SubjectChangingValidator.Add($listener,$aBlock)
    }
    AddSubjectChangedListener([object]$listener,[scriptBlock]$aBlock){
        $this.SubjectChangedListeners.Add($listener,$aBlock)
    }

    [bool]SubjectChanging([object]$current,[object]$new){
        if( !$this.SuppressDependents ){
            return($this.SubjectChangingListeners.Perform(@($current,$new),$this.Workingset,{$true}))
        }
        else{
            return $true
        }
    }

    SubjectChanged([object]$old,[object]$new){
        if( !$this.SuppressDependents ){
            $this.SubjectChangedListeners.Perform(@( $old,$new ),$this.WorkingSet,{})|out-null
        }
    }

    [bool]ValueChanging([object]$Subject,[object]$aValue){
        return $true
    }

    ValueChanged([object]$newValue){
    }
}

class ValueHolder : ValueModel{
    [DependencyHolder]$ValueChangeValidator
    [DependencyHolder]$ValueChangedListeners
        
    hidden [void]Initialize()
    {
        ([ValueModel]$this).Initialize()
        $this.ValueChangeValidator = [DependencyHolder]::new(1)
        $this.ValueChangedListeners = [DependencyHolder]::new()
    }

    ValueHolder() : base(){
    }
    ValueHolder([object]$subject) : base($subject){
    }

    SetValueChangingValidator([object]$listener,[scriptBlock]$aBlock){
        $this.ValueChangeValidator.Add($listener,$aBlock)
    }
    AddValueChangedListener([object]$listener,[scriptBlock]$aBlock){
        $this.ValueChangedListeners.Add($listener,$aBlock)
    }

    ValueUsingSubject([object]$subject,[object]$value){
        $this.wpvSubject = $value
    }

    [bool]ValueChanging($current,$new){
        if( !$this.SuppressDependents ){
            return ($this.ValueChangeValidator.Perform(@($current,$new),$this.WorkingSet,{$true}))
        }
        else{
            return $true
        }
    }
    ValueChanged($newValue){
        if( !$this.SuppressDependents ){
            $this.ValueChangedListeners.Perform(@( $newValue ),$this.WorkingSet,{})
        }
    }

    [object]ValueOr([ScriptBlock]$complementBlock){
        if( $null -eq ($result = $this.Value()) ){
            return(&$complementBlock)
        }
        else{
            return($result)
        }
    }
}


class AspectAdaptor : ValueModel{
    [string]$Aspect

    hidden [void]Initialize(){
        ([ValueModel]$this).Initialize()
    }
    
    AspectAdaptor([object]$subject,[string]$aspect) : base($subject){
        $this.Aspect = $aspect
    }

    [object]ValueUsingSubject([object]$subject){
        $aValue = ($subject).($this.Aspect)
        return ($aValue)
    }
    ValueUsingSubject([object]$subject,[object]$value){
        ($this.Subject).($this.Aspect) = $value
    }
}

class PluggableAdaptor : ValueModel {
    [ScriptBlock]$GetValueBlock
    [ScriptBlock]$SetValueBlock

    hidden [void]Initialize(){
        ([ValueModel]$this).Initialize()
    }

    PluggableAdaptor([object]$Subject,[ScriptBlock]$GetValueBlock,[ScriptBlock]$SetValueBlock) : base($Subject){
        $this.GetValueBlock = $GetValueBlock
        $this.SetValueBlock = $SetValueBlock
    }

    [object]ValueUsingSubject([object]$Subject){
        return (&$this.GetValueBlock $Subject)
    }
    ValueUsingSubject([object]$Subject,[object]$Value){
        &$this.SetValueBlock $Subject $Value
    }
}


