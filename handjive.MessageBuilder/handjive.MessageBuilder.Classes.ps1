enum StreamName{
    Host
    Debug
    Information
    Warning
    Error
    Verbose
}

enum OutputColor{
    Black 	    = [ConsoleColor]::Black 	
    Blue 	    = [ConsoleColor]::Blue
    Cyan 	    = [ConsoleColor]::Cyan
    DarkBlue 	= [ConsoleColor]::DarkBlue
    DarkCyan 	= [ConsoleColor]::DarkCyan
    DarkGray 	= [ConsoleColor]::DarkGray
    DarkGreen 	= [ConsoleColor]::DarkGreen
    DarkMagenta = [ConsoleColor]::DarkMagenta
    DarkRed 	= [ConsoleColor]::DarkRed
    DarkYellow 	= [ConsoleColor]::DarkYellow
    Gray 	    = [ConsoleColor]::Gray
    Green 	    = [ConsoleColor]::Green 	
    Magenta 	= [ConsoleColor]::Magenta
    Red 	    = [ConsoleColor]::Red
    White 	    = [ConsoleColor]::White
    Yellow 	    = [ConsoleColor]::Yellow
    DNS         = -1
}

class MessageHelper{
    [string]Line([int]$width,[string]$element){
        $a = $element * $width
        return($a.Substring(0,$width))
    }

    [string]Line([int]$width){
        return($this.Line($width,'-'))
    }
}

class MessageBuilder : handjive.IMessageBuilder {
    static [int]$DefaultIndent = 4

    [Text.StringBuilder]$Substance
    [MessageHelper]$Helper
    [bool]$Active
    [bool]$Dirty
    [int]$Indent
    [int]$wpvIndentLevel
    [string]$wpvIndentFiller = ' '
    [Collections.Stack]$IndentStack
    [string[]]$wpvLines
    [bool]$ResetOnFlush

    MessageBuilder(){
        $this.Substance = [Text.StringBuilder]::new()
        $this.Helper = [MessageHelper]::new()
        $this.Reset()
    }
    MessageBuilder([bool]$active){
        $this.Substance = [Text.StringBuilder]::new()
        $this.Helper = [MessageHelper]::new()
        $this.Reset()
        $this.Active = $active
    }

    Reset(){
        $this.Substance.Clear()
        $this.Active = $true
        $this.Indent = [MessageBuilder]::DefaultIndent
        $this.IndentStack = [Collections.Stack]::new()
        $this.wpvIndentLevel = 0
        $this.ResetOnFlush = $true
    }

    [string[]]BuildLines(){
        if( ($null -eq $this.wpvLines) -or ($this.IsDirty())){
            $lines = [Collections.ArrayList]::new($this.ToString().split("`n"))
            if( $lines.Count -gt 0 ){
                $lines.RemoveAt($lines.Count-1)
            }
            $this.wpvLines = [string[]]$lines
        }
        return ($this.wpvLines)
    }

    [string[]]get_Lines(){
        return($this.BuildLines())
    }

<#    
    set_Lines([string[]]$newLines){
        $this.wpvLines = $newLines
    }
#>    
    BeDirty([bool]$value){
        $this.Dirty = $value
    }
    [bool]IsDirty(){
        return ($this.Dirty)
    }

    [int]IndentLevel(){
        return($this.wpvIndentLevel)
    }

    IndentLevel([int]$level){
        if( $level -ge 0){
            $this.wpvIndentLevel = $level
        }
        else{
            throw 'Indent level should be positive'
        }
    }

    [MessageBuilder]IndentRight(){
        $this.IndentRight(1)
        return($this)|out-null
    }
    IndentRight([int]$level){
        $this.wpvIndentLevel += $level
    }
    IndentLeft(){
        $this.IndentLeft(1)
    }
    IndentLeft([int]$level){
        $newLevel = $this.wpvIndentLevel - $level
        $this.wpvIndentLevel = [int]::max($newLevel,0)
   }

    PushIndentlevel([int]$newLevel){
        $this.IndentStack.Push($this.IndentLevel())
        $this.wpvIndentLevel = $newLevel
    }
    PopIndentLevel(){
        if( $this.IndentStack.Count -gt 0 ){
            $this.IndentLevel($this.IndentStack.Pop())
        }
    }

