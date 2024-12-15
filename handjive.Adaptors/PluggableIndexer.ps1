using namespace System.Collections
using namespace handjive.Foundation
using namespace handjive.Adaptors
using namespace handjive.Collections
using module handjive.Foundation

class PluggableIndexer : PluggableIndexerBase{
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
        $this.Subject = $null
    }
    PluggableIndexer([object]$subject){
        $this.Subject = $subject
    }

    hidden [void]ConstructDefaultBuildBEnumeratorBlock()
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

            $adaptor.Enumerator.Reset()
        }
    }

    hidden [object]PSget_Subject(){
        if( $null -eq $this.pvSubject ){
            throw [handjive.Foundation.SubjectNotAssignedException]::new("Missing Subject")
        }
        return $this.pvSubject 
    }
    hidden PSset_Subject([object]$subject){ 
        $this.pvSubject = $subject 
        $this.ConstructDefaultBuildBEnumeratorBlock()
    }

    [Generic.IEnumerator[object]]PSGetEnumerator(){
        &$this.BuildEnumeratorBlock $this
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
}

