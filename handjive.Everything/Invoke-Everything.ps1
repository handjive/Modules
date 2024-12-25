using namespace handjive.Everything
using namespace handjive.MessageBuilder

function Invoke-Everything{
    [CmdletBinding(HelpURI="https://www.voidtools.com/support/everything/searching/")]
    Param(
        [Parameter(HelpMessage="検索起点とするパス(省略時はカレントディレクトリ)")][String]$QueryBase = "."
        ,[Parameter(HelpMessage="Everythingの検索コマンド",Mandatory)][AllowEmptyString()][String]$Operation = ""
        ,[Parameter(HelpMessage="Everythingのソート順指定フラグ")][ESAPI_SORT]$SortOrder = [ESAPI_SORT]::NAME_ASCENDING
        ,[Parameter(HelpMessage="結果の出力タイプ(Default=String)")][Type]$OutputType = [String]
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
    $es.ResultType = $OutputType

    $mb.NL()
    'Result count = {0} ({1})' | InjectMessage $mb -FormatByStream $es.NumberOfResults $es.LastError -NewLine -FlushIf $ShowDetail
    $es.Results.foreach{
        Write-Output $_
    }
}