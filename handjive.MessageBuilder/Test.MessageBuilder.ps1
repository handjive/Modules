. '.\handjive.MessageBuilder\handjive.MessageBuilder.ps1'

$mb = [MessageBuilder]::new()
$mb.Append('Hoge')
$mb.Append('tara')
$mb.AppendFormat(@('{0} and {1}','A','B'))
$mb.ToString()