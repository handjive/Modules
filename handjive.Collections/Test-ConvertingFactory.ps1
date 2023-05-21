$mb = [MessageBuilder]::new()
function BagPrinter{
    param([Bag]$Subject,[MessageBuilder]$Builder)
    $Subject.ValuesAndElements.foreach{
        $value,$elements = $_.value,$_.Elements
        '"{0}" => {{ ' | InjectMessage $Builder -FormatByStream $value
        $Builder.PushIndentLevel(1)
        $elements.foreach{
            InjectMessage $Builder $args[0].Name
        }
        $Builder.PopIndentLevel()
        '}' | InjectMessage $Builder -Flush
    }
}
function SimplePrinter{
    param([Collections.Generic.IEnumerable[object]]$Subject,[MessageBuilder]$Builder)
    $Subject.foreach{
        '[{0}] {1}' | InjectMessage $Builder -FormatByStream $_.gettype() $_ -Flush
    }
}

function Print{
    param([Collections.Generic.IEnumerable[object]]$Subject,[MessageBuilder]$Builder)
 
    $count = if( $Subject -is [Bag] ){ $Subject.ValuesAndElements.Count } else{ $Subject.Count }
    '(result type is {0}, count={1})' | InjectMessage $Builder -FormatByStream $Subject.gettype() $count -Flush -Italic
    if( $Subject -is [Bag] ){
        BagPrinter -Subject $Subject -Builder $Builder
    }
    else{
        SimplePrinter -Subject $Subject -Builder $Builder
    }
    write-host ''
}

