#using module handjive.Foundation

param([switch]$Step2)
$DebugPreference = 'Continue'

#import-module handjive.Foundation

<#class Test1{
    $One
    $Two
    $Three
}#>
$error.Clear()

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
        $vm = [ValueModel]::new()
        $vm.dependents.Add([EV_ValueModel]::ValueChanging,'a',{ param([object]$subject,[object[]]$argarray) Write-Host "Subject=$subject, Args=($argarray)" $true })
        $vm.dependents.Add([EV_ValueModel]::ValueChanged,'b',{ param([object]$subject,[object[]]$argarray) Write-Host "Subject=$subject, Args=($argarray)" $true })
        #$vm.dependents.Add([EV_ValueModel]::SubjectChanged,'b',{ param([object]$subject,[object[]]$argarray) Write-Host "$subject=$subject, Args=($argarray)" })
        $results = $vm.TriggerEvent([EV_ValueModel]::ValueChanged,@( 1,2,3 ))
        Write-Output $results
    }

    2 {
        $vh = [ValueHolder]::new()
        $vh.Dependents.Add([EV_ValueModel]::ValueChanging,{ 
            param([object]$subject,[object[]]$argarray)
            Write-Host "OnSubjectChanging"
            Write-Host "Subject=$subject"
            Write-Host "arguments=$argarray"
            $argarray[1].Length -ge 4
        })
        $vh.Dependents.Add([EV_ValueModel]::ValueChanged,{ 
            param([object]$subject,[object[]]$argarray)
            Write-Host "OnSubjectChang[ed]"
            Write-Host "Subject=$subject"
            Write-Host "arguments=$argarray"
            'TARA'
        })
        $vh.Value = 'Oh!'
        $vh.Value = 'Doodledo!'
    }
}
return

<#
if( $Step2 ){
}
else{
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

            $vh.Value = 'Hoge'
            @(1..5).foreach{ $vh.Value = $_ }
            $vh.Value = 'Tara'

            $mb.Flush()
        }
        2 {
            $a = [AspectAdaptor]::new(($t1 = [Test1]::new()),'One')

            $a.Value = 'hogee!'
            $a.Value,$t1.One | Write-Host

            $b = [PluggableAdaptor]::new($t1,{ $args[0].Two },{$args[0].Two = $args[1]})
            $b.Value = 'Tara'
            $b.Value,$t1.Two | write-host
        }
        3 {
            $vh1 = [ValueHolder]::new()
            $vh2 = [ValueHolder]::new()
            $dummyContext = @{ vh1=$vh1; vh2=$vh2; }

            $vh1.AddValueChangedListener($dummyContext,{
                param($listener,$args1,$args2,$workingset)
                $listener.vh2.Subject = $args1[1]
            })
            $vh2.AddValueChangedListener($dummyContext,{
                param($listener,$args1,$args2,$workingset)
                $listener.vh1.Subject = $args1[1]
            })

            Trace-Script -ScriptBlock {
                @(1..1000).foreach{
                    $vh1.Value = 'Hoge'
                    $vh2.Value = 'Tara'
                }
            }
            (Get-LatestTrace).Top50Duration
        }
        4 {
            $es = [Everything]::new()
            $es.Reset()
            Trace-Script -ScriptBlock { $es.PerformQuery('*.ps1') }
            $trace1 = Get-LatestTrace
            $trace1.Top50Durations

            $enumer = $es.ResultsEnumerable()
            Trace-Script -ScriptBlock { 
                $es.Results
            }
            $trace2 = Get-LatestTrace
            $trace2.Top50Durations
        }
        5 {
            [Everything]::Search('c:\users\handjive\Documents\書架\BooksArchive','ダンジョン')
        }
    }
}
    #>