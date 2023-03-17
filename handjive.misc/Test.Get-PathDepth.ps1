. '.\handjive.misc\Get-PathDepth.ps1'
switch($args){
    1 {
        Get-PathDepth -Path 'c:\abc\def\aaa.txt' | Write-Host
        Get-PathDepth -Path 'c:\abc\def\aaa.txt' -Base 'c:\abc' | Write-Host
        Get-PathDepth -Path 'c:\abc\def\' -Base 'c:\abc' | Write-Host      
    }
    2 {
        $base1 = 'c:\Users\handjive\Documents\書架\BooksArchive\'
        $base2 = 'c:\Users\handjive\Documents\書架\BooksArchive\2019-01'
        $path1 = 'c:\Users\handjive\Documents\書架\BooksArchive\2019-01\[ブロッコリーライオン×秋風緋色] 聖者無双'
        $path2 = 'c:\Users\handjive\Documents\書架\BooksArchive\2019-01\[ブロッコリーライオン×秋風緋色] 聖者無双\[ブロッコリーライオン×秋風緋色] 聖者無双 第11巻'
        Get-PathDepth -path $path1 -base $base1
        Get-PathDepth -path $path2 -base $base1
        Get-PathDepth -path $path1 -base $base2
        Get-PathDepth -path $path2 -base $base2
   }
}

