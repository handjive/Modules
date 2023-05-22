using namespace handjive.Collections
class TestData{
    $a
    $b
    $c

    TestData($a,$b,$c){
        $this.a = $a
        $this.b = $b
        $this.c = $c
    }


}

$mb = [MessageBuilder]::new()
$files = Get-ChildItem -Path . -File -Recurse

switch($args){
    1 { # Linq.Enumerableを使用したソートの習作
        $sortKeys = [Collections.ArrayList]::new(@( 'Extension',{ $args[0].BaseName },'LastWriteTime','Length' ))
        if( $sortKeys[0] -is [ScriptBlock] ){
            $keySelector = $sortKeys[0]
        }
        else{
            $keySelector = ([AspectComparer]::new($sortKeys[0]).GetSubjectBlock)
        }
        $comparer = [SortingComparer]::DefaultDescending()
        $sortKeys.RemoveAt(0)
        $sorted = [Linq.Enumerable]::OrderBy[object,object]($aList,[func[object,object]]$keySelector,$comparer)
        $sortKeys.foreach{
            if( $_ -is [ScriptBlock] ){
                $keySelector = $_
            }
            else{
                $keySelector = ([AspectComparer]::new($_).GetSubjectBlock)
            }
            
            $sorted = [Linq.Enumerable]::ThenBy[object,object]($sorted,[func[object,object]]{ $args[0].Length},$comparer)
        }

        $sorted.foreach{
            '{0} {1} {2}' | InjectMessage $mb -FormatByStream $_.LastWriteTime $_.Length $_.Name -Flush
        }
    }
    2 { # プロトタイプ
        $aList = [Collections.Generic.List[object]]::new($files)
        $sorter = [EnumerableSorter]::new($aList)
        $sorted = $sorter.Sort(([SortCondition]::Ascending('LastWriteTime'),[SortCondition]::Ascending('Name'),[SortCondition]::Descending('Length')))
        
        $sorted.foreach{
            '{0} {1} {2}' | InjectMessage $mb -FormatByStream $_.LastWriteTime $_.Length $_.Name -Flush
        }
    }
    3.1 { # EnumerableSorterのテスト
        $aList = [Collections.Generic.List[object]]::new()
        @(1..10).foreach{
            $a = $_
            @(1..10).foreach{
                $b = $_
                @(1..10).foreach{
                    $td = [TestData]::new($a,$b,$_)
                    $aList.Add($td)
                }
            }
        }
        $sorter = [EnumerableSorter]::new($aList)
        $sorted1 = $sorter.Sort(([SortCondition]::Descending('a'),[SortCondition]::Ascending({ $args[0].b }),[SortCondition]::Descending('c')))
        [Linq.Enumerable]::Count[object]($sorted1)
    }
    3.2 {
        $aList = [Collections.Generic.List[object]]::new()
        @(1..10).foreach{
            $a = $_
            @(1..10).foreach{
                $b = $_
                @(1..10).foreach{
                    $td = [TestData]::new($a,$b,$_)
                    $aList.Add($td)
                }
            }
        }
        $sorter = [EnumerableSorter]::new($aList)
        $sorted2 = $sorter.Sort(@('a:a','a:{ $args[0].b }','d:c'))
        [Linq.Enumerable]::Count[object]($sorted2)
    }
}
