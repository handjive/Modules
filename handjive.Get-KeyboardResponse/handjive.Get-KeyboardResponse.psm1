function Get-KeyboardResponse{
    param(
         [Parameter(Mandatory,Position=0)][string]$Prompt
        ,[switch]$AcceptEnter
        ,[string]$Valid = ''
        ,[int]$GivingUp = 3
        ,[Parameter(ParameterSetName="AcceptNumber")][switch]$AcceptNumber
        ,[Parameter(ParameterSetName="AcceptNumber")][Nullable[int]]$Min
        ,[Parameter(ParameterSetName="AcceptNumber")][Nullable[int]]$Max
    )

    $numberBounds = [Bounds]::new($Min,$Max)
    $actualValid = $Valid.ToUpper()
    $ind1 = if( $PSCmdlet.ParameterSetName -eq "AcceptNumber" ){ $numberBounds.ToString() } else{ '' }
    $ind2 = if( '' -ne $Valid ){ ($actualValid.ToCharArray() -join '/') } else{ '' }
    $ind3 = if( $AcceptEnter ){ 'ENTER' } else{ '' }
    
    $inds = $ind1,$ind2,$ind3 | where-object { $_ -ne '' }

    $indicator = $inds -join('/')
    #[String]::Format('[ {0}{1}{2} ]',$indicator1,$indicator2,$indicator3)
    
    for($i=1; $i -le $GivingUp; $i++ ){
        $response = Read-Host ([String]::Format('{0} [{1}]',$Prompt,$indicator))

        if( $PSCmdlet.ParameterSetName -eq "AcceptNumber" ){
            try{
                $value = [int]::Parse($response)

                if( $numberBounds.Includes($value) ){
                    return [string]$value
                }
            }
            catch [FormatException] {
            }
        }

        if( $response -ne "" ){
            if( $actualValid.IndexOf($response.ToUpper()) -ne -1 ){
                return $response.ToUpper()
            }
        }
        else{
            if( $AcceptEnter ){
                return $response
            }
        }

        Write-Host ''
        Beep
        $timesToQuit = if( $i -eq $GivingUp ){ 'Quit' } else{ [String]::Format('(remain: {0}times)',$GivingUp-$i) }
        $responseToDisplay = if( $response -eq '' ){ 'Empty imput (ENTER only)'} else{ $response }
        [String]::Format('"{0}" is not acceptable, retry {1}',$responseToDisplay,$timesToQuit) | Write-Host -ForegroundColor Yellow
        Write-Host ''
        continue
    }
    
    return $null
}

Export-ModuleMember -Function '*'