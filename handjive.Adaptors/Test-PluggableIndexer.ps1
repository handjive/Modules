using namespace handjive.Adaptors
import-module handjive.Adaptors -force

[CmdletBinding()]

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
$ia.SetItemBlock = { 
    param($adaptor,$index,$value) 
    write-host "[$value] into [$index]"
    #throw "Unable to set item for this object" 
}

Write-Host $ia.Subject
$ia.Subject = $null
Write-Host "$ErrorActionPreference"
$ErrorActionPreference = 'Stop'
try{
    Write-Host $ia.Subject
    #throw [handjive.Foundation.SubjectNotAssignedException]::new("HOGEEEEEE!")
}
catch {
    Write-Error $PSItem.ToString()
}

$ia.Subject = $es
Write-Host $ia['stringIndex']
Write-Host $ia.Count
Write-Host $ia[0,1,3]
Write-Host $ia[1..4]
Write-Host $ia[9]
$ia[5] = 'HOGE'

write-Host '------------------------'
$ia.foreach{
    Write-Host $_
}

write-Host '------------------------'
Write-Host $ia[0,3,-1]
Write-Host $ia['stringIndex']
Write-Host $ia.Count
Write-Host $ia[0]
Write-Host $ia[9]

write-Host '------------------------'
Write-Host $ia[-1..0]


write-Host '------------------------'
$ia.foreach{
    Write-Host $_
}
