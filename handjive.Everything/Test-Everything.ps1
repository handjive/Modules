using module handjive.Everything

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
        $es.ResultAt(0)|Write-Host
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
        $results = $es2.PerformQuery()
        $es2.LastError
        $es2.Results.Count
        #$es2.Results.foreach{ write-host $_.Name }

        $es2.SearchString = 'folder: "みんなあげ"'
        $es2.PerformQuery()
    }
}