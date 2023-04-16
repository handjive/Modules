class Test1{
    $One
    $Two
    $Three
}

switch($args){
    0 {
        $dh = [DependencyHolder]::new()
        $dh.Add(@(1..3),{
            param($receiver,$args1,$additionalArgs,$workingset)
            $arg.foreach{
                [String]::Format('{0}({1})',$_,$_.gettype()) | Write-Host
            }
            $additionalArgs.foreach{
                [String]::Format('{0}({1})',$_,$_.gettype()) | Write-Host
            }
            $false
        })
        
        $arg = @( 'hoge' )
        $result = $dh.Perform($arg,@{},{})
        $arg | Write-Host
        $result |write-host
    }
    1 {
        $vh = [ValueHolder]::new('')
        $vh.SetValueChangingValidator($null,{
            param($receiver,$v1,$v2,$workingset)
            $result = $v1[1].gettype() -eq [String]
            $msg = if( $result ){
                [string]::format('Subject may change to "{0}".',$v1[1])
            }
            else{ 
                [string]::format('"{0}" rejected as new-subject',$v1[1])
            }
            $msg | Write-Host
            $result
        })

        $bukets = [Collections.ArrayList]::new()
        $mb = [MessageBuilder]::new()
        $vh.AddValueChangedListener($mb,{
            param($receiver,$v1,$v2,$workingset)
            $receiver.AppendLine($v1[0])
        })
        $vh.AddValueChangedListener($null,{
            param($receiver,$v1,$v2,$workingset)
            [string]::format('Subject changed! new subject is"{0}"',$v1[0])
        })

        $vh.Value('Hoge')
        @(1..5).foreach{ $vh.Value($_) }
        $vh.Value('Tara')

        $mb.Flush()
    }

    2 {
        $a = [AspectAdaptor]::new(($t1 = [Test1]::new()),'One')

        $a.Value('hogee!')
        $a.Value(),$t1.One | Write-Host

        $b = [PluggableAdaptor]::new($t1,{ $args[0].Two },{$args[0].Two = $args[1]})
        $b.Value('Tara')
        $b.Value(),$t1.Two | write-host
    }

}
