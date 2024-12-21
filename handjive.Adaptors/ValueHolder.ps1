#using module handjive.LimitedList


 

class ValueHolder : ValueModel{
        
    ValueHolder() : base(){
    }
    ValueHolder([object]$value) : base($value){
    }

    hidden [void]Initialize()
    {
        Write-Debug "Initializing in $this.gettype()"
        ([ValueModel]$this).Initialize()

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

        # super intitalize()
        #$this.ValueChangeValidator = [DependencyHolder]::new(1)
        #$this.ValueChangedListeners = [DependencyHolder]::new()
    <#SetValueChangingValidator([object]$listener,[scriptBlock]$aBlock){
        $this.Dependents.Add([EV_ValueModel]::ValueChanging,$listener,$aBlock)
    }
    AddValueChangedListener([object]$listener,[scriptBlock]$aBlock){
        $this.Dependents.Add([EV_ValueModel]::ValueChanged,$listener,$aBlock)
    }#>




