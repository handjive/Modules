using namespace handjive
using namespace handjive.Foundation

enum EV_ValueAdaptor{ ValueChanging; ValueChanged; SubjectChanging; SubjectChanged; }

class ValueAdaptor : ValueModel, IAdaptor{
    static [object]$EventsPublished = [EV_ValueAdaptor]

    [object]$wpvSubject

    ValueAdaptor([object]$subject) : base(){
        $this.wpvSubject = $subject
        #$this.Initialize()
    }
    hidden Initialize(){
        ([ValueModel]$this).Initialize()
        Write-Debug "Initializing in ValueAdaptor"
        $this.wpvDependents = [DependencyHolder]::new()
        $this.wpvDependents.Add([EV_ValueAdaptor]::ValueChanging,$this,{ $true })
        $this.wpvDependents.Add([EV_ValueAdaptor]::SubjectChanging,$this,{ $true })
    }

    hidden [object]get_Subject(){ return $this.wpvSubject }
    hidden set_Subject([object]$subject){
        $result = $this.TriggerEvent([EV_ValueAdaptor]::SubjectChanging,$this.wpvSubject,@($subject))
        if( -not ($result -contains $false) ){
            $oldSubject = $this.wpvSubject
            $this.wpvSubject = $subject
            $this.TriggerEvent([EV_ValueAdaptor]::SubjectChanged,@($oldSubject,$subject))
        }
    }
    hidden set_Value([object]$aValue){
        $oldValue = $this.ValueUsingSubject()
        $result = $this.TriggerEvent([EV_ValueAdaptor]::ValueChanging,@($oldValue,$aValue))
        if( -not ($result -contains $false) ){
            $this.ValueUsingSubject($aValue)
            $this.TriggerEvent([EV_ValueAdaptor]::ValueChanged,@($oldValue,$aValue))
        }
    }

    hidden [object]ValueUsingSubject(){
        throw [handjive.Foundation.SubclassResponsibilityException]::new()
    }

    hidden ValueUsingSubject([object]$value){
        throw [handjive.Foundation.SubclassResponsibilityException]::new()
    }
}