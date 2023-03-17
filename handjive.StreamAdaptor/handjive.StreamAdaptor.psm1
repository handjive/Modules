using namespace System.Management.Automation 
using module handjive.LimitedList
function StreamAdaptor
{
     [CmdletBinding()]
     Param(
           [Parameter(Position=0,ValueFromPipeline)][object][PSCustomObject]$Subject
          ,[Parameter(Mandatory,ParameterSetName="Head")][ValidateRange([ValidateRangeKind]::Positive)][int]$Head
          ,[Parameter(Mandatory,ParameterSetName="Tail")][ValidateRange([ValidateRangeKind]::Positive)][int]$Tail
          ,[Parameter(Mandatory,ParameterSetName="Select")][scriptBlock]$Select
          ,[Parameter(Mandatory,ParameterSetName="Reject")][scriptBlock]$Reject
          ,[Parameter(Mandatory,ParameterSetName="Treat")][scriptBlock]$Treat
          ,[Parameter(Mandatory,ParameterSetName="PassThru")][switch]$PassThru
     )
     
     begin{
          $counter = 0
          if($PsCmdlet.ParameterSetName -eq 'Tail') {
               $buffer = [LimitedList]::new($Tail)
          }
     }
     process{
          ++$counter
          switch ($PsCmdlet.ParameterSetName) {
               Head {
                    if( $counter -le $Head){
                         write-output $Subject
                    }
               }
               Tail {
                    $buffer.Add($Subject)
               }
               Select {
                    if( &$Select $Subject ){
                         Write-Output $Subject
                    }
               }
               Reject {
                    if( !(&$Reject $Subject) ){
                         Write-Output $Subject
                    }
               }
               Treat {
                    Write-Output (&$Treat $Subject)
               }
               PassThru {
                    Write-Output $Subject
               }
          }
     }
     end{
          if($PsCmdlet.ParameterSetName -eq 'Tail') {
               $buffer.Values().foreach{
                    Write-Output $_
               }
          }
     }
}

Export-ModuleMember StreamAdaptor