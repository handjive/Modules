using namespace System.Collections
using namespace handjive.Foundation
using namespace handjive.Adaptors
using namespace handjive.Collections
using module handjive.Collections

class PluggableIndexer : handjive.Collections.EnumerableBase, IIndexAdaptor[object,object]{
    [ScriptBlock]$GetEnumeratorBlock = { 
        param($adaptor) 
        $adaptor.Enumerator = [PluggableEnumerator]::Empty()
    }
    [ScriptBlock]$GetCountBlock = { param($adaptor) $adaptor.Subject.Count }
    [ScriptBlock]$GetItemBlock = { param($adaptor,$index) $adaptor.Subject[$index] }
    [ScriptBlock]$SetItemBlock = { param($adaptor,$index,$value) $adaptor.Subject[$index] = $value }

    [object]$Subject
    [PluggableEnumerator]$Enumerator

    PluggableIndexer(){
        $this.Initialize()
    }
    PluggableIndexer([object]$subject){
        $this.Subject = $subject
        $this.Initialize()
    }

    hidden [void]Initialize()
    {
        $this.GetEnumeratorBlock = {
            param($adaptor) # $adaptorは自分自身
            if( $null -eq $adaptor.Enumerator ){
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
          
                $adaptor.Enumerator = $enumerator
            }

            $adaptor.Enumerator.Reset()
        }
    }

    [Generic.IEnumerator[object]]PSGetEnumerator(){
        &$this.GetEnumeratorBlock $this
        return $this.Enumerator
    }

    [int]get_Count(){
        return (&$this.GetCountBlock $this)
    }

    [object]get_Item([object]$index){
        return (&$this.GetItemBlock $this $index)
    }

    set_Item([object]$index,[object]$value){
        &$this.SetItemBlock $this $index $value
    }
}


