using module handjive.ValueHolder

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

