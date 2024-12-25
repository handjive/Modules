import-module handjive.Everything -Force
$ErrorActionPreference ='Stop'
$DebugPreference = 'SilentlyContinue'

switch($args){
    0 {
        $es = [Everything]::new()
        $es.QueryBase = '.\'
        $es.SearchString = '*.psd1'
        $es.SetRequestFlag([ESAPI_REQUEST]::EXTENSION);
        $es.SetRequestFlag([ESAPI_REQUEST]::SIZE)
        $es.SetRequestFlag([ESAPI_REQUEST]::DATE_CREATED)
        $es.SetRequestFlag([ESAPI_REQUEST]::DATE_MODIFIED)
        $es.SetRequestFlag([ESAPI_REQUEST]::DATE_ACCESSED)
        $es.SetRequestFlag([ESAPI_REQUEST]::ATTRIBUTES)
        $es.PerformQuery()
    }

    1 {
        $esra = [EverythingResultAccessor]::new($es)
        Write-Host 'Result = ' $esra.Count
        Write-Host 'Error? = ' $esra.LastError

        for($index=0; $index -lt $es.NumberOfResults; $index++){
            Write-Host '---------------'
            $esra.FileNameAt($index)
            $esra.PathAt($index)
            $esra.ExtensionAt($index)
            $esra.FullPathAt($index)
            $esra.SizeAt($index)
            $esra.DateCreatedAt($index)
            $esra.DateModifiedAt($index)
            $esra.DateAccessedAt($index)
            # $esra.DateRunAt($index)
            #$esra.DateRecentlyChangedAt($index)
            $esra.AttributesAt($index)
            $esra.ExtensionAt($index)
        }
    }

    2 {
        $converter = [EverythingResultConverter_HashTable]::new($es)
        $converter.Convert(0) | Write-Output

        $converter = [EverythingResultConverter_String]::new($es)
        $converter.Convert(0) | write-output

        $converter = [EverythingResultConverter_FileSystemInfo]::new($es)
        $fsi = $converter.Convert(0)
        write-output $fsi

        $converter = [EverythingResultConverter_EverythingSearchResultElement]::new($es)
        write-output ($converter.Convert(0))
    }

    2.1 {
        $converter = [EverythingResultConverter_HashTable]::new($es)
        for($index=0; $index -lt $es.NumberOfResults; $index++){
            $converter.Convert($index) | Write-Output
        }            
    }

    3 {
        $cv = [EverythingResultConverter]::ConverterFor($es,[String])
        Write-Output $cv.Convert(0)
        $cv = [EverythingResultConverter]::ConverterFor($es,[hashtable])
        Write-Output $cv.Convert(0)
        $cv = [EverythingResultConverter]::ConverterFor($es,[EverythingSearchResultElement])
        Write-Output $cv.Convert(0)
    }

    4 { # ConversionFinishedイベントの受信
        $es.SelectResultType([string])
        $accessor = [EverythingResultAccessor]::new($es)
        Write-Host $accessor[0]

        $accessor.SelectConverter([hashtable])
        Write-Output $accessor[0]
        
        $accessor.SelectConverter([EverythingSearchResultElement])
        $accessor.Dependents.Add([EV_EverythingResultAccessor]::ConversionFinished,{ param($elem,$converter)
            Write-Output $elem
            Write-Output $converter.gettype()
            Beep
        })
        
        Write-Output $accessor[0]
    }
    
    4.1 { # Enumerationのテスト
        $accessor = [EverythingResultAccessor]::new($es)
        Write-Output $accessor[0]
        $accessor.foreach{
            Write-Output $_
        }
        write-host '-----------------------------'
        $accessor.SelectConverter([string])
        $accessor.foreach{
            Write-output $_
        }

        write-host '-----------------------------'
        $accessor.SelectConverter([EverythingSearchResultElement])
        $accessor.foreach{
            Write-Output $_
        }
        write-host '-----------------------------'
        $accessor.SelectConverter([hashtable])
        $accessor.foreach{
            Write-Output $_
        }
    }

    5 {
        $es = [Everything]::new()
        $es.QueryBase = '.\'
        $es.SearchString = '*.psd1'
        $es.PerformQuery()
        $es.Results.foreach{
            Write-Output $_
        }
    }
}