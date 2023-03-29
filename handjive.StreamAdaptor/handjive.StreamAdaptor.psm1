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
          ,[object[]]$argumentInput
          ,[object]$injectResult
          ,[ScriptBlock]$injectionBlock
     )
     if( $null -ne $streamInput ){
          return &$injectionBlock $injectResult $streamInput
     }
     else{
          $result = $injectResult
          $argumentInput.foreach{
               $result = &$injectionBlock $result $_
          }
          return $result
     }
}

function SA_FindLast{
     param(
           [AllowNull()][object]$streamInput
          ,[object[]]$argumentInput
          ,[object]$findiLastResult
          ,[ScriptBlock]$findLastBlock
     )

     if( $null -ne $streamInput ){
          if( &$findLastBlock $streamInput ){
               return $streamInput
          }
          else{
               return $findiLastResult
          }
     }
     else{
          $result = $findLastResult
          $argumentInput.foreach{
               if( (&$findLastBlock $_) ){
                    $result = $_
               }
          }
          return $result
     }
}
function SA_Find{
     param(
           [AllowNull()][object]$streamInput
          ,[object[]]$argumentInput
          ,[ScriptBlock]$findBlock
     )

     if( $null -ne $streamInput ){
          if( &$findBlock $streamInput ){
               return $streamInput
          }
          else{
               return $null
          }
     }
     else{
          $argumentInput.foreach{
               if( (&$findBlock $_) ){
                    return $_
               }
          }
          return $null
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
           [Parameter(Position=0)][object[]]$Subject = $null
          ,[Parameter(Mandatory,ParameterSetName="Head")][ValidateRange([ValidateRangeKind]::Positive)][int]$Head
          ,[Parameter(Mandatory,ParameterSetName="Tail")][ValidateRange([ValidateRangeKind]::Positive)][int]$Tail
          ,[Parameter(Mandatory,ParameterSetName="Select")][scriptBlock]$Select
          ,[Parameter(Mandatory,ParameterSetName="Reject")][scriptBlock]$Reject
          ,[Alias('Treat')][Parameter(Mandatory,ParameterSetName="Collect")][scriptBlock]$Collect
          ,[Parameter(Mandatory,ParameterSetName="InjectInto")][object]$Inject
          ,[Parameter(Mandatory,ParameterSetName="InjectInto")][ScriptBlock]$Into
          ,[Parameter(Mandatory,ParameterSetName="Find")][ScriptBlock]$Find
          ,[Parameter(Mandatory,ParameterSetName="FindLast")][ScriptBlock]$FindLast
          ,[Parameter(Mandatory,ParameterSetName="PassThru")][switch]$PassThru
          ,[Parameter()][ScriptBlock]$ifAbsent
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
          elseif($PsCmdlet.ParameterSetName -eq 'FindLast'){
               $findResult = $null
          }
     }
     process{
          ++$counter
          switch ($PsCmdlet.ParameterSetName) {
               Head      { SA_Head $streamInput $Subject $counter $Head }
               Tail      { SA_Tail $streamInput $Subject $buffer $Tail }
               Select    { SA_Select $streamInput $Subject $Select }
               Reject    { SA_Reject $streamInput $Subject $Reject }
               Collect   { SA_Treat $streamInput $Subject $Collect }
               InjectInto{ $injectResult = SA_InjectInto $streamInput $Subject $injectResult $Into }
               Find      { $findResult = SA_Find $streamInput $Subject $Find }
               FindLast  { $findResult = SA_FindLast $streamInput $Subject $findResult $FindLast }
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
          elseif(($PsCmdlet.ParameterSetName -eq 'FindLast') -or  ($PsCmdlet.ParameterSetName -eq 'Find')){
               if( $null -eq $findResult ){
                    $aValue = if( $null -ne $ifAbsent ){ &$ifAbsent } else{ $findResult }
                    write-Output $aValue
               }
               else{
                    write-Output $findResult
               }
          }
     }
}

Export-ModuleMember StreamAdaptor