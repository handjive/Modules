enum EncoderName{
    shift_jis = 932
    IBM860 = 860
    ibm861 = 861
    IBM880 = 20880
    DOS_862 = 862
    IBM863 = 863
    gb2312 = 936
    IBM864 = 864
    IBM865 = 865
    cp866 = 866
    koi8_u = 21866
    IBM037 = 37
    ibm869 = 869
    IBM500 = 500
    x_mac_icelandic = 10079
    IBM01140 = 1140
    IBM01141 = 1141
    IBM01142 = 1142
    IBM273 = 20273
    IBM01143 = 1143
    IBM01144 = 1144
    IBM01145 = 1145
    windows_1250 = 1250
    IBM01146 = 1146
    windows_1251 = 1251
    IBM01147 = 1147
    macintosh = 10000
    windows_1252 = 1252
    DOS_720 = 720
    IBM277 = 20277
    IBM01148 = 1148
    x_mac_japanese = 10001
    windows_1253 = 1253
    IBM437 = 437
    IBM278 = 20278
    IBM01149 = 1149
    x_mac_chinesetrad = 10002
    windows_1254 = 1254
    windows_1255 = 1255
    Johab = 1361
    windows_1256 = 1256
    x_mac_arabic = 10004
    windows_1257 = 1257
    x_mac_hebrew = 10005
    windows_1258 = 1258
    x_mac_greek = 10006
    x_mac_cyrillic = 10007
    IBM00924 = 20924
    iso_8859_2 = 28592
    iso_8859_3 = 28593
    iso_8859_4 = 28594
    iso_8859_5 = 28595
    iso_8859_6 = 28596
    IBM870 = 870
    iso_8859_7 = 28597
    iso_8859_8 = 28598
    iso_8859_9 = 28599
    x_mac_turkish = 10081
    x_mac_croatian = 10082
    windows_874 = 874
    cp875 = 875
    IBM420 = 20420
    ks_c_5601_1987 = 949
    IBM423 = 20423
    IBM424 = 20424
    IBM280 = 20280
    IBM01047 = 1047
    IBM284 = 20284
    IBM285 = 20285
    x_mac_romanian = 10010
    EUC_JP = 20932
    x_mac_ukrainian = 10017
    x_Europa = 29001
    ibm737 = 737
    x_IA5 = 20105
    big5 = 950
    x_cp20936 = 20936
    x_IA5_German = 20106
    x_IA5_Swedish = 20107
    x_IA5_Norwegian = 20108
    koi8_r = 20866
    ibm775 = 775
    iso_8859_13 = 28603
    IBM290 = 20290
    iso_8859_15 = 28605
    x_Chinese_CNS = 20000
    ASMO_708 = 708
    IBM297 = 20297
    x_mac_thai = 10021
    x_cp20001 = 20001
    IBM905 = 20905
    x_Chinese_Eten = 20002
    x_ebcdic_koreanextended = 20833
    x_cp20003 = 20003
    x_cp20004 = 20004
    x_cp20005 = 20005
    ibm850 = 850
    IBM_Thai = 20838
    ibm852 = 852
    IBM871 = 20871
    x_mac_ce = 10029
    IBM855 = 855
    cp1025 = 21025
    x_cp20949 = 20949
    ibm857 = 857
    IBM00858 = 858
    x_cp20261 = 20261
    IBM1026 = 1026
    x_cp20269 = 20269
    utf_16 = 1200
    utf_16BE = 1201
    utf_32 = 12000
    utf_32BE = 12001
    us_ascii = 20127
    iso_8859_1 = 28591
    utf_8 = 65001     
}

function GenerateEncoderName
{
    'enum EncoderName{' | write-host
    [System.Text.Encoding]::GetEncodings().foreach{
        $name = $_.Name.replace('-','_')
        [String]::Format('    {0} = {1}',$name,$_.CodePage) | write-host
    }
    '}' | Write-Host
}

#GenerateEncoderName

<#function SizeInByte{
    param(
          [parameter(Position=0)][string]$String
         ,[parameter()][EncoderName]$EncoderName = [EncoderName]::shift_jis
    )
    if( "" -eq $String ){
         return 0
    }
    $encoder = [Text.Encoding]::GetEncoding([int]$encoderName)
    return ($encoder.GetByteCount($String))
}
#>

class StringUtility{
    static [int]SizeInByte([string]$aString){
        return([StringUtility]::SizeInByte($aString,[EncoderName]::shift_jis))
    }
    static [int]SizeInByte([String]$aString,[EncoderName]$EncoderName){
        if( $null -eq $aString){ return 0 }
        if( "" -eq $aString ){ return 0 }

        $encoder = [Text.Encoding]::GetEncoding([int]$EncoderName)
        return($encoder.GetByteCount($aString))
    }

    static [string]ReverseString([string]$str){
        $chars = $str[($str.Length-1)..0]
        return (($chars -join('')))
    }
    static [string]Left([string]$str,[int]$width){
        return([StringUtility]::Left($str,$width,' '))
    }

    static [string]Left([String]$str,[int]$width,[string]$filler){
        $str,$padding = [StringUtility]::ClipAndCulculatePadding($str,$width,$filler)
        return($str+$padding)
    }

    static [string]Right([string]$str,[int]$width){
        return([StringUtility]::Right($str,$width,' '))
    }

    static [string]Right([String]$str,[int]$width,[string]$filler){
        $str,$padding = [StringUtility]::ClipAndCulculatePadding([StringUtility]::ReverseString($str),$width,$filler)
        return($padding+[StringUtility]::ReverseString($str))
    }

    hidden static [string]ClipLeftInWidth([string]$str,[int]$width){
        return([StringUtility]::ReverseString(([StringUtility]::ClipRightInWidth([StringUtility]::ReverseString($str),$width))))
    }

    hidden static [string]ClipRightInWidth([string]$str,[int]$width){
        $buffer = ''
        for($i = 0; $i -lt $str.Length; $i++){
            $bufferWidth = [StringUtility]::SizeInByte($buffer)
            $charWidth = [StringUtility]::SizeInByte($str[$i])
            if( ($bufferWidth+$charWidth) -le $width ){
                $buffer += $str[$i]
            }
            else{ 
                break
            }
        }

        if( ([StringUtility]::SizeInByte($buffer)) -gt $width ){
            throw "What a HELL!?"
        }
        return ($buffer)
    }




    hidden static [string[]]ClipAndCulculatePadding([string]$str,[int]$width,[string]$filler){
        $widthInBytes = [StringUtility]::SizeInByte($str)

        $result = $str
        
        # 幅ぴったしなら処理不要
        if( $widthInBytes -eq $width){
            return($result)
        }

        # 指定幅より長ければクリップ
        # (クリップ結果は指定幅より短い可能性がある)
        if( $widthInBytes -gt $width){
            $result = [StringUtility]::ClipRightInWidth($str,$width)
        }

        # クリップした結果ﾄﾞﾝﾋﾟｼｬならそのまま返す
        if( ($resultWidth = [StringUtility]::SizeInByte($result)) -eq $width ){ return($result) }

        # フィラー処理
        $widthDiff = $width - $resultWidth
        $fillerCandidate = ($filler * $widthDiff)   # Fillerが一文字ならこれでいいんだけど…
        $actualFiller = $fillerCandidate
        if( ([StringUtility]::SizeInByte($fillerCandidate)) -gt $widthDiff ){
            $actualFiller = [StringUtility]::ClipRightInWidth($fillerCandidate,$widthDiff)
        }

        return(@($result,$actualFiller))
    }

}