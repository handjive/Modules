using namespace handjive.Foundation
using namespace handjive.Adaptors

class IITest1 : EnumerableBase, handjive.Foundation.IAdaptor, IItemIndexable[object,object]{
    IITest1(){
    }

    hidden [object]get_Subject(){
        return 'HOGE'
    }
    hidden [void]set_Subject([object]$subject){}

    hidden [int]get_Count(){ return 10 }
    hidden [object]get_Item([object]$index){
        return $index.ToString()
    }
    hidden [void]set_Item([object]$index,[object]$value){
        Write-Host "[$value] set to index [$index]"
    }

    hidden [System.Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        $enumerator = [PluggableEnumerator]::new($this)
                
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
        
        $enumerator.Reset()
        return $enumerator
    }
}

$iit1 = [IITest1]::new()
Write-Host $iit1.Count
Write-Host $iit1[0]
Write-Host $iit1[0..3]
Write-Host $iit1[0,1,2]
Write-Host $iit1[0,1,-1]
$iit1.foreach{
    Write-host $_
}
$iit1[0]='HOGE'
#Write-Host $iit1[0..3,4,-1]
