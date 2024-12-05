using namespace handjive.Everything
using namespace handjive.MessageBuilder

function Invoke-Everything{
    [CmdletBinding(HelpURI="https://www.voidtools.com/support/everything/searching/")]
    Param(
        [Parameter(HelpMessage="検索起点とするパス(省略時はカレントディレクトリ)")][String]$QueryBase = "."
        ,[Parameter(HelpMessage="Everythingの検索コマンド",Mandatory)][AllowEmptyString()][String]$Operation = ""
        ,[Parameter(HelpMessage="Everythingのソート順指定フラグ")][ESAPI_SORT]$SortOrder = [ESAPI_SORT]::NAME_ASCENDING
        ,[Parameter(HelpMessage="FileSystemInfoに変換して出力")][switch]$AsFileSystemInfo
        ,[switch]$ShowDetail
    )

    $mb = [MessageBuilder]::new()
    $mb.NL()
    'QueryBase=[{0}]' | InjectMessage $mb -FormatByStream $QueryBase -FlushIf $ShowDetail
    'Operation=[{0}]' | InjectMessage $mb -FormatByStream $Operation -FlushIf $ShowDetail
    'SortOrder=[{0}]' | InjectMessage $mb -FormatByStream $SortOrder -FlushIf $ShowDetail

    $es = [Everything]::new()
    $es.QueryBase = $QueryBase
    $es.SearchString = $Operation
    $es.SortOrder = $SortOrder
    $es.PerformQuery()

    $mb.NL()
    'Result count = {0} ({1})' | InjectMessage $mb -FormatByStream $es.NumberOfResults $es.LastError -NewLine -FlushIf $ShowDetail

    <# !!!なせこれが動かんのかﾜｶﾗﾝ!!
    $es.ResultIndexDo({
        param($index)
        $fullPath = $es.ResultFullpathAt($index)
        if( $AsFileSystemInfo ){
            Write-Output (Get-Item -LiteralPath $fullPath)
        }
        else{
            Write-Output $fullPath
        }
    }) #>

    for($i = 0; $i -lt $es.NumberOfResults; $i++ ){
        $fullPath = $es.ResultFullpathAt($i)
        if( $AsFileSystemInfo ){
            Write-Output (Get-Item -LiteralPath $fullPath)
        }
        else{
            Write-Output $fullPath
        }
    }
}