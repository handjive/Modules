switch($args){
    1{
        $line = '-' * 20

        $nominator = {
            param($elem)
            ($elem % 2 ) -eq 0
        }
        
        Write-Host $line ' Select even'
        CollectionOperator @( 1..10 ) -Select $nominator
        
        Write-Host $line ' Select even(Pipeline)'
        @( 1..10 ) | CollectionOperator -Select $nominator
        
        $modifier = {
            param($elem)
            '"'+[string]$elem+'"'
        }
        Write-Host $line ' Collect double quoted'
        CollectionOperator @( 1..10 ) -Collect $modifier
        
        Write-Host $line ' Collect double quoted(Pipeline)'
        @( 1..10 ) | CollectionOperator -Collect $modifier
        
        Write-Host $line ' Reject even (select odd)'
        CollectionOperator @( 1..10 ) -Reject $nominator
        
        $dispatcher = {
            param($container,$elem)
            if( ($elem % 2) -eq 0 ){    #even
                $container['even']+=$elem
            }
            else{
                $container['odd']+=$elem
            }
        }
        Write-Host $line ' Inject:Into'
        CollectionOperator @( 1..10 ) -Inject @{ even=@(); odd=@() } -into $dispatcher
        
        Write-Host $line ' At:ifAbsent:'
        CollectionOperator @( 1..10 ) -At 11 -ifAbsent { -10 }
        
        Write-Host $line ' detect:ifNone:'
        CollectionOperator @( 1..10 ) -Detect {
            param($elem)
            $elem -eq 3
        } -ifNone { -1 }
        
        CollectionOperator @( 1..10 ) -Detect {
            param($elem)
            $elem -eq 11
        } -ifNone { -1 }
    }

    2 {
        $result = CollectionOperator @(1..10) -inject 0 -into {
            $args[0]+$args[1] 
        }
        Write-Host $result
    }
}



