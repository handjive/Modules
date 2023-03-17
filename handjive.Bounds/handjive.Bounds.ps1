class Bounds{
    [object]$Start=$null
    [object]$End=$null

    Bounds($start,$end){
        $this.Start = $start
        $this.End = $end
    }

    [bool]Includes([System.IComparable]$var){
        if( $null -eq $this.Start ){
            return($var -le $this.End)
        }
        if( $null -eq $this.End ){
            return($var -ge $this.Start)
        }
        return ($var -ge $this.Start) -and ($var -le $this.End)
    }
    [bool]Excludes([System.IComparable]$var){
        return (!$this.Includes($var))
    }
    [bool]IsIncomplete()
    {
        return(($null -eq $this.Start) -or ($null -eq $this.End))
    }
    [string]ToString(){
        $startStr = if( $null -eq $this.Start){ '' } else{ [string]$this.Start}
        $endStr = if( $null -eq $this.End ){ '' } else{ [string]$this.End }

        if( ($startStr -eq '') -and ($endStr -eq '') ){
            return ''
        }
        else{
            #$result = [String]::Format('{0}~{1}',$startStr,$endStr)
            $result = "$startStr~$endStr"
            return $result
        }
    }
}