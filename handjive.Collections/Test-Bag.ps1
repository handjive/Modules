using module handjive.Collections
using module handjive.ChainScript
using module handjive.Everything

switch($args){
    1{
        # Sort-order: Ascending
        $mb = [MessageBuilder]::new()

        # デフォルト(ソート: Ascending)
        $aBag = [Bag]::new()
        [Interval]::new(9,1,2).ForEach{ 
            $_ | InjectMessage $mb -format 'Adding {0}' -Flush
            $aBag.Add($_) 
        }
        '----- Ordered -----' | InjectMessage $mb -Flush
        $aBag.ValuesOrdered | InjectMessage $mb -Flush -Oneline

        '----- Sorted by Default(Ascending) -----' | InjectMessage $mb -Flush
        $aBag.ValuesSorted | InjectMessage $mb -Flush -OneLine

        '----- Changing Comparer to Desending -----' | InjectMessage $mb -Flush
        $aBag.Comparer = [PluggableComparer]::DefaultDescending()
        $aBag.ValuesSorted | InjectMessage $mb -Flush -oneline

    }
    1.1{
        # Sort-order: Ascending
        $mb = [MessageBuilder]::new()

        # 明示的ソート指定: Ascending
        $aBag = [Bag]::new([PluggableComparer]::DefaultAscending())
        [Interval]::new(9,1,2).ForEach{ 
            $_ | InjectMessage $mb -format 'Adding {0}' -Flush
            $aBag.Add($_) 
        }
        '----- Ordered -----' | InjectMessage $mb -Flush
        $aBag.ValuesOrdered | InjectMessage $mb -Flush -Oneline

        '----- Sorted by Default(Ascending) -----' | InjectMessage $mb -Flush
        $aBag.ValuesSorted | InjectMessage $mb -Flush -OneLine

        '----- Changing Comparer to Asending -----' | InjectMessage $mb -Flush
        $aBag.Comparer = [PluggableComparer]::DefaultDescending()
        $aBag.ValuesSorted | InjectMessage $mb -Flush -oneline
    }
    1.2 {
        # a Bag from the Bag & デフォルトソート
        $mb = [MessageBuilder]::new()

        $aBag1 = [Bag]::new()
        $aBag1.AddAll([Interval]::new(20,1,2))
        $elementsOrdered = $aBag1.ElementsOrdered
        $elementsSorted = $aBag1.ElementsSorted
        '----- ElementsOrdered -----' | InjectMessage $mb -Flush
        $aBag1.ElementsOrdered.foreach{ $_.Value,$_.Occurrence | InjectMessage $mb -OneLine -Flush }
        '----- Enumerate Bag directory -----' | InjectMessage $mb -Flush
        $aBag1.foreach{ $_.Value,$_.Occurrence | InjectMessage $mb -OneLine -Flush }
        '----- ElementsSorted -----' | InjectMessage $mb -Flush
        $aBag1.ElementsSorted.foreach{ $_.Value,$_.Occurrence | InjectMessage $mb -OneLine -Flush }

        $aBag1.foreach{ $_.Value,$_.Occurrence | InjectMessage $mb -OneLine -Flush }

        $aBag2 = [Bag]::new($aBag1)
        $aBag3 = [Bag]::new([Interval]::new(1,100,9))

        '----- ValuesOrdered -----' | InjectMessage $mb -Flush
        $aBag2.ValuesOrdered | InjectMessage $mb -Flush -Oneline

        '----- ValuesSorted by Default(Ascending) -----' | InjectMessage $mb -Flush
        $aBag2.ValuesSorted | InjectMessage $mb -Flush -OneLine

        '----- Changing Comparer to Desending -----' | InjectMessage $mb -Flush
        $aBag2.Comparer = [PluggableComparer]::DefaultDescending()
        $aBag2.ValuesSorted | InjectMessage $mb -Flush -oneline

        
    }
    1.3 {
        $mb = [MessageBuilder]::new()
        $aBag = [Bag]::new([interval]::new(1,10,1))
        $aBag.AddAll([interval]::new(1,10,2))
        $aValue = $aBag[[int]3]
        '$aBag[[int]{0}] is "{1}"' | InjectMessage $mb -FormatByStream 3 $aValue -Flush
        @(1..10).foreach{
            '$aBag[[object]{0}] is "{1}"' | InjectMessage $mb -FormatByStream $_ $aBag[[object]$_] -Flush
        }
        @(-5..15).foreach{
            '$aBag.Includes({0}) => {1}' | InjectMessage $mb -FormatByStream $_ $aBag.Includes([object]$_) -Flush
        }
    }

    2 {
        $mb = [MessageBuilder]::new()
        $autherAndTitles = [Bag]::new() # key=auther, occurrence=number of title
        $autherAndTitles.AddAll((Get-Content -path .\Authers.txt))
        '{0} authers listed.' | InjectMessage $mb -FormatByStream $autherAndTitles.Keys.Count -Flush
        $autherIndex = [Bag]::new() # key = Initial letter, value = auther name
        $autherIndex.GetKeyBlock = { ($args[0])[0] }
        $autherIndex.AddAll($autherAndTitles.Keys)
        $autherIndex.Keys.foreach{
            "[{0}]`t" | InjectMessage $mb -FormatByStream $_ -Flush -Bold -NoNewLine
           (StreamAdaptor $autherIndex.ValueAtKey($_) -collect{ [String]::Format('{0}({1})',$args[0],$autherAndTitles.ValueAtKey($args[0]).Count)} )| InjectMessage $mb  -OneLine -Delimiter ',' -Flush
        }

        #'Occurrences of "{0}" is {1}' | InjectMessage $mb -FormatByStream $key $aBag.OccurrencesOf($key) -Flush
    }
    3 { 
        $xh = [xhashtable]::new()
        $mb = [MessageBuilder]::new()

        @(1,3,5,7,9).foreach{ $xh.Add($_) }
        @(3,7).foreach{ $xh.Add($_) }

        $xh.Keys.foreach{
            'Occuerrences of "{0}" is "{1}"' | InjectMessage $mb -FormatByStream $_ $xh.OccurrencesOf($_) -Flush
        }
        @(1..10).foreach{
            'Is includes {0}? => {1}' | InjectMessage $mb -FormatByStream $_ $xh.Includes($_) -Flush
        }
        $xh[1] | write-host
        $xh.3 | write-host
        '----- keys -----' | InjectMessage $mb
        $xh.Keys | InjectMessage $mb -NewLine -Flush

        '----- Values -----' | InjectMessage $mb
        $xh.Values | InjectMessage $mb -NewLine -Flush
        
        '----- Set GetKeyBlock -----' | InjectMessage $mb
        $xh.GetKeyBlock = { ($args[0])[0] }     # 
        $xh.Keys | InjectMessage $mb -NewLine -Flush
        $xh.Values | InjectMessage $mb -NewLine -Flush

        '----- After set GetKeyBlock -----' | InjectMessage $mb
        $xh.GetKeyBlock | InjectMessage $mb -NewLine -Flush

        '----- Set dictionay value, same name -----' | InjectMessage $mb
        $xh['GetKeyBlock'] = 10
        $xh.Keys | InjectMessage $mb -NewLine -Flush
        $xh['GetKeyBlock'] | InjectMessage $mb -NewLine -Flush
        $xh.GetKeyBlock | InjectMessage $mb -NewLine -Flush
        $xh.Values | InjectMessage $mb -NewLine -Flush
    }
    3.1 { 
        $dht = [DerivedHT]::new()

        @(1,3,5,7,9).foreach{ $dht.Add($_) }
        @(3,7).foreach{ $dht.Add($_) }

        '----- keys -----' | Write-Host
        $dht.Keys | Write-Host

        '----- Values -----' | Write-Host
        $dht.Values | Write-Host

        <#$dht.Keys.foreach{
            [String]::Format('Occuerrences of "{0}" is "{1}"',$_,$dht.OccurrencesOf($_)) | Write-Host
        }
        @(1..10).foreach{
            [String]::Format('Is includes {0}? => {1}',$_ ,$dht.Includes($_)) | Write-Host
        }#>

        <#
        $xh.Keys.foreach{
            [String]::Format('Occuerrences of "{0}" is "{1}"',$_,$xh.OccurrencesOf($_)) | Write-Host
        }
        @(1..10).foreach{
            [String]::Format('Is includes {0}? => {1}',$_ ,$xh.Includes($_)) | Write-Host
        }
        $xh.GetKeyBlock = { ($args[0])[0] }
        $xh.Keys | InjectMessage $mb -NewLine -Flush
        $xh.Values | InjectMessage $mb -NewLine -Flush

        $xh.GetKeyBlock | InjectMessage $mb -NewLine -Flush
        $xh['GetKeyBlock'] = 10
        $xh.Keys | InjectMessage $mb -NewLine -Flush
        $xh['GetKeyBlock'] | InjectMessage $mb -NewLine -Flush
        $xh.GetKeyBlock | InjectMessage $mb -NewLine -Flush
        $xh.Values | InjectMessage $mb -NewLine -Flush
        #>
    }
    4 {
        $mb = [MessageBuilder]::new()
        $aBag = [Bag]::new()
        $aBag.Add('Hoge')
        $aBag.HOGE | write-host
    }
    5 {
        $dht = [DelivedHT]::new()
        $dht.Add(1,'one')
        $dht.Keys | write-host
    }
    6 {
        <#  Values
            Includes
            OccurrencesOf
            [[int]$index] (keys[$index]を返す)
            Add
            AddAll
            Remove
            RemoveAll
            Count
        #>
        $aBag = [Bag]::new()
        $mb = [MessageBuilder]::new()

        @( 1,3,5,7,9 ).foreach{ $aBag.Add($_) }
        $aBag.AddAll(@(1,5,9))
        '----- Values -----' | InjectMessage $mb
        $aBag.Values | InjectMessage $mb -NewLine -Flush

        '----- Includes -----' | InjectMessage $mb
        @(1..10).foreach{
            '$aBag includes {0} => {1}' | InjectMessage $mb -FormatByStream $_ $aBag.Includes($_) -Flush
        }

        '----- OccurrencesOf -----' | InjectMessage $mb
        $aBag.Values.foreach{
            'Occurrences of "{0}" => {1}' | InjectMessage $mb -FormatByStream $_ $aBag.OccurrencesOf($_) -Flush
        }

        '----- Remove -----' | InjectMessage $mb
        $aBag.Remove(1)
        $aBag.Values | InjectMessage $mb -Flush

        '----- RemoveAll -----' | InjectMessage $mb
        $aBag.RemoveAll(@(3,5))
        $aBag.Values | InjectMessage $mb -Flush

        '----- Count and Index accessing -----' | InjectMessage $mb
        $aBag.Count | InjectMessage $mb -Format '$aBag has {0} elemnts' -Flush -NewLine
        for( $i=0; $i -le $aBag.Count-1; $i++ ){
            '$aBag[{0}] => {1}' | InjectMessage $mb -FormatByStream $i $aBag[$i] -Flush
        }

        '----- ValueAndOccurrences -----' | InjectMessage $mb -Flush
        $aBag.ValuesAndOccurrences.foreach{
            'Value: "{0}" has {1} occurrences' | InjectMessage $mb -FormatByStream $_.value $_.Occurrences -Flush
        }
    }
    7 {
        $mb = [MessageBuilder]::new()
        $ixb = [IndexedBag]::new()
        $ixb.GetIndexBlock = { ($args[0])[0] } # 最初の一文字がキー
        $ixb.AddAll((Get-Content -path .\Authers.txt))
        '----- keys -----' | InjectMessage $mb -Flush
        $keys = $ixb.Keys
        $keys.count | InjectMessage $mb -Flush
        $keys.foreach{
            'Key [{0}] has {1} occurrences' | InjectMessage $mb -FormatByStream $_ $ixb.keysOccurrencesOf($_) -Flush
        }
        '----- values -----' | InjectMessage $mb -Flush
        $ixb.Values.Count | InjectMessage $mb -Flush

        $a = $ixb['六']
        $a.gettype() | Write-Output
        $a[0].gettype()| Write-Output
        $a | write-Output
        $b = $ixb[0]
        $b.gettype() | Write-Output
        $b[0].gettype()|write-output
        $b | write-output

        '----- keys and values -----' | InjectMessage $mb -Flush
        $ixb.IndicesAndValues.Count | InjectMessage $mb -Flush
        $ixb.IndicesAndValues.foreach{
            'Key={0} Value={1}' | InjectMessage $mb -FormatByStream $_.Key $_.Value -Flush
        }

        '----- key, value, occurrences -----' | InjectMessage $mb -Flush
        $ixb.IndicesAndValuesAndOccurrences.foreach{
            'Key="{0,-5}" Value="{1,-40}" Occurrences={2}' | InjectMessage $mb -FormatByStream $_.Key $_.Value $_.Occurrences -Flush
        }
    }
    8 {
        $ab = [OrderedBag]::new()
        @(1..100).foreach{ $ab.Add(([String]::Format('Value{0}',$_))) }
        [Interval]::new(1,100,2).foreach{ $ab.Add(([String]::Format('Value{0}',$_))) }
        $od = $ab.Substance
        $keyEnum = $od.Keys.GetEnumerator()
        $keyEnum.foreach{ Write-Host $_ }
        $ab.Values.foreach{ write-host $_ }
        $ab.ValuesAndOccurrences.foreach{ 
            Write-Host $_.Value $_.Occurrences }
        $ab[18] | write-host
        $ab['Value18'] | Write-Host
        $ab.Value18 | Write-host

        [Interval]::new(10,100,10).foreach{ $ab.Remove(([String]::Format('Value{0}',$_)))}
        $ab.ValuesAndOccurrences.foreach{
             Write-Host $_.Value $_.Occurrence }

        #[Linq.Enumerable]::OrderBy([Linq.Enumerable]::Where($inputCollection, ...), ...)
        #while( $ab.MoveNext() ){
            #$ab.Current | write-host
        #}
        
        $aCollection = $ab.ValuesAndOccurrences.ToArray()
        #$aCollection = $ab.Substance.Keys
        #$aCollection = 1..100
        $sorted = [System.Linq.Enumerable]::OrderByDescending($ab, [Func[object,object]]{ $args[0].Occurrence })
        $enum = $sorted.GetEnumerator()
        while($enum.MoveNext()){
            write-host $enum.Current.Value $enum.Current.Occurrence
        }

        StreamAdaptor -FindLast {$args[0].Occurrence -eq 1 } -Subject $ab | Select-Object -Property Value,Occurrence
        $ab | StreamAdaptor -Find { $args[0].Occurrence -eq 2 } | Select-Object -Property Value,Occurrence
        

        $ab | StreamAdaptor -FindLast { $args[0].Occurrence -eq 3 } -ifAbsent { ([BagElement]::new('hoge',0)) } | Select-Object -Property Value,Occurrence
        $ab | StreamAdaptor -Find { $args[0].Occurrence -eq 3 } -ifAbsent { ([BagElement]::new('hoge',0)) } | Select-Object -Property Value,Occurrence
    }
    9 {
        $ixb  = [IndexedBag]::new()

        $ixb.GetIndexBlock = { $args[0].Substring(0,1) }
        $ixb.AddAll((Get-Content -path .\Authers.txt))
        #$ixb.Values 
        #$ixb.ValuesAndOccurrences.foreach{ Write-Host $_.Value $_.Occurrence }

        $ixb.Count 
        $ixb[752].foreach{ write-host $_.Value $_.Occurrence }
        $ixb.IndexesAndValuesAndOccurrences.foreach{ Write-Host $_.index $_.Value $_.Occurrence }
        <#
        $ixb.GetIndexBlock = { ($args[0])[0] }
        $ixb.Add("あんぱん")
        $ixb.Add("あんぽんたん")
        $ixb.Add("あんぽんたん")
        $ixb.Add("あんぽんたん")
        $ixb.Add("あんかけ")
        $ixb.Add("あんちょび")
        $ixb.Add("あんちょび")
        $ixb
        野 野間与太郎 1
野 野々村朔 1
野 野崎まど 1
野 野崎つばた 1
野 野人 1
野 野口芽衣 1
野 野田彩子 1
野 野営地 1
野 野宮けい 1
野 野上武志 1
野 野山歩 1
野 野良おばけ 1
野 野呂俊介 1
野 野村宗弘 1
野 野口賢 1

野 野々村朔 1
野 野上武志 1
野 野人 1
野 野口芽衣 1
野 野口賢 1
野 野呂俊介 1
野 野営地 1
野 野宮けい 1
野 野山歩 1
野 野崎つばた 1
野 野崎まど 1
野 野村宗弘 1
野 野田彩子 1
野 野良おばけ 1
野 野間与太郎 1

野 野間与太郎 1
野 野良おばけ 1
野 野田彩子 1
野 野村宗弘 1
野 野崎まど 1
野 野崎つばた 1
野 野山歩 1
野 野宮けい 1
野 野営地 1
野 野呂俊介 1
野 野口賢 1
野 野口芽衣 1
野 野人 1
野 野上武志 1
野 野々村朔 1


        #>
    }
    10 {
        $mb = [MessageBuilder]::new()
        $testdata = @( '花沢健吾','花沢健吾','花沢健吾','若木民喜','荒井春太郎','荒井春太郎','莉ジャンヒュン','菅原キク','萩埜まこと','萩尾望都','藤間麗','西義之','ナイーブタ','西餅' )
        $ixb = [IndexedBag]::new()
        $ixb.GetIndexBlock = { [string]($args[0][0]) }  # 先頭一文字でインデックス
        $testdata.foreach{ $ixb.Add($_) }

        $ixb.Count | InjectMessage $mb -Format 'Bag.Count = {0}' -Flush

        '----- Values Ordered -----' | InjectMessage $mb -Flush
        $ixb.ValuesOrdered | InjectMessage $mb -Flush
        '----- Values Sorted -----' | InjectMessage $mb -Flush
        $ixb.ValuesSorted | InjectMessage $mb -Flush

        '----- Indexes -----' | InjectMessage $mb -Flush
        $ixb.Indexes | InjectMessage $mb -Flush

        $sorted = $ixb.ElementsSorted
        while($sorted.MoveNext()){
            $elem = $sorted.Current
            'Index={0}, Value={1}, Occurrence={2}' | InjectMessage $mb -FormatByStream $elem.Index $elem.Value $elem.Occurrence -Flush
        }
        $ordered = $ixb.ElementsOrdered
        while($ordered.MoveNext()){
            $elem = $ordered.Current
            'Index={0}, Value={1}, Occurrence={2}' | InjectMessage $mb -FormatByStream $elem.Index $elem.Value $elem.Occurrence -Flush
        }

        for($i=0; $i -lt $ixb.Count; $i++){
            '$ixb[{0}] => "{1}"' | InjectMessage $mb -FormatByStream $i $ixb[$i] -Flush
        }

        (1..5).foreach{ 
            $ixb.OccurrencesOf('花沢健吾') | InjectMessage $mb -Flush
            $ixb.Remove('花沢健吾')
        }
        $testdata.foreach{
             '$ixb.Includes({0}) => {1}' | InjectMessage $mb -FormatByStream $_ $ixb.Includes($_) -Flush
        }
        for($i=0; $i -lt $ixb.Count; $i++){
            '$ixb[{0}] => "{1}"' | InjectMessage $mb -FormatByStream $i $ixb[$i] -Flush
        }

        '----- Indexes -----' | InjectMessage $mb -Flush
        $ixb.Indexes | InjectMessage $mb -Flush

        $aBag = $ixb['西']
        $ixb.Purge('西義之')
        $ixb.Purge('西餅')
        $ixb.PurgeIndex('荒')
        $od = $ixb.Substance
        $od

        # Comparer差し替えでインデックスが正しく再構成されるか?
    }
    11 {
        $mb = [MessageBuilder]::new()
        $testdata = @( '花沢健吾','花沢健吾','花沢健吾','若木民喜','荒井春太郎','荒井春太郎','莉ジャンヒュン','菅原キク','萩埜まこと','萩尾望都','藤間麗','西義之','ナイーブタ','西餅' )
        $aBag = [Bag]::new()
        $testdata.foreach{ $aBag.Add($_) }
        '----- ValuesSorted -----' | InjectMessage $mb -Flush
        $aBag.ValuesSorted.foreach{
            $_
        }
        '----- ValuesOrdered -----' | InjectMessage $mb -Flush
        $aBag.ValuesOrdered.foreach{
            $_
        }
        $aBag
    }
}