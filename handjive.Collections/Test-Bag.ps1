using namespace System.Collecitons

$mb = [MessageBuilder]::new()

function BagPrinter{
    param([object[]]$bags)
    $bags.foreach{
        '$bag has {0} elements (count without occurrences = {1}) below:' | InjectMessage $mb -FormatByStream $_.Count() $_.CountWithoutDuplicate -ForegroundColor Green -Bold -Flush 
        $mb.Helper.Line(80) | InjectMessage $mb -Flush
        $_.ValuesAndOccurrences().foreach{
            '(Occurrence={0}) [{1}] "{2}"' | InjectMessage $mb -FormatByStream $_.Occurrence $_.Value.Extension $_.Value.FullName -Flush
        }
        '' | InjectMessage $mb -Flush
    }

}


switch($args){
    1 { # 単純なオブジェクトによるテスト
        $bag1 = [Bag]::new()

        $adder = {
            param($aBag)
            $aBag.AddAll(@(1..10))
            $aBag.AddAll(@(2,4,6,8,10))
            $aBag.AddAll(@(1,3,5,7,9))
            $aBag.AddAll(@(1,3,5,7,9))
        }

        &$adder $bag1

        '$aBag1 has {0} elements (count without occurrences = {1}) below:' | InjectMessage $mb -FormatByStream $bag1.Count $bag1.CountWithoutDuplicate -ForegroundColor Green -Bold -Flush 
        $bag1 | InjectMessage $mb -OneLine -Delimiter ',' -Flush
        $bag1.Elements.foreach{
            write-host $_ ' ' -NoNewline
        }

        write-host ''
        'ValuesAndElements.foreach' | InjectMessage $mb -Flush
        $bag1.ValuesAndElements.foreach{
            '"{0}": [' | InjectMessage $mb -FormatByStream $_.Value -NoNewLine
            $_.Elements | InjectMessage $mb -OneLine -NoNewLine
            ']' | InjectMessage $mb -Flush
        }

        write-host ''
        'ValuesAndElements by Index' | InjectMessage $mb -Flush
        for($i=0; $i -lt $bag1.ValuesAndElements.Count; $i++){
            '"{0}": [' | InjectMessage $mb -FormatByStream $bag1.ValuesAndElements[$i].Value -NoNewLine
            $bag1.ValuesAndElements[$i].Elements | InjectMessage $mb -OneLine -NoNewLine
            ']' | InjectMessage $mb -Flush
        }

        'Values and Occurrences are:' | InjectMessage $mb -ForegroundColor Green -Bold -Flush
        $bag1.ValuesAndOccurrences | Select-Object Value,Occurrence | write-host
        write-host ''


        '----- Elements -----' | write-host
        $bag1.Elements | write-host

        '----- Remove 1 -----' | write-host
        $bag1.Remove(1)
        $bag1.ValuesAndOccurrences | Select-Object Value,Occurrence | write-host
        '----- Remove 1,1 -----' | write-host
        $bag1.RemoveAll(@(1,1))
        $bag1.ValuesAndOccurrences | Select-Object Value,Occurrence | write-host

        '----- Purge 3 -----' | write-host
        $bag1.Purge(3)
        $bag1.ValuesAndOccurrences | Select-Object Value,Occurrence | write-host

        '----- Purge 5,7 -----' | write-host
        $bag1.PurgeAll((5,7))
        $bag1.ValuesAndOccurrences | Select-Object Value,Occurrence | write-host

        '----- Includes and Occurrences of 1-10 ? -----' | write-host
        @(1..10).foreach{
            'Value {0}: Includes={1}, Occurrences={2}' | InjectMessage $mb -FormatByStream $_ $bag1.Includes($_) $bag1.OccurrencesOf($_) -Flush
        }
    }
    2 { # メンバを持つオブジェクトでのテスト
        $children = Get-ChildItem -Path . -Recurse
        $bag1 = [Bag]::new()
        $bag1.AddAll($children)

        '$bag1 has {0} elements, CountWithoutDuplicate={1}' | InjectMessage $mb -FormatByStream $bag1.Count $bag1.CountWithoutDuplicate -Flush
        write-host ''

        $bag1.Comparer = [AspectComparer]::new('Extension')
        'Set comparer by "Extension"' | InjectMessage $mb -Flush
        '$bag1 has {0} elements, CountWithoutDuplicate={1}' | InjectMessage $mb -FormatByStream $bag1.Count $bag1.CountWithoutDuplicate -Flush
        $mb.Helper.Line(80) | InjectMessage $mb -Flush
        $bag1.ValuesAndOccurrences.foreach{
            '"{0}" ({1})' | InjectMessage $mb -FormatByStream $_.Value $_.Occurrence -Flush
        }
        write-host ''
        $bag1.Comparer = [AspectComparer]::new('PSParentPath')
        'Set comparer by "PSParentPath"' | InjectMessage $mb -Flush
        '$bag1 has {0} elements, CountWithoutDuplicate={1}' | InjectMessage $mb -FormatByStream $bag1.Count $bag1.CountWithoutDuplicate -Flush
        $mb.Helper.Line(80) | InjectMessage $mb -Flush
        $bag1.ValuesAndOccurrences.foreach{
            '"{0}" ({1})' | InjectMessage $mb -FormatByStream $_.Value $_.Occurrence -Flush
        }
        write-host ''
    }
    4.1 { # 23/05/05 - 追加・修正部分の動作確認 OccurrencesOf,Includes,OccurrenceValuesOf
        $var1 = '-----1-----'
        $var2 = '-----2-----'
        $aBag = [Bag]::new()
        @(1..10).foreach{
            $aBag.Add($var1)
        }
        @(1..5).foreach{
            $aBag.Add($var2)
        }

        '$aBag has {0} elements' | InjectMessage $mb -FormatByStream $aBag.Count -Flush
        '$aBag includes "{0}"={1}' | InjectMessage $mb -FormatByStream $var1 $aBag.Includes($var1) -Flush
        '"{0}" has {1} occcurrences' | InjectMessage $mb -FormatByStream $var1 $aBag.OccurrencesOf($var1) -Flush
        $aBag.OccurrenceElementsOf($var1) | write-host
        $aBag.ValuesAndOccurrences.foreach{
            write-host $_
        }
    }
    4.2 {
        <#
        # AspectComparerを指定したBagがOccurrenceにどう振る舞うのが妥当なんだろ…?
        # ｷﾓﾁとしては↓こういう感じに書きたいんだけど、これでIncludes=true,OccurrencesOf = 54が返るようにするのはちとﾔﾔｺｼｲ。
        #
        # (・∀・) ちょっと整理したら上手くいった!! これでいくw!
        #>
        $filesAndDirectories = Get-ChildItem -Path . -Recurse
        $aBag = [Bag]::new($filesAndDirectories,[AspectComparer]::new('Extension'))
        $var1 = '.dll'
        '$aBag has {0} elements' | InjectMessage $mb -FormatByStream $aBag.Count -Flush
        '$aBag includes "{0}"={1}' | InjectMessage $mb -FormatByStream $var1 $aBag.Includes($var1) -Flush
        '"{0}" has {1} occcurrences' | InjectMessage $mb -FormatByStream $var1 $aBag.OccurrencesOf($var1) -Flush
        $aBag.OccurrenceElementsOf($var1) | write-host
        $aBag.ValuesAndOccurrences.foreach{
            write-host $_
        }
    }

    5.0 { # EnumerationとIndexing
        $files = Get-ChildItem -Path . -Recurse -File
        $aBag = [Bag]::new($files,[AspectComparer]::new('Extension'))
        '----- $aBag.foreach -----' | InjectMessage $mb -Flush
        $aBag.foreach{
            $_ | write-host
        }
        '----- $aBag[] -----' | InjectMessage $mb -Flush
        '($aBag has {0} elements)' | InjectMessage $mb -FormatByStream $aBag.Count -Flush
        for($i=0; $i -lt $aBag.Count; $i++ ){
            '[{0,3}] "{1}"' | InjectMessage $mb -FormatByStream $i $aBag[$i] -Flush
        }
    }
    5.1 { # ElementsOrdered,ElementsSorted
        $directories = Get-ChildItem -Path . -Recurse -Directory
        $aBag = [Bag]::new($directories,[AspectComparer]::new('Extension'))

        '----- Elements -----' | InjectMessage $mb -Flush
        $aBag.Elements.foreach{
            $args[0].Extension | InjectMessage $mb -Flush
        }
        '----- Elements by Index -----' | InjectMessage $mb -Flush
        '($aBag has {0} elements)' | InjectMessage $mb -FormatByStream $aBag.Count -Flush
        for( $i=0; $i -lt $aBag.Count; $i++ ){
            '[{0,2}]=>[{1}][{2}]' | InjectMessage $mb -FormatByStream $i $aBag.Elements[$i].Extension $aBag.Elements[$i].Name -Flush
        }
    }
    5.2 {  # ValuesAndOccurrencesOrdere,ValuesAnOccurrencesSorted
        $directories = Get-ChildItem -Path . -Recurse -Directory
        $aBag = [Bag]::new($directories,[AspectComparer]::new('Extension'))

        '----- ValuesAndOccurrences -----' | InjectMessage $mb -Flush
        $aBag.ValuesAndOccurrences.foreach{
            '[{0,-30}],[{1,3}]' | InjectMessage $mb -FormatByStream $_.Value $_.Occurrence -Flush
        }
        '----- ValuesAndOccurrencesOrdered by Index-----' | InjectMessage $mb -Flush
        '($aBag has {0} elements without duplicate)' | InjectMessage $mb -FormatByStream $aBag.CountWithoutDuplicate -Flush
        for( $i=0; $i -lt $aBag.CountWithoutDuplicate; $i++ ){
            $elem = $aBag.ValuesAndOccurrences[$i]
            '[{0,2}]=>[{1}],{2}' | InjectMessage $mb -FormatByStream $i $elem.Value $elem.Occurrence -Flush
        }
    }
    5.3 { # ValuesAndElements
        $files = Get-ChildItem -Path . -Recurse -File
        $aBag = [Bag]::new($files,[AspectComparer]::new('Extension'))

        '----- ValuesAndElements -----' | InjectMessage $mb -Flush -ForegroundColor Green -Bold
        $aBag.ValuesAndElements.foreach{
            '.' | write-host
            '[{0,-30}],[{1,3}]' | InjectMessage $mb -FormatByStream $_.Value $_.Elements.Count -Flush
            $mb.PushIndentLevel(1)
            $_.Elements | InjectMessage $mb -Format '>> {0}' -Flush
            $mb.PopIndentLevel()
        }

        '----- ValuesAndElements by Index-----' | InjectMessage $mb -Flush -ForegroundColor Green -Bold
        '($aBag has {0} elements without duplicate)' | InjectMessage $mb -FormatByStream $aBag.CountWithoutDuplicate -Flush
        for( $i=0; $i -lt $aBag.CountWithoutDuplicate; $i++ ){
            $value = $aBag.ValuesAndElements[$i]
            '[{0,2}]=>[{1}],{2}' | InjectMessage $mb -FormatByStream $i $value.Value $value.Elements.Count -Flush
            $mb.PushIndentLevel(1)
            $value.Elements | InjectMessage $mb -Format '{0}' -Flush
            $mb.PopIndentLevel()
        }
    }
}

