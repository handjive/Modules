#. '.\handjive.MessageBuilder\handjive.MessageBuilder.Functions.ps1'
#. '.\handjive.MessageBuilder\handjive.MessageBuilder.Classes.ps1'

[CmdletBinding()]

$mb = [MessageBuilder]::new()
$DebugPreference = "Continue"
$InformationPreference = "Continue"

switch($args){
    1 {
        # Basics
        $mb.Reset()
        $mb.IndentLevel(1)
        @(1..5) | InjectMessage $mb -OneLine -Delimiter ',' -ForegroundColor BRIGHT_BLUE -Italic
        $mb.ToString() | Set-Content -Path '.\aaa.txt'
        $mb.Flush()
        @(1..5) | InjectMessage $mb -OneLine -Delimiter ''
        $mb.Flush()
        $mb.IndentRight()
        @(1..5) | InjectMessage $mb 'Additional 1 ' 'Additional 2' 'Additional 3' -Bold -BackgroundColor BLUE
        Write-Host '----- Write Host -----'
        $mb.ToString() | Add-Content -Path '.\aaa.txt'
        $mb.Flush()
        
        write-Host '----- Write into Warning Stream -----'
        $mb.Flush([StreamName]::Warning)

        write-host '----- Write-Into Error Stream -----'
        $mb.Flush([StreamName]::Error)

        write-host '----- Write into Debug stream -----'
        $mb.Flush([StreamName]::Debug)
    }
    2 {
        $mb.Reset()

        $mb.IndentRight()
        '----- Indent Right -----' | InjectMessage $mb
        @(1..5) | InjectMessage $mb

        $mb.IndentRight()
        '----- Indent Right -----' | InjectMessage $mb
        @(1..5) | InjectMessage $mb

        '----- Indent Right(3) -----' | InjectMessage $mb
        $mb.IndentRight(3)
        @(1..5) | InjectMessage $mb

        $mb.IndentLeft(4)
        '----- Indent left(4), input from arguments -----' | InjectMessage $mb
        InjectMessage $mb '1' '2' '3' 'a' 'b' 'c'
        $mb.Flush()
    }
    3 {
        Write-Host '----- MessageBuilder Turn inactive -----'
        $mb.Active = $false
        $mb.ResetOnFlush =$false
        InjectMessage $mb '1' '2' '3' 'a' 'b' 'c'
        $mb.Flush()
        Write-Host '----- MessageBuilder Turn active -----'
        $mb.Active = $true
        $mb.Flush()
    }
    4 {
        $mb.Reset()
        $scaleLine = '0---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----'
        write-host $scaleLine
                    

        $mb.Helper.Line(20) | InjectMessage $mb -oneline -NoNewLine -ForegroundColor Green
        $mb.Helper.Line(4,' ') | InjectMessage $mb -oneline -NoNewLine -ForegroundColor RED
        $mb.Helper.Line(20,'~') | InjectMessage $mb -ForegroundColor Yellow
        $mb.Flush()
    }
    5 {
        $scaleLine = '0---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----'
        write-host $scaleLine

        $mb = [MessageBuilder]::new()
        1,3,5 | InjectMessage $mb -Left 5 -OneLine -NoNewLine

        1,3,5 | InjectMessage $mb -Right 10 -NoNewLine
        $mb.Flush()
    }
    6 {
        $mb = [MessageBuilder]::new()
        'hogehoge' | InjectMessage $mb -ForegroundColor Yellow -Left 40
        'hogehoge' | InjectMessage $mb -ForegroundColor Yellow -Right 40 -Padding '>>'
        'Bold&Italic&Underline' | InjectMessage $mb -Bold -Italic -Underline
        'Underline'  | InjectMessage $mb -Underline 
        'Reset' | InjectMessage $mb -Reset 
        'Hide' | InjectMessage $mb -Hide 
        'Strike' | InjectMessage $mb -Strike 
        'taratara ' | InjectMessage $mb -ForegroundColor BRIGHT_YELLOW -BackgroundColor CYAN -Italic -Bold
        $mb.ToString() | Set-Content -Path aaa.txt
        $mb.Flush()
    }
    9 {
        $mb = [MessageBuilder]::new()
        'hoge {0}/{1}' | InjectMessage $mb -FormatByStream 'a' 'b' -BackgroundColor Cyan 
        $mb.Flush()
    }
    10 {
        $mb = [MessageBuilder]::new()
        'hoge' | InjectMessage $mb -Left 20 -Padding '<<' -ForegroundColor Yellow 1 2 3 -OneLine -Delimiter '|'
        'tara' | InjectMessage $mb -Right 20 -Padding '>>' -ForegroundColor Green 4 5 6
        $mb.Flush()
    }
    11 {
        $mb = [MessageBuilder]::new()
        @(1..10) | InjectMessage $mb -Format 'Value is "{0}"' 11 12 13 -Bold -Italic -Underline -Strike
        $mb.Flush()
        @(1..10) | InjectMessage $mb -Format 'Value is "{0}"' 11 12 13 -Oneline -Delimiter ','
        $mb.Flush()
    }
    12 {
        $mb = [MessageBuilder]::new()
        @(1..10) | InjectMessage $mb -Format 'Value is "{0}"' 11 12 13 -Bold -Italic -Underline -Strike
        Set-Content -Path '.\aaa.txt' -Value ($mb.ToString())
        $mb.ToString() | Set-Content -Path '.\bbb.txt'
    }

}


