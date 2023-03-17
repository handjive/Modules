switch($args){
    1 {
        $array = @(1..50)
        Write-Host '1-50 int StreamAdaptor -Head 5'
        $array | StreamAdaptor -Head 5
        Write-Host ''

        Write-Host '1-50 into StreamAdaptor -Tail 5'
        $array | StreamAdaptor -Tail 5|write-host
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
    }
    2 {
        Write-Host '<< 1-50 into StreamAdaptor -Select even >>'
        $array | StreamAdaptor -Select {
            param($elem)
            ($elem % 2) -eq 0
        }    | write-host
        Write-Host ''

        Write-Host '<< 1-50 into StreamAdaptor -Reject even (select odd) >>'
        $array | StreamAdaptor -Reject {
            param($elem)
            ($elem % 2) -eq 0
        } | write-host
        Write-Host ''
   }
   3 {
        write-host '<< 1-50 from commandline(not stream), Select even >>'
        StreamAdaptor @(1..50) -Select {
            ($args[0] % 2) -eq 0 } | write-host
   }
   3.1 {
        @(1..50) | StreamAdaptor -Select {
            ($args[0] % 2) -eq 0 } | write-host
   }
   4 {
        write-host 'Head' ('='*120)
        StreamAdaptor @(1..50) -Head 10 | write-host
        write-host ('-'*40)
        @(1..50) | StreamAdaptor -Head 10 | write-host

        write-host 'Tail' ('='*120)
        StreamAdaptor @(1..50) -Tail 10 | write-host
        write-host ('-'*40)
        @(1..50) | StreamAdaptor -Tail 10 | write-host

        write-host 'Select' ('='*120)
        StreamAdaptor @(1..50) -Select { ($args[0] % 2) -eq 0 } | write-host
        write-host ('-'*40)
        @(1..50) | StreamAdaptor -Select { ($args[0] % 2) -eq 0 } | write-host
        
        write-host 'Reject' ('='*120)
        StreamAdaptor @(1..50) -Reject { ($args[0] % 2) -eq 0 } | write-host
        write-host ('-'*40)
        @(1..50) | StreamAdaptor -Reject { ($args[0] % 2) -eq 0 } | write-host

        write-host 'Treat' ('='*120)
        StreamAdaptor @(1..50) -Treat { [String]::Format('### {0} ###',$args[0]) } | write-host
        write-host '-'*40
        @(1..50) | StreamAdaptor -Treat { [String]::Format('### {0} ###',$args[0]) } | write-host

        write-host 'PassThru' ('='*120)
        StreamAdaptor @(1..50) -PassThru | write-host
        write-host ('-'*40)
        @(1..50) | StreamAdaptor -PassThru | write-host
   }
   5 {
        @(1..10) | StreamAdaptor -Inject 0 -into {
            param($lastResult,$elem)
            $lastResult + $elem
        } | write-Host

        StreamAdaptor @(1..10) -Inject 0 -into {
            param($lastResult,$elem)
            $lastResult + $elem
        } | write-Host
   }
}
