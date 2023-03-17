
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
        ,[parameter(ParameterSetName='OneLine')][switch]$NoNewLine
        ,[parameter(ParameterSetName='OneLine')][string]$Delimiter = " "
        ,[parameter(ValueFromRemainingArguments=$true)]$Lefts
    )

    begin{
        $local:actualDelimiter=''
    }

    process{
        switch($PsCmdlet.ParameterSetName){
            OneLine {
                if( $null -eq $streamInput ){
                    break
                }
                OneLineAppender $Builder $actualDelimiter $Delimiter @( $streamInput )
                $actualDelimiter = $Delimiter
            }
            default {
                if( $null -eq $streamInput ){
                    break
                }
                $Builder.AppendLine($streamInput)
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

        switch( $PsCmdlet.ParameterSetName ){
            OneLine {
                $Builder.PopIndentLevel()
                if( !$NoNewLine){
                    $Builder.NL()
                }
            }
        }
    }

}