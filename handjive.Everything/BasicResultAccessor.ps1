using namespace handjive.Everything
using namespace handjive.Foundation
using module handjive.Adaptors

class BasicResultAccessor : IBasicResultAccessor, IAdaptor {
    hidden [IEverything]$pvSubject
    hidden [object]$esapi

    BasicResultAccessor([IEverything]$subject){
        $this.Subject = $subject
        $this.esapi = [EverythingAPI]
    }

    hidden [object]get_Subject(){ return $this.pvSubject }
    hidden set_Subject([object]$subject){ $this.pvSubject = $subject }

    hidden [int]get_Count()
    {
        return ($this.esapi::Everything_GetNumResults())
    }
    hidden [object]get_LastError()
    {
        return([ESAPI_ERROR]$this.esapi::Everything_GetLastError())
    }

    [string]FileNameAt([int]$index)
    {
        return $this.esapi::GetResultFileName($index)
    }

    [string]ExtensionAt([int]$index)
    {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringUni(($this.esapi::Everything_GetResultExtension($index)))
    }

    [string]PathAt([int]$index)
    {
        return $this.esapi::GetResultPath($index)
    }

    [string]FullPathAt([int]$index)
    {
        return Join-Path -Path $this.PathAt($index) -ChildPath $this.FileNameAt($index)
    }

    [int]SizeAt([int]$index)
    {
        $aSize = [long]0
        $this.esapi::Everything_GetResultSize($index,[ref]$aSize)
        return $aSize
    }

    [DateTime]DateCreatedAt([int]$index)
    {
        $aFiletime = [long]0
        $this.esapi::Everything_GetResultDateCreated($index,[ref]$aFiletime)
        return ([DateTime]::FromFileTime($aFiletime))
    }

    [DateTime]DateModifiedAt([int]$index)
    {
        $aFiletime = [long]0
        $this.esapi::Everything_GetResultDateModified($index,[ref]$aFiletime)
        return ([DateTime]::FromFileTime($aFiletime))
    }

    [DateTime]DateAccessedAt([int]$index)
    {
        $aFiletime = [long]0
        $this.esapi::Everything_GetResultDateAccessed($index,[ref]$aFiletime)
        return ([DateTime]::FromFileTime($aFiletime))
    }

    hidden [DateTime]DateRunAt([int]$index) # 使えない
    {
        $aFiletime = [long]0
        $this.esapi::Everything_GetResultDateRun($index,[ref]$aFiletime)
        return ([DateTime]::FromFileTime($aFiletime))
    }

    hidden [DateTime]DateRecentlyChangedAt([int]$index) # 使えない
    {
        $aFiletime = [long]0
        $this.esapi::Everything_GetResultDateRecentlyChanged($index,[ref]$aFiletime)
        return ([DateTime]::FromFileTime($aFiletime))
    }

    [System.IO.FileAttributes]AttributesAt([int]$index)
    {
        return [System.IO.FileAttributes]($this.esapi::Everything_GetResultAttributes($index))
    }
}

class EverythingResultConverter : IAdaptor, IEverythingResultConverter{
    static [hashtable]$KnownConverters =@{
        [hashtable]=[EverythingResultConverter_HashTable]
        [string]=[EverythingResultConverter_String]
        [EverythingSearchResultElement]=[EverythingResultConverter_EverythingSearchResultElement]
    }
    static [EverythingResultConverter]ConverterFor([IEverything]$subject,[type]$type){
        $aConverterClass = [EverythingResultConverter]::KnownConverters[$type]
        $aConverter = $aConverterClass::new($subject)
        return $aConverter
    }
    static [void]RegistConverter([type]$type,[EverythingResultConverter]$converter){
        [EverythingResultConverter]::KnownConverters.Add($type,$converter)
    }

    hidden [object]$pvSubject
    hidden [BasicResultAccessor]$Accessor

