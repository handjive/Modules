using namespace System.Collections
using namespace handjive.Foundation
using namespace handjive.Adaptors
using namespace handjive.Collections

using module handjive.Foundation

enum EV_PluggableIndexer{ SubjectChanging; SubjectChanged; }

class PluggableIndexer : PluggableIndexerBase, IDependencyServer{
    [DependencyHolder]$pvDependents
    [ScriptBlock]$BuildEnumeratorBlock = { 
        param($adaptor) 
        $adaptor.Enumerator = [PluggableEnumerator]::Empty()
    }
    [ScriptBlock]$GetCountBlock = { param($adaptor) $adaptor.Subject.Count }
    [ScriptBlock]$GetItemBlock = { param($adaptor,$index) $adaptor.Subject[$index] }
    [ScriptBlock]$SetItemBlock = { param($adaptor,$index,$value) $adaptor.Subject[$index] = $value }

    [object]$pvSubject
    [PluggableEnumerator]$Enumerator

    PluggableIndexer(){
        $this.pvSubject = $null
        $this.Initialize()
    }
    PluggableIndexer([object]$subject){
        $this.pvSubject = $subject
        $this.Initialize()
    }

    hidden Initialize(){
        $this.pvDependents = [DependencyHolder]::new()
    }
    hidden [object]get_Dependents(){ return $this.pvDependents }
    hidden [object]get_Events(){ return [EV_PluggableIndexer] }

    hidden [void]ConstructDefaultBuildEnumeratorBlock()
    {
        $this.BuildEnumeratorBlock = {
            param($adaptor) # $adaptorは自分自身
            if( $null -eq $adaptor.Enumerator ){
                if( $null -eq $adaptor.Subject ){
                    $enumerator = [PluggableEnumerator]::Empty()
                }
                else{
                    $enumerator = [PluggableEnumerator]::new($adaptor)
                
                    $enumerator.OnMoveNextBlock = { 
                        param($substance,$workingset)
                        $workingset.Locator++
                        $workingset.Locator -lt $substance.Count
                    }
                    $enumerator.OnCurrentBlock = { 
                        param($substance,$workingset)
                        Write-Output ($substance[$workingset.Locator])
                    }
                    $enumerator.OnResetBlock = {
                        param($substance,$workingset)
                        $workingset.Locator = -1
                    }
                }
                $adaptor.Enumerator = $enumerator
            }
        }
    }

    hidden [object]PSget_Subject(){
        if( $null -eq $this.pvSubject ){
            throw [handjive.Foundation.SubjectNotAssignedException]::new("Missing Subject")
        }
        return $this.pvSubject 
    }
    hidden PSset_Subject([object]$subject){ 
        $result = $this.TriggerEvent([EV_PluggableIndexer]::SubjectChanging,@($this.pvSubject,$subject))
        if( -not ($result -contains $false) ){
            $oldSubject = $this.pvSubject
            $this.pvSubject = $subject 
            $this.TriggerEvent([EV_PluggableIndexer]::SubjectChanged,@($oldSubject,$this.pvSubject))
            $this.ConstructDefaultBuildEnumeratorBlock()
        }
    }

    [Generic.IEnumerator[object]]PSGetEnumerator(){
        &$this.BuildEnumeratorBlock $this
        $this.Enumerator.PSReset()
        return $this.Enumerator
    }

    [int]PSget_Count(){
        return (&$this.GetCountBlock $this)
    }

    [object]PSget_Item([object]$index){
        return (&$this.GetItemBlock $this ([IndexRegulator]::ActualIndexFrom(0,$this.PSget_Count(),$index)))
    }

    PSset_Item([object]$index,[object]$value){
        &$this.SetItemBlock $this ([IndexRegulator]::ActualIndexFrom(0,$this.PSget_Count(),$index)) $value
    }

    [object[]]TriggerEvent([object]$anEvent,[array]$parameters){ 
        return ($this.Dependents.TriggerEvent($anEvent,$parameters))
    }
}

