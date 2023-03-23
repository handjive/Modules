using module handjive.StringUtility

enum StreamName{
    Host
    Debug
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
    DNS = -1
}


class VT100CharacterModifier {
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
            $this.Enable()
        }
    }

    Enable(){
        $this.Enabled($true)
    }
    Disable(){
        $this.Enabled($false)
    }
    Enabled([bool] $aValue){
        $this.FRAME = if( $aValue ){ [VT100CharacterModifier]::CHAR_MOD_FRAME } else{ ''}
    }
}

class MessageHelper{
    static [VT100CharacterModifier]$modifier
    
    [VT100CharacterModifier]modifier(){
        if( $null -eq [MessageHelper]::modifier ){
            [MessageHelper]::modifier = [VT100CharacterModifier]::new()
        }
        return([MessageHelper]::modifier)
    }

    [string]Line([int]$width,[string]$element){
        $a = $element * $width
        return($a.Substring(0,$width))
    }

    [string]Line([int]$width){
        return($this.Line($width,'-'))
    }

    [string]Left([string]$aString,[int]$aWidth){
        return([StringUtility]::Left($aString,$aWidth))
    }
    [string]Left([string]$aString,[int]$aWidth,[string]$aFiller){
        return([StringUtility]::Left($aString,$aWidth,$aFiller))
    }
    [string]Right([string]$aString,[int]$aWidth){
        return([StringUtility]::Right($aString,$aWidth))
    }
    [string]Right([string]$aString,[int]$aWidth,[string]$aFiller){
        return([StringUtility]::Right($aString,$aWidth,$aFiller))
    }
    [string]VtModifyString([VT100CharMod]$modifierId){
        return($this.modifier.modify($modifierId))
    }

}

class MessageBuilder {
    static [int]$DefaultIndent = 4

    [Text.StringBuilder]$Substance  
    [MessageHelper]$Helper
    [VT100CharacterModifier]$modifier

    [bool]$ResetOnFlush
    [bool]$Active
    [int]$Indent
    [int]$wpvIndentLevel
    [string]$wpvIndentFiller = ' '
    [Collections.Stack]$IndentStack

    InitializeInstance(){
        $this.Substance = [Text.StringBuilder]::new()
        $this.Helper = [MessageHelper]::new()
        $this.modifier = [VT100CharacterModifier]::new()
        $this.IndentStack = [Collections.Stack]::new()
        $this.Indent = [MessageBuilder]::DefaultIndent
        $this.Active = $true
        $this.ResetOnFlush = $true
    }
    MessageBuilder(){
        $this.InitializeInstance()
        $this.Reset()
    }
    MessageBuilder([bool]$active){
        $this.InitializeInstance()
        $this.Reset()
        $this.Active = $active
    }

    Reset(){
        $this.wpvIndentLevel = 0
        $this.Substance.Clear()
    }

    <# 
    # VT100 Character modify
    #>
    Modify([VT100CharMod]$mod){
        $this.Substance.Append($this.modifier.Modify($mod))
    }
    ResetModify(){
        $this.Substance.Append($this.modifier.Modify([VT100CharMod]::Reset))
    }

    ForegroundColor([VT100CharMod]$color){
        $this.Substance.Append($this.modifier.Modify($color))
    }
    BackgroundColor([VT100CharMod]$color){
        $this.Substance.Append($this.modifier.BackgroundColor($color))
    }

    <#
    # Indent Contol 
    #>
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

    PushIndentLevel(){
        $this.PushIndentlevel($this.IndentLevel())
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


    <#
    # Append string into buffer
    #>
    Append([Text.StringBuilder]$sb){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.Append($sb)
    }
    Append([object]$var){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.Append($var)
    }
    AppendLine([Text.StringBuilder]$sb){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.Append($sb)
        $this.NL()
    }
    AppendLine([object]$var){
        $this.Substance.Append($this.IndentFiller())
        $this.Substance.Append($var)
        $this.NL()
    }

    NL(){
        $this.NL($true)
    }
    NL([int]$times){
        $this.NL($true,$times)
    }

    NL([bool]$switch){
        $this.NL($switch,1)
    }
    NL([bool]$switch,[int]$times){
        if( !$switch ){
            return
        }
        $this.ResetModify()
        @(1..$times).foreach{ $this.Substance.AppendLine() }
    }

    [string]ToString(){
        return($this.Substance.ToString())
    }
    

    <#
    # ダイレクト出力
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
    # バッファ全体の内容出力
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

    # Stream指定
    Flush([StreamName]$streamName){
        $this.basicFlush($this.ToString(),$streamName,$false)
    }

    basicFlush([string]$value,[StreamName]$streamName,[bool]$NewLine){

        if(! $this.Active ){
            if( $this.ResetOnFlush ){
                $this.Reset()
            }
            return
        }
        
        switch($streamName){
            Host {
                if( $NewLine ){
                    Write-host $value
                }
                else{
                    Write-Host $value
                }
            }
            Debug {
                Write-Debug $value
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
}