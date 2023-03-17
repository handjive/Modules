import-module handjive.Get-KeyboardResponse -Force

switch($args){
    1 {
        Write-Host $_ '<< Numerical input only >>'
        Get-KeyboardResponse -Prompt 'Enter valid key' -AcceptNumber -Min 1 -Max 10
    }
    2 {
        Write-Host $_ '<< Empty(ENTER only) or a,b,c,d >>'
        Get-KeyboardResponse 'Prompt' -AcceptEnter -Valid 'abcd'
    }
    3 {
        Write-Host $_ '<< Accept ENTER only, -20 to 20 number, qwer chars'
        Get-KeyboardResponse 'Prompt' -AcceptEnter -AcceptNumber -Min -20 -Max 20 -Valid 'qwer'
    }
    4 {
        Write-Host $_ '<< YN only >>'
        Get-KeyboardResponse 'Prompt ' -Valid 'YN'
    }
    5 {
        $response = Get-KeyboardResponse 'Prompt' -AcceptEnter -AcceptNumber -Max 20 -Valid 'qwer'
        [String]::Format('"{0}"',$response)
        Get-KeyboardResponse 'Prompt' -AcceptEnter -AcceptNumber -Min -20 -Valid 'qwer' 
    }
    6 {
        Get-KeyboardResponse '' -AcceptEnter -AcceptNumber -Min -20 -Valid 'qwer' 
    }
}
