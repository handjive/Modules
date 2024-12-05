using module handjive.Everything

import-module handjive.Everything
function hoge
{
    Write-Host 'HOGEeeee!!'
}


class TestElement : EverythingSearchResultElement{
    [string]$hoge
    [string]$tara

    OnInjectionComplete([object]$elem){
    }
}

switch($args){
    1 {
        $block = {
            param($elem)
            if( $null -eq $elem ){
                Write-Host '$elem is null'
            }
            
            !$elem.ContainerPath.contains('ニート')
        }

        $es = new-object Everything
        $es.QueryBase = 'C:\Users\handjive\Documents\書架\BooksArchive'
        $es.PerformQuery('folder: "[炬とうや×藤森フクロウ] 転生したら悪役令嬢だったので引きニートになります"')
        $es.Results[0]|Write-Host
        $result = $es.SelectResult($block)

        $result[0].Name
    }
    2 {
        $es2 = [Everything]::new()
        $es2.PostBuildElementListeners.Add(@(),{
            param($elem)
            $elem.Name | Write-Host
        })
        
        $es2.QueryBase = 'C:\Users\handjive\Documents\書架\BooksArchive'
        $es2.SearchString = 'folder: "げんしけん"'
        $es2.PerformQuery()
        $es2.LastError
        $es2.Results.Count
        $results = $es2.Results
        #$es2.Results.foreach{ write-host $_.Name }

        $es2.SearchString = 'folder: "みんなあげ"'
        $es2.PerformQuery()

        if( $results[0] -ge $es2.Results[0] ){
            write-host 'HOGE!'
        }
        else{
            write-host 'TARA...'
        }
    }
    3 {
        <#
         GetEnumerator()を追加したことによる変更のテスト 
        #>

        $mb = [MessageBuilder]::new()
        # Enumeratorのテスト
        # Resultsとの整合性について重視
        $es2 = [Everything]::new()
        $es2.QueryBase = 'C:\Users\handjive\Documents\書架\BooksArchive'
        $es2.SearchString = 'folder: "げんしけん"'
        $es2.PostBuildElementListeners.Add(@(),{
            param($elem)
            '>>',$elem.Name | InjectMessage $mb -Oneline -Flush -Italic
        })

        $es2.PerformQuery()

        'From enumerator(1: movenext()->Current)' | InjectMessage $mb -Flush -ForegroundColor Green -Bold
        $results = $es2.GetEnumerator()
        while($results.MoveNext()){
            $results.Current.Name | InjectMessage $mb -Flush
        }
        
        'From enumerator(2: foreach)' | InjectMessage $mb -Flush -ForegroundColor Green -Bold
        $es2.GetEnumerator().foreach{
            
            $_.Name | InjectMessage $mb -Flush
        }
        
        'After GetEnumerator(), internal result collection is null? => {0}' | InjectMessage $mb -FormatByStream ($null -eq $es2.wpvResults) -Flush

        'From Everything.Results[]' | InjectMessage $mb -Flush -ForegroundColor Green -Bold
        $es2.Results.foreach{
            $_.Name | InjectMessage $mb -Flush
        }
    }
    4 {
        [Everything]::Search('c:\users\handjive\Documents\書架\BooksArchive','ダンジョン')
    }

    5 {
        # ResultIndexDo
        $es = [Everything]::new()
        $es.QueryBase = '.'
        $es.SearchString = '*.psd1'
        $es.PerformQuery()

        Write-Host $es.NumberOfResults
        Write-Host '-------------'

        $es.ResultIndexDo({
            param($index)
            Write-Host $es.ResultFullpathAt($index)
        })

        $es.SearchString = '*.psd1m' #存在しないファイル、検索結果0
        $es.PerformQuery()

        Write-Host $es.NumberOfResults
        Write-Host '-------------'

        $es.ResultIndexDo({
            param($index)
            Write-Host $es.ResultFullpathAt($index)
        })

    }
}