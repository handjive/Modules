
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
        ,[parameter()][switch]$NewLine
        ,[parameter()][int]$NewLines

        ,[parameter()][switch]$Flush
        ,[parameter()][switch]$FlushIfDebug
        ,[parameter()][switch]$FlushIfVerbose
        ,[parameter()][boolean]$FlushIf

        ,[parameter(ValueFromRemainingArguments=$true)]$Lefts
    )

    begin{
        $local:actualDelimiter=''
        $actualPadding = if( "" -eq $Padding ){ ' ' } else{ $Padding }
        $local:leftAlone = $Lefts

        if( $OneLine ){ $Builder.PushIndentlevel()}

        $modifyBlock = {
            if( $null -ne $ForegroundColor ){
                $Builder.ForegroundColor($ForegroundColor)
            }
            if( $null -ne $BackgroundColor ){
                $Builder.BackgroundColor($BackgroundColor)
            }
    
            if( $Bold       ){ $Builder.Modify('Bold') }
            if( $Italic     ){ $Builder.Modify('Italic') }
            if( $Underline  ){ $Builder.Modify('Underline') }
            if( $Invert     ){ $Builder.Modify('Invert') }
            if( $Hide       ){ $Builder.Modify('Hide') }
            if( $Strike     ){ $Builder.Modify('Strike') }
            if( $Normal     ){ $Builder.Modify('Normal') }
            if( $Reset      ){ $Builder.ResetModify() }
        }
    }

    process{
        &$modifyBlock

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
                &$modifyBlock
                OneLineAppender $Builder $actualDelimiter $Delimiter $leftAlone
                $local:actualDelimiter=$Delimiter
            }
            else{
                for($i=0; $i -lt $leftAlone.Count; $i++){
                    &$modifyBlock
                    $Builder.Append($leftAlone[$i])   
                    if( $i -ne ($leftAlone.Count -1) ){ # NoNewLineが指定されてるかもしれないんで、最後の一行はNL()しない
                        $Builder.NL()
                    }
                }
                $Builder.NL(!$NoNewLine)

#                $leftAlone.foreach{ 
#                    $Builder.Append($args[0])
#
#                }
            }
        }

#        if( !$KeepModify ){ $Builder.ResetModify() }

        if( $OneLine ){
            $Builder.PopIndentLevel()
            $Builder.NL(!$NoNewLine)
        }

        if( $NewLine ){
            $Builder.NL()
        }
        if( $NewLines -gt 0 ){
            $Builder.NL($NewLines)
        }

        if( $Flush ){
            $Builder.Flush()
        }
        if( $FlushIfDebug ){
            if( $DebugPreference -ne 'SilentlyContinue' ){
                $Builder.Flush()
            }
            $Builder.Clear()
        }
        if( $FlushIfVerbose ){
            #if( $VerbosePreference -ne 'SilentlyContinue' ){
            Write-Verbose $Builder.ToString()
            #}
            $Builder.Clear()
        }
        if( $FlushIf ){
            $Builder.Flush()
            $Builder.Clear()
        }
    }
}