    [string]IndentFiller(){
        $result = $this.wpvIndentFiller * ($this.wpvIndentLevel*$this.Indent)
        return($result)
    }

    Append([Text.StringBuilder]$sb){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.Append($sb)
        $this.BeDirty($true)
    }
    Append([object]$var){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.Append($var)
        $this.BeDirty($true)
    }
    AppendLine([Text.StringBuilder]$sb){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.AppendLine($sb)
        $this.BeDirty($true)
    }
    AppendLine([object]$var){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.AppendLine($var)
        $this.BeDirty($true)
    }

    NL(){
        $this.Substance.AppendLine('')
        $this.BeDirty($true)
    }

    [string]ToString(){
        return($this.Substance.ToString())
    }
    

    <#
        ダイレクト出力
    #>
    Flush([string]$directValue){
        $this.Flush($directValue,[OutputColor]::DNS,[OutputColor]::DNS)
    }

    Flush([string]$directValue,[OutputColor]$fgc,[OutputColor]$bgc)
    {
        if( $this.Active){
            $ui = (Get-Host).UI.RawUI
            ( $curFgc,$curBgc ) = ($ui.ForegroundColor,$ui.BackgroundColor)
            $actualFgc = if( $fgc -eq [OutputColor]::DNS){ $curFgc } else{ $fgc }
            $actualBgc = if( $bgc -eq [OutputColor]::DNS){ $curBgc } else{ $bgc }
            $directValue | write-host -ForegroundColor $actualFgc -BackgroundColor $actualBgc
        }
    }

    <#
        バッファ全体の内容出力
    #>

    # Stream=Host
    Flush(){    
        if( $this.Active ){
            $this.ToString() | Write-Host -NoNewline
        }
        if( $this.ResetOnFlush ){
            $this.Reset()
        }
    }

    # Stream=Host,色指定付き
    Flush([OutputColor]$fgc,[OutputColor]$bgc){
        $this.basicFlush($this.ToString(),[StreamName]::Host,$fgc,$bgc,$false)
    }

    # Stream指定
    Flush([StreamName]$streamName){
        $this.basicFlush($this.ToString(),$streamName,[OutputColor]::DNS,[OutputColor]::DNS,$false)
    }

    basicFlush(
             [string]$value
            ,[StreamName]$streamName
            ,[OutputColor]$fgColor=[OutputColor]::DNS
            ,[OutputColor]$bgColor=[OutputColor]::DNS
            ,[bool]$NewLine){

        if(! $this.Active ){
            if( $this.ResetOnFlush ){
                $this.Reset()
            }
            return
        }
        
        $ui = Get-Host.UI.RawUI
        $curFgc,$curBgc = $ui.ForegroundColor,$ui.BackgroundColor

        $actualFgc = if( [OutputColor]::DNS -eq $fgColor ){ $curFgc }{ $fgColor }
        $actualBgc = if( [OutputColor]::DNS -eq $bgColor ){ $curBgc }{ $bgColor }

        switch($streamName){
            Host {
                if( $NewLine ){
                    Write-host $value -ForegroundColor $actualFgc -BackgroundColor $actualBgc
                }
                else{
                    Write-Host $value -NoNewline -ForegroundColor $actualFgc -BackgroundColor $actualBgc
                }
            }
            Debug {
                Write-Debug $value
            }
            Information {
                Write-Information $value
            }
            Warning {
                Write-Warning $value
            }
            Error {
                Write-Error $value
            }
            Verbose {
                Write-Verbose $value 
            }
        }
        if( $this.ResetOnFlush ){
            $this.Reset()
        }
    }


    <#
     行単位の出力
    #>

    # Stream=Host
    FlushLine([int]$index){
        $this.basicFlush($this.Lines[$index],[StreamName]::Host,[OutputColor]::DNS,[OutputColor]::DNS,$true)
    }

    # Stream=Host, 色指定
    FlushLine([int]$index,[OutputColor]$fgColor=[OutputColor]::DNS,[OutputColor]$bgColor=[OutputColor]::DNS){
        $this.basicFlush($this.Lines[$index],[StreamName]::Host,$fgColor,$bgColor,$true)
    }

    FlushLine([int]$index,[StreamName]$streamName){
        $this.basicFlush($this.Lines[$index],$streamName,[OutputColor]::DNS,[OutputColor]::DNS)
    }
}