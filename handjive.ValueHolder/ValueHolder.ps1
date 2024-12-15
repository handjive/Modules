#using module handjive.LimitedList




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
        if( $null -eq ($result = $this.Value ) ){
            return(&$complementBlock)
        }
        else{
            return($result)
        }
    }
}




