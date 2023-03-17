using namespace System.Management.Automation 
using module handjive.LimitedList


function SA_Head{
     param(
           [AllowNull()][object]$streamInput
          ,[AllowNull()][object[]]$argumentInput
          ,[int]$counter
          ,[int]$count

     )
     if( $null -ne $streamInput){
          if( $counter -le $count){
               write-output $streamInput
          }
     }
     else{
          for( $i = 0; $i -lt $count; $i++){
               Write-Output $argumentInput[$i]
          }
     }
}

function SA_Tail{
     param(
           [AllowNull()][object]$streamInput
          ,[AllowNull()][object[]]$argumentInput
          ,[LimitedList]$buffer
          ,[int]$count
     )
     if( $null -ne $streamInput ){
          $buffer.Add($streamInput)
     }
     else{
          $from = 0 - $count
          $argumentInput[$from .. -1] | write-Output
          $buffer.Clear()
     }
}
function SA_Select{
     param(
           [AllowNull()][object]$streamInput
          ,[AllowNull()][object[]]$argumentInput
          ,[ScriptBlock]$nominator
     )
     if( $null -ne $streamInput ){
          if( &$nominator $streamInput ){ Write-Output $streamInput }
     }
     else{
          $argumentInput.foreach{
               if( &$nominator $_  ){ Write-Output $_ }
          }
     }
}

function SA_Reject{
     param(
           [AllowNull()][object]$streamInput
          ,[AllowNull()][object[]]$argumentInput
          ,[ScriptBlock]$denominator
     )
     if( $null -ne $streamInput ){
          if( ! (&$denominator $streamInput) ){ Write-Output $streamInput }
     }
     else{
          $argumentInput.foreach{
               if( !(&$denominator $_) ){ Write-Output $_ }
          }
     }
}

function SA_Treat{
     param(
           [AllowNull()][object]$streamInput
          ,[AllowNull()][object[]]$argumentInput
          ,[ScriptBlock]$modifier
     )

     if( $null -ne $streamInput ){
          &$modifier $streamInput | write-output
     }
     else{
          $argumentInput.foreach{
               &$modifier $_ | write-output
          }
     }
}

function SA_InjectInto{
     param(
           [AllowNull()][object]$streamInput
          ,[AllowNull()][object[]]$argumentInput
          ,[object]$injectResult
          ,[ScriptBlock]$injectionBlock
     )
     if( $null -ne $streamInput ){
          return &$injectionBlock $injectResult $streamInput
     }
     else{
          $result = $injectionResult
          $argumentInput.foreach{
               $result = &$injectionBlock $result $_
          }
          return $result
     }
}

function SA_PassThru{
     param(
           [AllowNull()][object]$streamInput
          ,[AllowNull()][object[]]$argumentInput
     )
     if( $null -ne $streamInput ){
          $streamInput | write-output
     }
     else{
          $argumentInput.foreach{ write-Output $_ }
     }
}

function StreamAdaptor
{
     [CmdletBinding()]
     Param(
           [Parameter(Position=0)][AllowNull()][object[]]$Subject = $null
          ,[Parameter(Mandatory,ParameterSetName="Head")][ValidateRange([ValidateRangeKind]::Positive)][int]$Head
          ,[Parameter(Mandatory,ParameterSetName="Tail")][ValidateRange([ValidateRangeKind]::Positive)][int]$Tail
          ,[Parameter(Mandatory,ParameterSetName="Select")][scriptBlock]$Select
          ,[Parameter(Mandatory,ParameterSetName="Reject")][scriptBlock]$Reject
          ,[Parameter(Mandatory,ParameterSetName="Treat")][scriptBlock]$Treat   # Treat is alias of Collect
          ,[Parameter(Mandatory,ParameterSetName="Collect")][scriptBlock]$Collect
          ,[Parameter(Mandatory,ParameterSetName="InjectInto")][object]$Inject
          ,[Parameter(Mandatory,ParameterSetName="InjectInto")][ScriptBlock]$Into
          ,[Parameter(Mandatory,ParameterSetName="PassThru")][switch]$PassThru
          ,[Parameter(ValueFromPipeline)][AllowNull()][object]$StreamInput = $null
     )
     
     begin{
          $counter = 0
          if($PsCmdlet.ParameterSetName -eq 'Tail') {
               $buffer = [LimitedList]::new($Tail)
          }
          elseif($PsCmdlet.ParameterSetName -eq 'InjectInto'){
               $injectResult = $Inject
          }
     }
     process{
          ++$counter
          switch ($PsCmdlet.ParameterSetName) {
               Head      { SA_Head $streamInput $Subject $counter $Head }
               Tail      { SA_Tail $streamInput $Subject $buffer $Tail }
               Select    { SA_Select $streamInput $Subject $Select }
               Reject    { SA_Reject $streamInput $Subject $Reject }
               Treat     { SA_Treat $streamInput $Subject $Treat }    # Treat is an alias of Collect
               Collect   { SA_Treat $streamInput $Subject $Treat }
               InjectInto{ $injectResult = SA_InjectInto $streamInput $Subject $injectResult $Into }
               PassThru  { SA_PassThru $streamInput $Subject }
          }
     }
     end{
          if($PsCmdlet.ParameterSetName -eq 'Tail') {
               $buffer.Values().foreach{
                    Write-Output $_
               }
          }
          elseif($PsCmdlet.ParameterSetName -eq 'InjectInto'){
               write-Output $injectResult
          }
     }
}

Export-ModuleMember StreamAdaptor