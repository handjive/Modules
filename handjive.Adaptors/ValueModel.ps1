using namespace handjive.Adaptors

enum EV_ValueModel{
    ValueChanging; ValueChanged;
}

class ValueModel : IValueModel, IDependencyServer{
    static [object]$EventsPublished = [EV_ValueModel]

    hidden [DependencyHolder]$wpvDependents
    hidden [bool]$SuppressDependents = $false
    hidden [object]$wpvValue
    
    [HashTable]$WorkingSet

    ValueModel(){
        $this.Initialize()
    }
    ValueModel([object]$value){
        $this.Value = $value
        $this.Initialize()
    }   

    hidden [void]Initialize(){
        Write-Debug "Initializing in ValueModel"
        $this.Workingset = @{}
        $this.wpvDependents = [DependencyHolder]::new()
        $this.Dependents.Add([EV_ValueModel]::ValueChanging,$this,{ $true }) # 指定が無い時のValueChangingイベント
    }

    hidden [object]get_Events(){ return $this.gettype()::EventsPublished }
    hidden [object]get_Dependents(){ return $this.wpvDependents }
    
    hidden [object]get_Value(){ return $this.ValueUsingSubject() }
    hidden set_Value([object]$aValue){
        $oldValue = $this.ValueUsingSubject()
        $result = $this.TriggerEvent([EV_ValueModel]::ValueChanging,@($oldValue,$aValue))
        if( -not ($result -contains $false) ){
            $this.ValueUsingSubject($aValue)
            $this.TriggerEvent([EV_ValueModel]::ValueChanged,@($oldValue,$aValue))
        }
    }
    hidden [object]ValueUsingSubject(){
        return $this.wpvValue
    }
    hidden ValueUsingSubject([object]$value){
        $this.wpvValue = $value
    }

    [object[]]TriggerEvent([object]$anEvent,[array]$parameters){ 
        $result = @()
        if( !$this.SuppressDependents ){
            $result = $this.dependents.Perform($anEvent,$parameters,$this.WorkingSet)
        }

        return $result 
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


    ### Obsoletes ###
    <#SetSubjectChangingValidator([object]$listener,[scriptBlock]$aBlock){
        $this.SubjectChangingValidator.Add($listener,$aBlock)
    }
    AddSubjectChangedListener([object]$listener,[scriptBlock]$aBlock){
        $this.SubjectChangedListeners.Add($listener,$aBlock)
    }
    hidden [object]get_Subject(){
        return($this.wpvSubject)
    }
    [object]ValueUsingSubject([object]$aSubject){
        return $aSubject
    }
    ValueUsingSubject([object]$Subject,[object]$aValue){
        $this.Subject = $aValue
    }

    hidden [object]get_Value(){
        return $this.ValueUsingSubject($this.Subject)
    }

    hidden set_Subject([object]$Subject){
        $result = $this.TriggerEvent([EV_ValueModel]::SubjectChanging,$this.Subject,$Subject)
        if( -not ($result -contains $false) ){
            $oldSubject = $this.wpvSubject
            $this.wpvSubject = $Subject
            $this.TriggerEvent([EV_ValueModel]::SubjectChanged,@($oldSubject,$Subject))
        }
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
    }#>
}