switch($args[0]){
    1.1 { # Quoter: WithSelectionBy
        $files = Get-ChildItem -Path . -File -Recurse
        $bag = [Bag]::new($files,[AspectComparer]::new('Extension'))

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag)
            '----- WithSelectionBy using {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithSelectionBy({ $args[0].Extension -eq '.dll' })
            '(result type is {0}, count={1})' | InjectMessage $mb -FormatByStream $result.gettype() $result.Count -Flush -Italic
            $result.foreach{
                '{0}' | InjectMessage $mb -FormatByStream $_.Name -Flush
            }
            write-host ''
        }
    }
    1.2 { # Quoter: WithIntersect([Bag])
        $files = Get-ChildItem -Path . -File -Recurse

        $bag1 = [Bag]::new($files,[AspectComparer]::new('PSParentPath'))
        $bag2 = [BagToBagQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.dll' }) # 拡張子が.dllのファイルを抽出
        #$bag2.Comparer = [AspectComparer]::new('PSParentPath')  # 親パスで集約

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)    
            '----- WithIntersect([Bag]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithIntersect($bag2)  # .dllを含むフォルダの内容
            Print -Subject $result -Builder $mb
        }
    }
    1.3 { # Quoter: WithIntersect([IEnumerable[object],[ScriptBlock])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files,[AspectComparer]::new('PSParentPath'))
        $bag2 = [BagToBagQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.dll' })

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithIntersect([Bag],[ScriptBlock]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithIntersect($bag2,{ $args[0].PSParentPath }) 
            Print -Subject $result -Builder $mb
        }
    }
    1.4 { # Quoter: WithIntersectByValues([IEnumerable[object])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files,[AspectComparer]::new('Extension'))

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithIntersectByValues([IEnumerable[object]]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithIntersectByValues(@('.dll')) 
            Print -Subject $result -Builder $mb
        }
    }
    1.5 { # Quoter: WithExcept([Bag])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files,[AspectComparer]::new('PSParentPath'))
        $bag2 = [BagToBagQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.dll' })
        $bag2.Comparer = [AspectComparer]::new('PSParentPath')

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithExcept([Bag]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithExcept($bag2)     # .dllを含まないフォルダの内容
            Print -Subject $result -Builder $mb
        }
    }
    1.6 { # Quoter: WithExcept([IEnumerable[object]],[ScriptBlock])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files,[AspectComparer]::new('PSParentPath'))
        $bag2 = [BagToBagQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.dll' })

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithExcept([IEnumerable[object]],[ScriptBlock]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithExcept($bag2,{ $args[0].PSParentPath })     # .dllを含まないフォルダの内容
            Print -Subject $result -Builder $mb
        }
    }
    1.7 { # Quoter: WithExceptByValues([IEnumerable[object]])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files,[AspectComparer]::new('Extension'))

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithExceptByValues([IEnumerable[object]]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithExceptByValues(@('.dll','.cs'))     # .dllを含まないフォルダの内容
            Print -Subject $result -Builder $mb
        }
    }
    1.8 { # Quoter: WithMaxBy([String])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files)

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithMaxBy([String]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithMaxBy('LastWriteTime')     # 最終書き込み日が最大のファイル
            Print -Subject $result -Builder $mb
        }
    }
    1.9 { # Quoter: WithMaxBy([ScriptBlock])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files)

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithMaxBy([ScriptBlock]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithMaxBy({ $args[0].Length })     # サイズが最大のファイル
            Print -Subject $result -Builder $mb
        }
    }
    1.A { # Quoter: WithMinBy([String])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files)

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithMinBy([String]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithMinBy('Length')       # サイズが最小のファイル
            Print -Subject $result -Builder $mb
        }
    }
    1.B { # Quoter: WithMinBy([ScriptBlock])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files)

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)
            '----- WithMinBy([ScriptBlock]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithMinBy({ $args[0].Length })       # サイズが最小のファイル
            Print -Subject $result -Builder $mb
        }
    }
    1.C { # Quoter: WithUnion([Bag])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files,[AspectComparer]::new('PSParentPath'))
        $bag2 = [BagToBagQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.dll' })
        $bag3 = [BagToBagQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.json' })

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag2)
            '----- WithUnion([Bag]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithUnion($bag3)     # .dllを含まないフォルダの内容
            Print -Subject $result -Builder $mb
        }
    }
    1.D { # Quoter: WithUnion([Bag])
        $files = Get-ChildItem -Path . -File -Recurse
        $bag1 = [Bag]::new($files,[AspectComparer]::new('PSParentPath'))
        $enumerable = [BagToEnumerableQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.dll' })
        $bag3 = [BagToBagQuoter]::new($bag1).WithSelectionBy({ $args[0].Extension -eq '.json' })

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag3)
            '----- WithUnion([IEnumerable[object]]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithUnion($enumerable)     # .dllを含まないフォルダの内容
            Print -Subject $result -Builder $mb
        }
    }
    2.1 { # Extractor: WithSelectionBy
        $files = Get-ChildItem -Path . -File -Recurse
        $bag = [Bag]::new($files,[AspectComparer]::new('Extension'))
    
        #@( ,,[] ).foreach{
        $extractor = [BagToEnumerableExtractor]::new($bag)
        '----- WithSelectionBy using {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
        'bag.Count = {0}' | InjectMessage $mb -FormatByStream $bag.Count -Flush
        $result = $extractor.WithSelectionBy({ $args[0].Extension -eq '.dll' })
        $count = [Linq.Enumerable]::Count[object]($result)
        'result type is {0}, count={1} / bag.Count = {2}' | InjectMessage $mb -FormatByStream $result.gettype() $count $bag.Count -Flush -Italic

        $result.foreach{
            '{0}' | InjectMessage $mb -FormatByStream $_.Name -Flush
        }
        write-host ''

        $bag = [Bag]::new($files,[AspectComparer]::new('Extension'))
        $extractor = [BagToBagExtractor]::new($bag)
        '----- WithSelectionBy using {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
        'bag.Count = {0}' | InjectMessage $mb -FormatByStream $bag.Count -Flush
        $result = $extractor.WithSelectionBy({ $args[0].Extension -eq '.dll' })
        $count = $result.Count
        'result type is {0}, count={1} / bag.Count = {2}' | InjectMessage $mb -FormatByStream $result.gettype() $count $bag.Count -Flush -Italic

        $result.foreach{
            '{0}' | InjectMessage $mb -FormatByStream $_.Name -Flush
        }
        write-host ''

        $bag = [Bag]::new($files,[AspectComparer]::new('Extension'))
        $extractor = [BagToSetExtractor]::new($bag)
        '----- WithSelectionBy using {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
        'bag.Count = {0}' | InjectMessage $mb -FormatByStream $bag.Count -Flush
        $result = $extractor.WithSelectionBy({ $args[0].Extension -eq '.dll' })
        $count = $result.Count
        'result type is {0}, count={1} / bag.Count = {2}' | InjectMessage $mb -FormatByStream $result.gettype() $count $bag.Count -Flush -Italic

        $result.foreach{
            '{0}' | InjectMessage $mb -FormatByStream $_.Name -Flush
        }
        write-host ''
    }
    3 {
        [BagToEnumerableQuoter]::GetInstaller().InstallOn([Bag])
        [BagToBagQuoter]::GetInstaller().InstallOn([Bag])
        [BagToSetQuoter]::GetInstaller().InstallOn([Bag])
        [BagToEnumerableExtractor]::GetInstaller().InstallOn([Bag])
        [BagToBagExtractor]::GetInstaller().InstallOn([Bag])
        [BagToSetExtractor]::GetInstaller().InstallOn([Bag])
    }
    4 {
        $files = Get-ChildItem -Path . -File -Recurse
        $bag = [Bag]::new($files,[AspectComparer]::new('Extension'))
        $bag.QuoteTo([Bag]).WithSelectionBy({ $args[0].Extension -eq '.dll' })
    }
}