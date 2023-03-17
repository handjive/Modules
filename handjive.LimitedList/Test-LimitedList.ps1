using module handjive.LimitedList

$a = [LimitedList]::new(5)
$a.OnElementPushout={
    param($element)
    [String]::format('Element pushedout! "{0}"',$element) | write-Host
}
@( 1..20 ).foreach{
    $a.add($_)
    [String]::Format('$a has {0} object(s) => @( {1} )',$a.Count,($a -join(','))) | write-host
}

$a.Values() | Write-Output