    EverythingResultConverter([IEverything]$subject){
        $this.Subject = $subject
        $this.Accessor = [BasicResultAccessor]::new($subject)
    }

    hidden [object]get_Subject(){ return $this.pvSubject }
    hidden set_Subject([object]$subject){ $this.pvSubject = $subject }

    [int]get_Count(){ return $this.Accessor.Count }
    [object]Convert([int]$index){ return $null }
}

class EverythingResultConverter_HashTable : EverythingResultConverter {
    EverythingResultConverter_HashTable([IEverything]$subject) : base($subject){}

    [System.Collections.Specialized.OrderedDictionary]Convert([int]$index)
    {
        $result = [System.Collections.Specialized.OrderedDictionary]::new()
        
        # この2つは、リクエストフラグの有無にかかわらず返ってくる
        $result.Add([ESAPI_REQUEST]::FILE_NAME,$this.Accessor.FileNameAt($index))
        $result.Add([ESAPI_REQUEST]::PATH,$this.Accessor.PathAt($index))
        $result.Add('FULLPATH',$this.Accessor.FullPathAt($index))
        

        if( $this.Subject.RequestFlags.hasFlag([ESAPI_REQUEST]::EXTENSION) ){
            $result.Add([ESAPI_REQUEST]::EXTENSION,$this.Accessor.ExtensionAt($index))
        }
        if( $this.Subject.RequestFlags.hasFlag([ESAPI_REQUEST]::SIZE) ){
            $result.Add([ESAPI_REQUEST]::SIZE,$this.Accessor.SizeAt($index))
        }
        if( $this.Subject.RequestFlags.hasFlag([ESAPI_REQUEST]::DATE_CREATED) ){
            $result.Add([ESAPI_REQUEST]::DATE_CREATED,$this.Accessor.DateCreatedAt($index))
        }
        if( $this.Subject.RequestFlags.hasFlag([ESAPI_REQUEST]::DATE_MODIFIED) ){
            $result.Add([ESAPI_REQUEST]::DATE_MODIFIED,$this.Accessor.DateModifiedAt($index))
        }
        if( $this.Subject.RequestFlags.hasFlag([ESAPI_REQUEST]::DATE_ACCESSED) ){
            $result.Add([ESAPI_REQUEST]::DATE_ACCESSED,$this.Accessor.DateAccessedAt($index))
        }
        if( $this.Subject.RequestFlags.hasFlag([ESAPI_REQUEST]::ATTRIBUTES) ){
            $result.Add([ESAPI_REQUEST]::ATTRIBUTES,$this.Accessor.AttributesAt($index))
        }
        
        return $result
    }
}

class EverythingResultConverter_String : EverythingResultConverter {
    EverythingResultConverter_String([IEverything]$subject) : base($subject){}

    [string]Convert([int]$index)
    {
        return $this.Accessor.FullPathAt($index)
    }
}

class EverythingResultConverter_FileSystemInfo : EverythingResultConverter {
    EverythingResultConverter_FileSystemInfo([IEverything]$subject) : base($subject){}

    [IO.FileSystemInfo]Convert([int]$index)
    {
        $fsi = Get-Item -LiteralPath ($this.Accessor.FullPathAt($index)) -Force
        return $fsi
    }
}

class EverythingResultConverter_EverythingSearchResultElement : EverythingResultConverter {
    EverythingResultConverter_EverythingSearchResultElement([IEverything]$subject) : base($subject){}
    
    [EverythingSearchResultElement]Convert([int]$index)
    {
        $elem = [EverythingSearchResultElement]::new()
        $elem.Number = $this.subject.NumberingOffset + $index
        $elem.Name = $this.Accessor.FileNameAt($index)
        $elem.ContainerPath = $this.Accessor.PathAt($index)
        $elem.QueryBase = $this.Subject.QueryBase
        $elem.OnInjectionComplete($elem) | out-null

        return $elem
    }
}