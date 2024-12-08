using namespace handjive.Adaptors
import-module handjive.Adaptors -Force

$es = [Everything]::new()
$es.QueryBase = '.\'
$es.SearchString = '*.psd1'
$es.PerformQuery()

$ia = [PluggableIndexer]::new($es)
$ia.GetCountBlock = { 
    param($adaptor) 
    $adaptor.Subject.NumberOfResults 
}
$ia.GetItemBlock = { 
    param($adaptor,$index) 
    $adaptor.Subject.ResultFileNameAt($index) 
}
$ia.SetItemBlock = { param($adaptor,$index,$value) throw "Unable to set item for this object" }

<#$ia.GetEnumeratorBlock = { param($adaptor)
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
    $enumerator.Reset()


    $adaptor.Enumerator = $enumerator
}#>
Write-Host $ia['stringIndex']
Write-Host $ia.Count
Write-Host $ia[0]
Write-Host $ia[9]
write-Host '------------------------'
$ia.foreach{
    Write-Host $_
}

write-Host '------------------------'
Write-Host $ia[0,3,-1]

write-Host '------------------------'
$ia.foreach{
    Write-Host $_
}
