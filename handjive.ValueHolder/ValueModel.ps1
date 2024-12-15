class ValueModel : handjive.IValueModel[object]{
    hidden [DependencyHolder]$SubjectChangingListeners
    hidden [DependencyHolder]$SubjectChangedListeners
    hidden [bool]$SuppressDependents = $false
    hidden [object]$wpvSubject
    hidden [object]$wpvValue
    
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

    [object]get_Value(){
        return $this.ValueUsingSubject($this.Subject)
    }
    set_Value([object]$aValue){
        if( $this.ValueChanging($this.wpvValue,$aValue) ){
            $this.wpvValue = $aValue
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