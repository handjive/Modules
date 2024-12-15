#. ("$PSScriptRoot\StringUtility.ps1")

switch($args){
    1{
        [StringUtility]::ReverseString('abcdefg') | Write-Host
        [StringUtility]::Left('1234567890',5)| Write-Host
        [StringUtility]::Left('12',5,'<<')| Write-Host
        [StringUtility]::Right('1234567890',5)| Write-Host
        [StringUtility]::Right('12',5,'>>')| Write-Host
        [StringUtility]::SizeInByte('ほげほげhogeたろう')
        [StringUtility]::SizeInByte('ほげほげhogeたろう',[EncoderName]::utf_8)
    }
}