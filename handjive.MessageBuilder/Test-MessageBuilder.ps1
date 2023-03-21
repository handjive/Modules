. '.\handjive.MessageBuilder\handjive.MessageBuilder.Classes.ps1'

switch($args){
    0 {
        $mb = [MessageBuilder]::new()
        $mb.Append('Hoge')
        $mb.Append('tara')
        $mb.AppendFormat(@('{0} and {1}','A','B'))
        $mb.ToString()
    }
    1 { # Test for MessageHelper.ClipRightInWidth
        $scale = "0        1         2         3         4         5         6         7         8         9`n123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
        $mh = [MessageHelper]::new()
        #                     0        1         2         3         4         5         6         7         8         9
        #                     123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
        $result = $mh.ClipRightInWidth('ほげhogeほげたろうgoing on!',20)
        $sacle | Write-Host -ForegroundColor DarkGreen
        $result | write-Host
    }
}
