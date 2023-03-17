remove-module handjive.StreamAdaptor
import-module handjive.StreamAdaptor

$array = @(1..50)
Write-Host '1-50 int StreamAdaptor -Head 5'
$array | StreamAdaptor -Head 5
Write-Host ''

Write-Host '1-50 into StreamAdaptor -Tail 5'
$array | StreamAdaptor -Tail 5|write-host
Write-Host ''

Write-Host '1-50 into StreamAdaptor -Select even'
$array | StreamAdaptor -Select {
    param($elem)
    ($elem % 2) -eq 0
}    | write-host
Write-Host ''

Write-Host '1-50 into StreamAdaptor -Reject even (select odd)'
$array | StreamAdaptor -Reject {
    param($elem)
    ($elem % 2) -eq 0
} | write-host
Write-Host ''

Write-Host '1-50 into StreamAdaptor -Treat double quoted string'
$array | StreamAdaptor -Treat {
    param($elem)
    [String]::Format('"{0}"',[string]$elem)
} |write-host
Write-Host ''

Write-Host '1-50 into StreamAdaptor -Thru'
$newArray = ($array | StreamAdaptor -PassThru)
Write-Host $newArray.getType() ':' $newArray

$array | StreamAdaptor -PassThru | Write-Host

