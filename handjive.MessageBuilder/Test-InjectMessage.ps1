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
        @(1..5) | InjectMessage $mb -OneLine -Delimiter ','
        $mb.Flush()
        @(1..5) | InjectMessage $mb -OneLine -Delimiter ''
        $mb.Flush()
        $mb.IndentRight()
        @(1..5) | InjectMessage $mb 'Additional 1 ' 'Additional 2' 'Additional 3'
        Write-Host '----- Write Cyan -----'
        $mb.Flush([OutputColor]::Cyan,[OutputColor]::DNS)
        
        write-Host '----- Write into Warning Stream -----'
        $mb.Flush([StreamName]::Warning)

        write-host '----- Write-Into Error Stream -----'
        $mb.Flush([StreamName]::Error)

        write-host '----- Write into Debug stream -----'
        $mb.Flush([StreamName]::Debug)

        write-host '----- Write into Information stream -----'
        $mb.Flush([StreamName]::Information)
    }
    2 {
        $mb.Reset()
        $mb.IndentRight()
        $mb.IndentRight()
        $mb.IndentRight(3)
        $mb.IndentLeft(4)
        Write-Host '----- input from arguments -----'
        InjectMessage $mb '1' '2' '3' 'a' 'b' 'c'
        $mb.Flush()
    }
    3 {
        Write-Host '----- MessageBuilder Turn inactive -----'
        $mb.Active = $false
        $mb.Flush()
    }
    4 {
        # ToStringとLinesの使い分け ToStringは単一行、Linesは複数行を返したい
        $mb = [MessageBuilder]::new() 
        @( 1..20 ) | InjectMessage $mb -OneLine
        write-host '---- 1 -----'
        $mb.ToString()
        write-host '---- 1.1 -----'
        $mb.Lines.Count
        $mb.AppendLine("HOGEeeeee!")
        @(21..25) | InjectMessage $mb 
        write-host '---- 2 -----'
        $mb.Lines.Count | Write-Host
        write-host '---- 3 -----'
        $mb.Lines
        write-host '---- 3.1 -----'
        $mb.ToString()
        write-host '---- 4 -----'
        $mb.flush()
        write-host '---- 5 -----'

    }
    5 {
        $mb = [MessageBuilder]::new()
        @( 1..20 ) | InjectMessage $mb
        for($i=0; $i -lt $mb.Lines.Count; $i++){
            if( (($i+1)%2) -eq 0 ){
                $mb.FlushLine($i,[OutputColor]::Cyan,[OutputColor]::DNS)
            }
            else{
                $mb.FlushLine($i,[OutputColor]::Yellow,[OutputColor]::DNS)
            }
        }
        $mb.Flush()
    }
    6 {
        $mb.Reset()
        $scaleLine = '0---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----'
        write-host $scaleLine
                    

        $mb.Helper.Line(20) | InjectMessage $mb -oneline -NoNewLine
        $mb.Helper.Line(4,' ') | InjectMessage $mb -oneline -NoNewLine
        $mb.Helper.Line(20,'~') | InjectMessage $mb 
        $mb.Flush()
        <#
        $f = {
            param($str,$width)
            $len = $str.Length
            if( $len -lt $width){
                $diffLen = $width - $len
                $actualStr = (' ' * $diffLen)+$str
                

            }
        }
        &$f $scaleLine 40
        #>
    }
    7 {
        $scaleLine = '0---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8----+----9----+----'
        write-host $scaleLine

        $mb = [MessageBuilder]::new()
        1,3,5 | InjectMessage $mb -Left 5 -OneLine -NoNewLine

        1,3,5 | InjectMessage $mb -Right 10 -NoNewLine
        $mb.Flush()
    }
    8 {
        $mb = [MessageBuilder]::new()
        'hogehoge' | InjectMessage $mb -ForegroundColor Yellow -NoNewLine -Left 40
        'Bold' | InjectMessage $mb -Bold
        'Italic' | InjectMessage $mb -Italic
        'Underline'  | InjectMessage $mb -Underline
        'Reset' | InjectMessage $mb -Reset
        'Hide' | InjectMessage $mb -Hide -ResetAfterInject
        'Strike' | InjectMessage $mb -Strike -ResetAfterInject
        ' taratara ' | InjectMessage $mb -ForegroundColor BRIGHT_YELLOW -BackgroundColor CYAN
        $mb.Flush()
    }
}


