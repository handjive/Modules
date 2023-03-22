#. '.\handjive.MessageBuilder\handjive.MessageBuilder.Classes.ps1'
$scale = "0        1         2         3         4         5         6         7         8         9`n123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"

switch($args){
    0 {
        $mb = [MessageBuilder]::new()
        $mb.Append('Hoge')
        $mb.Append('tara')
        $mb.AppendFormat(@('{0} and {1}','A','B'))
        $mb.ToString()
    }
    1 { # Test for MessageHelper.ClipRightInWidth
        $mh = [MessageHelper]::new()
        #                     0        1         2         3         4         5         6         7         8         9
        #                     123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
        $result = $mh.Left('ほげhogeほげたろうgoing on!',20,'<<')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Left('ほげhogeほげたろうgだoing on!',20,'<<')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Left('ほげhoge',20,'<<')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Left('ほげhogeほ',20,'<<')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
    }
    2 {
        $mh = [MessageHelper]::new()
        $result = $mh.Right('ほげhogeほげたろうgoing on!',20,'>>')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Right('ほげhogeほげたろうgだoing on!',20,'>>')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Right('ほげhoge',20,'>>')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Right('ほげhogeほ',20,'>>')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Left('ほげhoge',20,'<<')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
        $result = $mh.Left('ほげhogeほ',20,'<<')
        $scale | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
    }
}
