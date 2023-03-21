
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
    [CmdletBinding()]
    param(
         [parameter(Mandatory,Position=0)][MessageBuilder]$Builder
        ,[parameter(ValueFromPipeline)][object]$streamInput
        ,[parameter(ParameterSetName='OneLine')][switch]$OneLine
        ,[parameter(ParameterSetName='OneLine')][string]$Delimiter = " "

        ,[parameter()][switch]$NoNewLine

        ,[parameter()][int]$Left
        ,[parameter()][int]$Right

        ,[parameter()][VT100CharMod]$ForegroundColor
        ,[parameter()][VT100CharMod]$BackgroundColor
        ,[parameter()][switch]$Bold
        ,[parameter()][switch]$Italic
        ,[parameter()][switch]$Underline
        ,[parameter()][switch]$Invert
        ,[parameter()][switch]$Hide
        ,[parameter()][switch]$Strike
        ,[parameter()][switch]$Normal
        ,[parameter()][switch]$Reset
        ,[parameter()][switch]$ResetAfterInject

        ,[parameter(ValueFromRemainingArguments=$true)]$Lefts
    )

    begin{
        $local:actualDelimiter=''
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
        $aValue = if(0 -ne $Left ){
            $aFormat = [String]::Format('{{0,-{0}}}',$Left)
            [String]::Format($aFormat,$streamInput)
        }
        elseif( 0 -ne $Right ){
            $aFormat = [String]::Format('{{0,{0}}}',$Right)
            [String]::Format($aFormat,$streamInput)
        }
        else{
            $streamInput
        }

        switch($PsCmdlet.ParameterSetName){
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
                $Builder.Append($aValue)
            }
       }
    }
    end{
        if( $Lefts.Count -gt 0){    # 残りの引数がある時
            switch($PsCmdlet.ParameterSetName ){
                OneLine {
                    OneLineAppender $Builder $actualDelimiter $Delimiter $Lefts
                    $local:actualDelimiter=$Delimiter
                }
                default{
                    $Lefts.foreach{ $Builder.AppendLine($args[0]) }
                }
            }
        }

        if( $ResetAfterInject ){ $Builder.Append($Builder.Helper.modifier.Reset()) }

        switch( $PsCmdlet.ParameterSetName ){
            OneLine {
                $Builder.PopIndentLevel()
            }
            default{
                if( !$NoNewLine){
                    $Builder.NL()
                }
            }
        }
    }

}