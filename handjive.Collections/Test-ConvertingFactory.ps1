$mb = [MessageBuilder]::new()
function BagPrinter{
    param([Bag]$Subject,[MessageBuilder]$Builder)
    $Subject.ValuesAndElements.foreach{
        $value,$elements = $_
        '"{0}" => {{ ' | InjectMessage $Builder -FormatByStream $value
        $Builder.PushIndentLevel(1)
        $elements.foreach{
            InjectMessage $Builder $_.Name
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
 
    $countSubject = if( $Subject -is [Bag] ){ $Subject.ValuesAndElements } else{ $Subject }
    $count = [Linq.Enumerable]::Count[object]($countSubject)
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
        $bag2.Comparer = [AspectComparer]::new('PSParentPath')  # 親パスで集約

        @( [BagToEnumerableQuoter],[BagToBagQuoter],[BagToSetQuoter] ).foreach{
            $quoter = $_::new($bag1)    
            '----- WithIntersect([Bag]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithIntersect($bag2)  # .dllを含むフォルダのファイル
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
            '----- WithIntersectByValues([Bag]) {0} -----' | InjectMessage $mb -FormatByStream $_.Name -Flush -ForegroundColor Green -Bold
            $result = $quoter.WithIntersectByValues(@('.dll')) 
            Print -Subject $result -Builder $mb
        }
    }
        <#
        [BagToBagQuoter]
        [BagToSetQuoter]

        [BagToEnumerableExtractor]
        [BagToBagExtractor]
        [BagToSetExtractor]
        #>
}