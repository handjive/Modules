[CmdletBinding()]

$DebugPreference = 'Continue' 
#$DebugPreference = 'SilentlyContinue' 

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

write-output $DebugPreference

switch($args){
    1 { # Simple
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

    2{ # Traverse
        $t2 = [Test2]::new()
        $aa = [AspectAdaptor]::new($t2,'test.a')
        $aa.Value = 'a of a [Test]'

        write-output $aa.Value
        write-output $t2 $t2.Test.a
    }

    3 { # Dependency - Simply ValueChanged
        $t = [Test]::new()
        $aa = [AspectAdaptor]::new($t,'a')
        $aa.Dependents.Add([EV_ValueAdaptor]::ValueChanged,'hoge',{ param($subject,$parameters,$workingset) Write-Host $parameters })
        $aa.Value = 38
    }

    3.1 { # Dependency - ValueChanging, Reject new value
        $t = [Test]::new()
        $aa = [AspectAdaptor]::new($t,'a')
        $aa.Dependents.Add([EV_ValueAdaptor]::ValueChanging,'hoge',{ param($subject,$parameters,$workingset) (($parameters[1] % 2) -ne 0) })
        $aa.Value = 38
        Write-Host $aa.Value
        $aa.Value = 39
        Write-Host $aa.Value
    }
}