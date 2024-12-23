
class PluggableAdaptor : ValueAdaptor {
    [ScriptBlock]$GetValueBlock
    [ScriptBlock]$SetValueBlock

    PluggableAdaptor([object]$Subject,[ScriptBlock]$GetValueBlock,[ScriptBlock]$SetValueBlock) : base($Subject){
        $this.GetValueBlock = $GetValueBlock
        $this.SetValueBlock = $SetValueBlock
    }

    hidden [void]Initialize(){
        ([ValueAdaptor]$this).Initialize()
    }

    [object]ValueUsingSubject(){
        return (&$this.GetValueBlock $this.Subject)
    }
    ValueUsingSubject([object]$Value){
        &$this.SetValueBlock $this.Subject $Value
    }
}

