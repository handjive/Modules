using namespace handjive.Adaptors
using namespace handjive.Foundation

enum EV_ValueModel{
    ValueChanging; ValueChanged;
}

class ValueModel : IValueModel, IDependencyServer{
    static [object]$EventsPublished = [EV_ValueModel]

    hidden [DependencyHolder]$wpvDependents
    hidden [object]$wpvValue
    
    ValueModel(){
        $this.Initialize()
    }
    ValueModel([object]$value){
        $this.wpvValue = $value
        $this.Initialize()
    }   

    hidden [void]Initialize(){
        Write-Debug "Initializing in ValueModel"
        $this.wpvDependents = [DependencyHolder]::new()
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
        else{
            Write-Debug "Value set rejected by EventHandler: value=[$aValue]"
        }
    }
    hidden [object]ValueUsingSubject(){
        return $this.wpvValue
    }
    hidden ValueUsingSubject([object]$value){
        $this.wpvValue = $value
    }

    [object[]]TriggerEvent([object]$anEvent,[array]$parameters){ 
        return $this.Dependents.TriggerEvent($anEvent,$parameters)
    }

    SuppressDependentsDo([ScriptBlock]$aBlock){
        $this.Dependents.Supress = $true
        try{
            &$aBlock
        }
        finally{
            $this.Dependents.Suppress = $false
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