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

enum VT100CharMod{
    RESET = 0
    BOLD = 1
    FAINT = 2
    ITALIC = 3
    UNDERLINE = 4
    #SLOWBLINK = 5
    #RAPIDBLINK = 6
    INVERT = 7
    HIDE = 8
    STRIKE =9
    #DOULBEUNDERLINE = 21
    NORMAL = 22
    #NOTREVERSED = 27
    #REVEAL = 28
    NOTCROSSEDOUT = 29

    BLACK = 30
    RED = 31
    GREEN = 32
    YELLOW = 33
    BLUE = 34
    MAGENTA = 35
    CYAN = 36
    WHITE = 37

    BRIGHT_BLACK = 30+60
    BRIGHT_RED = 31+60
    BRIGHT_GREEN = 32+60
    BRIGHT_YELLOW = 33+60
    BRIGHT_BLUE = 34+60
    BRIGHT_MAGENTA = 35+60
    BRIGHT_CYAN = 36+60
    BRIGHT_WHITE = 37+60

    BACKGROUND = 10
    DEFAULTCOLOR = 39
}

class VT100CharacterModifier{
    static [string]$CHAR_MOD_FRAME="`e[{0}m"
    [string]$FRAME = ""


    [string]Modify([Vt100CharMod]$mod){
        return([String]::Format(($this.FRAME),[int]$mod))
    }
    [string]Reset(){
        return($this.Modify([VT100CharMod]::RESET))
    }
    [string]ForegroundColor([VT100CharMod]$color){
        return($this.Modify($color))
    }
    [string]BackgroundColor([VT100CharMod]$color){
        return($this.Modify($color+[VT100CharMod]::BACKGROUND))
    }

    VT100CharacterModifier(){
        # 端末がVt100をサポートしていないなら、修飾指定されても空文字出力
        if( (Get-host).UI.SupportsVirtualTerminal ){
            $this.FRAME = [VT100CharacterModifier]::CHAR_MOD_FRAME
        }
    }
}

class MessageHelper{
    [VT100CharacterModifier]$modifier

    MessageHelper(){
        $this.modifier = [VT100CharacterModifier]::new()
    }

    [string]Line([int]$width,[string]$element){
        $a = $element * $width
        return($a.Substring(0,$width))
    }

    [string]Line([int]$width){
        return($this.Line($width,'-'))
    }

    [string]ForegroundColor([VT100CharMod]$color){
        return($this.modifier.ForegroundColor($color))
    }
    [string]BackgroundColor([VT100CharMod]$color){
        return($this.modifier.BackgroundColor($color))
    }
    [string]Modify([VT100CharMod]$modifier){
        return($this.modifier.modify($modifier))
    }
    
    [string]ReverseString([string]$str){
        $chars = $str[($str.Length-1)..0]
        return (($chars -join('')))
    }

    [string]ClipLeftInWidth([string]$str,[int]$width){
        return($this.ReverseString(($this.ClipRightInWidth($this.ReverseString($str),$width))))
    }

    [string]ClipRightInWidth([string]$str,[int]$width){
        #$a[($a.Length-1)..0]  
        $buffer = ''
        for($i = 0; $i -lt $str.Length; $i++){
            $bufferWidth = SizeInByte $buffer
            $charWidth = SizeInByte $str[$i]
            if( ($bufferWidth+$charWidth) -le $width ){
                $buffer += $str[$i]
            }
            else{ 
                break
            }
        }

        if( (SizeInByte $buffer) -gt $width ){
            throw "What a HELL!?"
        }
        return ($buffer)
    }

    [string]Left([string]$str,[int]$width){
        return($this.Left($str,$width,' '))
    }

    [string]Left([String]$str,[int]$width,[string]$filler){
        $str,$padding = $this.ClipAndCulculatePadding($str,$width,$filler)
        return($str+$padding)
    }

    [string]Right([string]$str,[int]$width){
        return($this.Right($str,$width,' '))
    }

    [string]Right([String]$str,[int]$width,[string]$filler){
        $str,$padding = $this.ClipAndCulculatePadding($this.ReverseString($str),$width,$filler)
        return($padding+$this.ReverseString($str))
    }



    [string[]]ClipAndCulculatePadding([string]$str,[int]$width,[string]$filler){
        $widthInBytes = SizeInByte $str

        $result = $str
        
        # 幅ぴったしなら処理不要
        if( $widthInBytes -eq $width){
            return($result)
        }

        # 指定幅より長ければクリップ
        # (クリップ結果は指定幅より短い可能性がある)
        if( $widthInBytes -gt $width){
            $result = $this.ClipRightInWidth($str,$width)
        }

        # クリップした結果ﾄﾞﾝﾋﾟｼｬならそのまま返す
        if( ($resultWidth = SizeInByte $result) -eq $width ){ return($result) }

        # フィラー処理
        $widthDiff = $width - $resultWidth
        $fillerCandidate = ($filler * $widthDiff)   # Fillerが一文字ならこれでいいんだけど…
        $actualFiller = $fillerCandidate
        if( (SizeInByte $fillerCandidate) -gt $widthDiff ){
            $actualFiller = $this.ClipRightInWidth($fillerCandidate,$widthDiff)
        }

        return(@($result,$actualFiller))
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