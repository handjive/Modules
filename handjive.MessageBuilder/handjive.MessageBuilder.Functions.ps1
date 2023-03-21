
function OneLineAppender
{
    param(
         [Parameter(Mandatory)][MessageBuilder]$Builder
        ,[Parameter(Mandatory)][AllowEmptyString()][string]$initialDelimiter
        ,[Parameter(Mandatory)][AllowEmptyString()][string]$Delimiter
        ,[Parameter(Mandatory)][string[]]$appendee
    )

    $local:actualDelimiter = $initialDelimiter
    $appendee.foreach{
        $Builder.Append($actualDelimiter)
        if( $Builder.IndentLevel() -ne 0 ){
            $Builder.PushIndentLevel(0)
        }
        $Builder.Append($_)
        $local:ActualDelimiter = $Delimiter
    }
}

function InjectMessage{
    [CmdletBinding(DefaultParameterSetName='CharMod')]
    param(

         [parameter(Mandatory,Position=0)][MessageBuilder]$Builder
        ,[parameter(ValueFromPipeline)][object]$streamInput
<#
        ,[parameter(Mandatory,ParameterSetName='Left')][int]$Left
        ,[parameter(Mandatory,ParameterSetName='Right')][int]$Right
        ,[parameter(Mandatory,ParameterSetName='FormatByStream')][switch]$FormatByStream
        ,[parameter(Mandatory,ParameterSetName='Format')][string]$Format
        ,[parameter(Mandatory,ParameterSetName='CharMod')][switch]$CharMod
#>
        ,[parameter(ParameterSetName='Left')][int]$Left
        ,[parameter(ParameterSetName='Right')][int]$Right
        ,[parameter(ParameterSetName='FormatByStream')][switch]$FormatByStream
        ,[parameter(ParameterSetName='Format')][string]$Format
        ,[parameter(ParameterSetName='CharMod')][switch]$CharMod

        ,[parameter()][string]$Padding
        ,[parameter()][switch]$OneLine
        ,[parameter()][string]$Delimiter = " "
        ,[parameter()][switch]$NoNewLine

        ,[parameter()][VT100CharMod]$ForegroundColor
        ,[parameter()][VT100CharMod]$BackgroundColor
        
        ,[parameter()][switch]$Bold
        ,[parameter()][switch]$Italic
        ,[parameter()][switch]$Underline
        ,[parameter()][switch]$Invert
        ,[parameter()][switch]$Hide
        ,[parameter()][switch]$Strike
        ,[parameter()][switch]$Normal
        ,[parameter()][switch]$ResetModify
        ,[parameter()][switch]$KeepModify

        ,[parameter(ValueFromRemainingArguments=$true)]$Lefts
    )

    begin{
        $local:actualDelimiter=''
        $actualPadding = if( "" -eq $Padding ){ ' ' } else{ $Padding }
        $local:leftAlone = $Lefts

        if( $null -ne $ForegroundColor ){
            $Builder.Append($Builder.Helper.modifier.ForegroundColor($ForegroundColor))
        }
        if( $null -ne $BackgroundColor ){
            $Builder.Append($Builder.Helper.modifier.BackgroundColor($BackgroundColor))
        }

        if( $Bold       ){ $Builder.Append($Builder.Helper.modifier.Modify('Bold')) }
        if( $Italic     ){ $Builder.Append($Builder.Helper.modifier.Modify('Italic')) }
        if( $Underline  ){ $Builder.Append($Builder.Helper.modifier.Modify('Underline')) }
        if( $Invert     ){ $Builder.Append($Builder.Helper.modifier.Modify('Invert')) }
        if( $Hide       ){ $Builder.Append($Builder.Helper.modifier.Modify('Hide')) }
        if( $Strike     ){ $Builder.Append($Builder.Helper.modifier.Modify('Strike')) }
        if( $Normal     ){ $Builder.Append($Builder.Helper.modifier.Modify('Normal')) }
        if( $Reset      ){ $Builder.Append($Builder.Helper.modifier.Reset()) }
    }

    process{
        # 出力値を変更するもの
        $aValue = switch($PsCmdlet.ParameterSetName){
            Left {
                $aStr = $Builder.Helper.Left($streamInput,$Left,$actualPadding)
                $aStr
            }
            Right {
                $aStr = $Builder.Helper.Right($streamInput,$Right,$actualPadding)
                $aStr
            }
            FormatByStream {
                $aStr = [String]::Format($streamInput,[array]$leftAlone)
                $leftAlone = @()
                $aStr
            }
            Format {
                [String]::Format($Format,$streamInput)
            }
            default {
                $streamInput
            }
        }

        if( $OneLine ){
            if( $null -ne $aValue ){
                OneLineAppender $Builder $actualDelimiter $Delimiter @( $aValue )
                $actualDelimiter = $Delimiter
            }
        }
        else{
            if( $null -ne $aValue ){
                if( $NoNewLine ){
                    $Builder.Append($aValue)
                }
                else{
                    $Builder.AppendLine($aValue)
                }
            }
        }

<#        switch($PsCmdlet.ParameterSetName){
            OneLine {
                if( $null -eq $aValue ){
                    break
                }
                OneLineAppender $Builder $actualDelimiter $Delimiter @( $aValue )
                $actualDelimiter = $Delimiter
            }
            default {
                if( $null -eq $streamInput ){
                    break
                }
                if( $NoNewLine ){
                    $Builder.Append($aValue)
                }
                else{
                    $Builder.AppendLine($aValue)
                }
            }
       }
       #>
    }
    end{
        if( $leftAlone.Count -gt 0){    # 残りの引数がある時
            if( $PsCmdlet.ParameterSetName -eq 'Format'){
                $leftAlone = StreamAdaptor $leftAlone -Collect{ [String]::Format($Format,$args[0]) }
            }

            if($PsCmdlet.ParameterSetName -eq 'Left' ){
                #$leftAlone = $leftAlone.foreach{ $Builder.Helper.Left($_,$Left,$Padding)}
                $leftAlone = StreamAdaptor $leftAlone -Collect{ $Builder.Helper.Left($args[0],$Left,$Padding)}
            }
            if($PsCmdlet.ParameterSetName -eq 'Right' ){
                $leftAlone = StreamAdaptor $leftAlone -Collect{ $Builder.Helper.Right($args[0],$Right,$Padding)}
            }

            if($OneLine){
                OneLineAppender $Builder $actualDelimiter $Delimiter $leftAlone
                $local:actualDelimiter=$Delimiter
                if( !$NoNewLine){
                    $Builder.NL()
                }
            }
            else{
                $leftAlone.foreach{ 
                    if( $NoNewLine ){
                        $Builder.Append($_)
                    }
                    else{
                        $Builder.AppendLine($_) 
                    }
                }
            }
        }

        if( !$KeepModify ){ $Builder.Append($Builder.Helper.modifier.Reset()) }

        switch( $PsCmdlet.ParameterSetName ){
            OneLine {
                $Builder.PopIndentLevel()
            }
        }
    }

}