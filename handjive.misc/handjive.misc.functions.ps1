. "$PSScriptRoot\Get-PathDepth.ps1"
function Beep
{
    [console]::Beep(440,500)
    [console]::Beep(880,250)
}

<#
    指定パスが実体かリンクか判定し、リンクだったら実体パスの、実体ならそのDirectoryInfoを返す
#>
function EnsureSubstancePath
{
    Param(
         [Parameter(Mandatory,HelpMessage="確認・変換対象パス")][string]$LiteralPath
        ,[Parameter(HelpMessage="対象パスがリンクだった時に実行するScriptBlock")][scriptblock]$ifLinkedPath={}               
        ,[Parameter(HelpMessage="対象パスが実体だった時に実こうするScriptBlock")][scriptblock]$ifSubstancePath={}
    )
    $dirInfo = Get-Item -LiteralPath $LiteralPath
    
    if( $null -ne $dirInfo.LinkTarget){ # 指定されたパスはリンク
        $actualTarget = Get-Item -LiteralPath $dirinfo.LinkTarget
        &$ifLinkedPath $LiteralPath $actualTarget
    }
    else{   #指定されたパスは実体
        $actualTarget = $dirInfo
        &$ifSubstancePath $LiteralPath $actualTarget
    }
    return $actualTarget
}
