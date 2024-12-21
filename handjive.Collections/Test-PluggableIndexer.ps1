using namespace handjive.Adaptors
import-module handjive.Adaptors -force
$ErrorActionPreference = 'Stop'

$es = [Everything]::new()
$es.QueryBase = '.\'
$es.SearchString = '*.psd1'
$es.PerformQuery()

switch($args){
    1 {
        $ia = [PluggableIndexer]::new($es)
        $ia.Subject = $null
        Write-Host "$ErrorActionPreference"
        try{
            Write-Host $ia.Subject
            #throw [handjive.Foundation.SubjectNotAssignedException]::new("HOGEEEEEE!")
        }
        catch {
            Write-Error $PSItem.ToString()
        }
    }
    2 {
        $ia = [PluggableIndexer]::new($es)
        $ia.GetCountBlock = { 
            param($adaptor) 
            $adaptor.Subject.NumberOfResults 
        }
        $ia.GetItemBlock = { 
            param($adaptor,$index) 
            Write-Host "Specified index=" $index
            $adaptor.Subject.ResultFileNameAt($index) 
        }
        $ia.SetItemBlock = { 
            param($adaptor,$index,$value) 
            write-host "[$value] into [$index]"
            throw "HOGEEEE!!: Unable to set item for this object" 
        }

        write-Host '----------[ Enumerate all ]--------------'
        $line = 0
        $ia.foreach{
            Write-Host "$line = " $_
            $line++
        }
        Write-Host "----------------------"
        Write-Host "Subject = " $ia.Subject
        Write-Host "Count=" $ia.Count
        Write-Host "0,1,3 = " $ia[0,1,3]
        Write-Host "1..4 = " $ia[1..4]
        Write-Host "9 = " $ia[9]
        Write-Host "Indexing by a string = " $ia['stringIndex']
        $ia[5] = 'HOGE'

        Write-Host "0,3,-1 = " $ia[0,3,-1]
        write-Host '------------------------'
        Write-Host "-1..0 = " $ia[-1..0]
        Write-Host "5..-1 = "$ia[5..-1]
    }
}

