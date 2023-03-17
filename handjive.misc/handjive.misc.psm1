function Beep
{
    [console]::Beep(440,500)
    [console]::Beep(880,250)
}

function Write-HostByFlag{
    [CmdletBinding()]
    Param([Parameter(Mandatory)][boolean]$ifTrue
         ,$message
         ,$head
         ,$tail
         ,[switch]$OneLine
         ,[switch]$NoNewline
         ,[Parameter(ValueFromPipeline)]$pipeValue
    )

    begin{
         if( $ifTrue )
         {
              if( $null -ne $head)
              {
                   if( $OneLine )
                   {
                         $head | Write-Host -NoNewline
                   }
                   else {
                         $head | Write-Host
                   }
              }
              if( $null -ne $message)
              {
                   if( $OneLine )
                   {
                         $message | Write-Host -NoNewline
                   }
                   else {
                         $message | Write-Host
                   }
              }
         }
    }

    process{
         if( $ifTrue )
         {
              if( $null -ne $pipeValue){
                   if( $OneLine )
                   {
                         $_ | Write-Host -NoNewline
                   }
                   else{
                         $_ | Write-Host
                   }
              }
         }
    }
    end{
          if( $null -ne $tail)
          {
               if( $OneLine ){
                    $tail | Write-Host -NoNewline
               }
               else{
                    $tail | Write-Host
               }
          }

          if( ! $NoNewline ){
               Write-Host ""
          }
    }
}



<#Export-ModuleMember -Function Write-HostByFlag
Export-ModuleMember -Function CollectionOperator
Export-ModuleMember -Function Beep
Export-ModuleMember -Function Get-PathDepth
#>