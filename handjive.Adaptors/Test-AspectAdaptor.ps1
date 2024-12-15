class Test{
    [string]$a
    [string]$b
    [int]$c
}

class Test2{
    [Test]$test = [Test]::new()
    [string]$name = 'No name'
    [int]$age = 0
}

switch($args){
    1 {
        $t = [Test]::new()
        $aa = [AspectAdaptor]::new($t,'a')
        $ac = [AspectAdaptor]::new($t,'c')

        $aa.Value = 'HOGE'
        $ac.Value = 18

        Write-Host $t.a $t.b $t.c
        Write-Host "a=" ($aa.Value)
        write-host "b=" ($t.b)
        write-host "c=" ($ac.Value)
    }

    2{
        $t2 = [Test2]::new()
        $expStr = [String]::Format('param($subject,$value) $subject.{0} = $value','test.a')
        $exp = [ScriptBlock]::create($expStr)
        Invoke-Command -ScriptBlock $exp -ArgumentList @($t2,'Tara')

#        $aa = [AspectAdaptor]::new($t2,'test.a')
#        $aa.Value = 'a of a [Test]'

        write-host $t2.test.a
    }

    3{
        $t2 = [Test2]::new()
        $aa = [AspectAdaptor]::new($t2,'test.a')
        $aa.Value = 'a of a [Test]'

        write-host $aa.Value
    }
}