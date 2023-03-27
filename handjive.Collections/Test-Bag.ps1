using module handjive.Collections

switch($args){
    1{
        $mb = [MessageBuilder]::new()

        $aBag = [Bag]::new()
        @(1,3,5,7,9).foreach{ $aBag.Add($_) }
        $aBag.AddAll(@(3,7))
        $aBag.Keys.foreach{
            'Occuerrences of "{0}" is "{1}"' | InjectMessage $mb -FormatByStream $_ $aBag.OccurrencesOf($_) -Flush
        }
        @(1..10).foreach{
            'Is includes {0}? => {1}' | InjectMessage $mb -FormatByStream $_ $aBag.Includes($_) -Flush
        }
        '----- keys -----' | InjectMessage $mb
        $aBag.Keys | InjectMessage $mb -NewLine
        $mb.Flush()
        '----- Values -----' | InjectMessage $mb
        $aBag.Values | InjectMessage $mb -NewLine
        $mb.Flush()

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
        $od = $ab.Substance
        $keyEnum = $od.Keys.GetEnumerator()
        $keyEnum.foreach{ Write-Host $_ }
        $ab.Values.foreach{ write-host $_ }
        $ab.ValuesAndOccurrences.foreach{ Write-Host $_.Value $_.Occurrences }
        $ab[18] | write-host
        $ab['Value18'] | Write-Host
        $ab.Value18 | Write-host
    }
}