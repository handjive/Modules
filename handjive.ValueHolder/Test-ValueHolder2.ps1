switch($args){
    0 {
        $dh = [DependencyHolder]::new()
        $dh.Add(@(1..3),{
            param($arg,$additionalArgs)
            $arg.foreach{
                [String]::Format('{0}({1})',$_,$_.gettype()) | Write-Host
            }
            $additionalArgs.foreach{
                [String]::Format('{0}({1})',$_,$_.gettype()) | Write-Host
            }
            $false
        })
        
        $arg = @( 'hoge' )
        $result = $dh.Perform($arg)
        $arg | Write-Host
        $result |write-host
    }
    1 {
        $vh = [ValueHolder2]::new('')
        $vh.SetSubjectChangingValidator(@(),{
            param($v1,$v2)
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
        $vh.AddSubjectChangedLister(@($mb),{
            param($v1,$v2)
            $v2[0].AppendLine($v1[0])
        })
        $vh.AddSubjectChangedLister(@(),{
            param($v1,$v2)
            [string]::format('Subject changed! new subject is"{0}"',$v1[0])
        })

        $vh.Value('Hoge')
        @(1..10).foreach{ $vh.Value($_) }
        $vh.Value('Tara')

        $mb.Flush()
    }
}
