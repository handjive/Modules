
<#
     $nameLongThan10 = ([col]::on($aCollection)).Select({
          param($elem)
          $elem.Name.Length -ge 10
     })
     ([col]::on($aCollection).Detect({$true}))


     )

     cop @( 1 .. 10) -select { $true }
     @( 1 .. 10) | cop -select { $true }

     cop @( 1 .. 10) -reject { $true }
     cop @( 1 .. 10) -collect { [string]$arg[0] }
     cop @( 1 .. 10) -inject { [string]$arg[0] } -into @()
     cop @( 1 .. 10) -detect { $true } -ifNone { Write-Host 'HOGE!' }

     cop @(1 .. 10) -at 8 ifAbsent {Write-Host 'HOGEeeee' }

#>

function CopSelect
{
     Param([object[]]$substance,[ScriptBlock]$nominator)
     $result = @()
     $substance.foreach{
          if( (&$nominator $_) ){
               $result += $_
          }
     }
     
     return $result
}

function CopCollect
{
     Param([object[]]$substance,[ScriptBlock]$modifier)

     $result = @()
     $substance.foreach{
          $result += &$modifier $_
     }

     return $result
}

function CopReject
{
     Param([object[]]$substance,[ScriptBlock]$denominator)
     $result = @()
     $substance.foreach{
          if( !(&$denominator $_) ){
               $result += $_
          }
     }

     return $result
}

function CopInjectInto{
     Param($substance,$initValue,$scriptBlock)
     $var = $initValue
     $substance.foreach{
          $var = &$scriptBlock $var $_
     }
     return $var
}

function CopDetectIfNone
{
     param($substance,$condition,$alternative)

     $substance.foreach{
          if( &$condition $_ ){
               return $_
          }
     }
     return &$alternative
}

function CopAtIfAbsent
{
     param($substance,$index,$alternative)
     if( $null -ne $substance[$index] ){
          return $substance[$index]
     }
     else{
          return &$alternative
     }
}
function CollectionOperator
{
     [CmdletBinding()]
     Param(
           [parameter(Position=0)][AllowNull()][object[]]$Substance = $null
          
          ,[parameter(Mandatory,ParameterSetName="Select")]      [ScriptBlock]$Select
          ,[parameter(Mandatory,ParameterSetName="Collect")]     [ScriptBlock]$Collect
          ,[parameter(Mandatory,ParameterSetName="Reject")]      [ScriptBlock]$Reject
          
          ,[Parameter(Mandatory,ParameterSetName="Inject")]      [object]$Inject
          ,[Parameter(Mandatory,ParameterSetName="Inject"
               ,HelpMessage='$Injectとコレクション要素の2引数をとるスクリプトブロック')]
                                                                 [scriptBlock]$Into

          ,[parameter(Mandatory,ParameterSetName="Detect")]      [ScriptBlock]$Detect
          ,[parameter(Mandatory,ParameterSetName="Detect")]      [ScriptBlock]$ifNone

          ,[parameter(Mandatory,ParameterSetName="At")]          [object]$At
          ,[parameter(Mandatory,ParameterSetName="At")]          [ScriptBlock]$ifAbsent
          
          ,[Parameter(ValueFromPipeline)][AllowNull()][object]$StreamInput = $null          
     )

     Process{
          switch ($PsCmdlet.ParameterSetName) {
               'Select'  { return (CopSelect $substance $Select) }
               'Collect' { return (CopCollect $substance $Collect) }
               'Reject'  { return (CopReject $substance $Reject)}
               'Inject'  { return (CopInjectInto $substance $Inject $Into)}
               'Detect'  { return (CopDetectIfNone $substance $Detect $ifNone)}
               'At'      { return (CopAtIfAbsent $substance $At $ifAbsent)}
          }
     }
}