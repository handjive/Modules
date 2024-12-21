using module handjive.Adaptors
using module handjive.ChainScript

using namespace handjive.Collections

<#
# 一定範囲の整数値
#
# [Interval]::new(1,100,2)      1~100、増分2の整数(1,3,5,7....)
# [Interval]::new(-100,100,10)  -100~100、増分10の整数(-100,-90,-80...80,90,100)
#
# while($anInterval.MoveNext(){ $anInterval.Current }
# $anInterval.foreach{ ------ }
#>
class Interval : EnumerableBase, Collections.IEnumerator{
    [int]$Start
    [int]$Stop
    [int]$Step
    [bool]$Descending = $false

    [nullable[int]]$wpvCurrent
    
    Interval([int]$start,[int]$stop,[int]$step) : base(){
        $this.initialize($start,$stop,$step)
    }

    Interval([int]$start,[int]$stop) : base(){
        $this.initialize($start,$stop,1)
    }

    hidden [object]calcvalue([nullable[int]]$value,[int]$step,[int]$stop,[scriptblock]$ifOutOfRange)
    {
        if( $null -eq $value ){
            $this.wpvCurrent = $this.Start
            return($this.Current)
        }

        $newValue = $null
        if( $this.Descending ){
            $newValue = $value - $step
            if( $newValue -ge $stop ){
                return $newValue
            }
            else{
                &$ifOutOfRange
                return $null
            }
        }
        else{
            $newValue = $value + $step
            if( $newValue -le $stop ){
                return $newValue
            }
            else{
                &$ifOutOfRange
                return($null)
            }
        }
    }
    hidden [object]calcvalue(){
        $newValue = $this.calcvalue($this.Current,$this.Step,$this.Stop,{})
        return($newValue)
    }

    hidden initialize([int]$start,[int]$stop,[int]$step){
        $this.Start = $start
        $this.Stop = $stop
        $this.Step = [Math]::abs($step)

        if( $this.Start -ge $this.Stop ){
            $this.Descending = $true
        }
        $this.calcvalue($start,$step,$stop,{ throw 'Too much Step' })
    }

    [object]get_Current(){
#        write-host 'Current is ' $this.wpvCurrent
        return($this.wpvCurrent)
    }
    [bool]MoveNext(){
        $this.wpvCurrent = $this.calcvalue()
        return($null -ne $this.wpvCurrent)
    }
    Reset(){
        $this.wpvCurrent = $null
    }

    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        $enumerator = [PluggableEnumerator]::new($this)
        $enumerator.OnMoveNextBlock = {
            param($substance,$workingset)
            return $substance.MoveNext()
        }
        $enumerator.OnCurrentBlock = {
            param($substance,$workingset)
            return($substance.Current)
        }
        $enumerator.OnResetBlock = {
            param($substance,$workingset)
            $substance.Reset()
        }

        return $enumerator
    }
}