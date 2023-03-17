<# 指定したパスの階層数を取り出す 
     
     ルートを0とし、対象までのパスを数える
     'C:\Users\handjive\Scripts.PowerShell\Modules\ConfigurationUtilities\aaa.txt'なら6階層目
     'C:\aaa.txt'なら0階層目

     -Baseが指定されたら、そのパスをルートとして数える
     Base='C:\Users\handjive\Scripts.PowerShell\'なら
     'C:\Users\handjive\Scripts.PowerShell\Modules\ConfigurationUtilities\aaa.txt'は3階層目

     実在しないパスをどう扱う?
#>

function StripEnd{
     Param(
           [parameter(Mandatory)][string]$String
          ,[parameter(Mandatory)][string]$StripCharacter
     )
     if( $String[-1] -eq $StripCharacter ){
          #if( $String.Length -gt 1 ){
               return($String.Substring(0,$String.Length-1))
          #}
     }
     return($String)
}
function Get-PathDepth
{
     [CmdletBinding()]
     Param(
           [Parameter(Mandatory)][String]$Path
          ,[string]$Base
     )

     <# 前処理
     　パスを"\a\b\c"の形式(Quorifier無し、"\"始まり)に揃える
     #>
     $actualBase = $null
     $actualPath = Split-Path -NoQualifier -Path $Path
     if( "" -ne $Base){
          $actualBase = Split-Path -NoQualifier -Path $Base
          $actualBase = StripEnd $actualBase '\'
          $actualPath = $actualPath.replace($actualBase,'',1)
     }
     $actualPath = Split-Path $actualPath
     $actualPath = StripEnd $actualPath '\'
     $splited = $actualPath.Split('\')
     $splited.Length-1
}