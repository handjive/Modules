using namespace handjive.Everything

using module handjive.EverythingAPI
using module handjive.ValueHolder

enum ESAPI_ERROR{
    OK	= 0
    ERROR_MEMORY = 1
    ERROR_IPC = 2
    REGISTERCLASSEX = 3
    ERROR_CREATEWINDOW = 4
    ERROR_CREATETHREAD = 5
    ERROR_INVALIDINDEX = 6
    ERROR_INVALIDCALL = 7
    ERROR_UNKNOWN = 8
}

[flags()] enum ESAPI_REQUEST{
    FILE_NAME = 0x00000001;
    PATH = 0x00000002;
    FULL_PATH_AND_FILE_NAME = 0x00000004;
    EXTENSION = 0x00000008;
    SIZE = 0x00000010;
    DATE_CREATED = 0x00000020;
    DATE_MODIFIED = 0x00000040;
    DATE_ACCESSED = 0x00000080;
    DATE_RUN = 0x00000800;
    DATE_RECENTLY_CHANGED = 0x00001000;
    ATTRIBUTES = 0x00000100;
    FILE_LIST_FILE_NAME = 0x00000200;
    RUN_COUNT = 0x00000400;
}

enum ESAPI_SORT{
    NAME_ASCENDING = 1;
    NAME_DESCENDING = 2;
    PATH_ASCENDING = 3;
    PATH_DESCENDING = 4;
    SIZE_ASCENDING = 5;
    SIZE_DESCENDING = 6;
    EXTENSION_ASCENDING = 7;
    EXTENSION_DESCENDING = 8;
    TYPE_NAME_ASCENDING = 9;
    TYPE_NAME_DESCENDING = 10;
    ATTRIBUTES_ASCENDING = 15;
    ATTRIBUTES_DESCENDING = 16;
    FILE_LIST_FILENAME_ASCENDING = 17;
    FILE_LIST_FILENAME_DESCENDING = 18;
    RUN_COUNT_ASCENDING = 19;
    RUN_COUNT_DESCENDING = 20;
    DATE_CREATED_ASCENDING = 11;
    DATE_CREATED_DESCENDING = 12;
    DATE_MODIFIED_ASCENDING = 13;
    DATE_MODIFIED_DESCENDING = 14;
    DATE_RECENTLY_CHANGED_ASCENDING = 21;
    DATE_RECENTLY_CHANGED_DESCENDING = 22;
    DATE_ACCESSED_ASCENDING = 23;
    DATE_ACCESSED_DESCENDING = 24;
    DATE_RUN_ASCENDING = 25;
    DATE_RUN_DESCENDING = 26;
}


class EverythingSearchResultElement : ISearchResultElement,IComparable {
    static [object]$DefaultComparer = [AspectComparer]::new('Name')
    hidden [string]$wpvQueryBase
    hidden [int]$wpvNumber
    hidden [string]$wpvName
    hidden [string]$wpvContainerPath
    [object]$Comparer

    EverythingSearchResultElement([int]$anIndex,[string]$aName,[string]$aContainer)
    {
        $this.Number = $anIndex
        $this.Name = $aName
        $this.ContainerPath = $aContainer
        $this.Comparer = [EverythingSearchResultElement]::DefaultComparer
    }
    EverythingSearchResultElement()
    {
        $this.Comparer = [EverythingSearchResultElement]::DefaultComparer
    }

    <# Reponsibility for IComparable #>
    [int] CompareTo([object]$left){
        return ($this.Comparer.PSCompare($this,$left))
    }

    [string]get_QueryBase(){
        return ($this.wpvQueryBase)
    }
    set_QueryBase([string]$value){
        $this.wpvQueryBase = $value
    }

    [int]get_Number(){
        return ($this.wpvNumber)
    }
    set_Number([int]$value){
        $this.wpvNumber = $value
    }

    [string]get_Name(){
        return ($this.wpvName)
    }
    set_Name([string]$value){
        $this.wpvName = $value
    }

    [string]get_ContainerPath(){
        return($this.wpvContainerPath)
    }
    set_ContainerPath([string]$value){
        $this.wpvContainerPath = $value
    }

    [string]AsFullPath()
    {
        return (Join-Path -Path $this.ContainerPath -ChildPath $this.Name)
    }
    [object]AsFilesystemInfo()
    {
        return Get-Item -literalPath $this.AsFullPath()
    }

    [string]get_FullName(){
        return $this.AsFullPath()
    }
    
    OnInjectionComplete([object]$elem)
    {
    }
}

class Everything : IEverything {
    static [object]$DefaultElementClass = [EverythingSearchResultElement]

    static [object[]]Search([string]$queryString){
        return ([Everything]::Search('',$queryString))
    }
    static [object[]]Search([string]$queryBase,[string]$queryString){
        $es = [Everything]::new()
        $es.QueryBase = $queryBase
        $es.PerformQuery($queryString)
        Write-Host ([String]::Format('Status: {0}',$es.LastError))
        Write-Host ([String]::Format('Number of results: {0}',$es.NumberOfResults))
        return $es.Results
    }

    [object]$ElementClass
    [object]$esapi
    hidden [object[]]$wpvResults = @()
    hidden [ValueHolder]$SearchStringHolder
    hidden [ValueHolder]$QueryBaseHolder
    hidden [bool]$isSearchStringDirty
    hidden [DependencyHolder]$PostBuildElementListeners
    [int]$NumberingOffset = 1

    Everything()
    {
        $this.Initialize([Everything]::DefaultElementClass)
        $this.Reset()
    }
    Everything([object]$elementClass){
        $this.Initialize($elementClass)
        $this.Reset()
    }

    Initialize([object]$elementClass){
        $this.esapi = [handjive.Everything.EverythingAPI]
        
        $this.PostBuildElementListeners = [DependencyHolder]::new()

        $beDirty={ param($receiver,$args1,$args2,$workingset)
            $receiver.isSearchStringDirty = $true }

        $this.SearchStringHolder = [ValueHolder]::new()
        $this.SearchStringHolder.AddValueChangedListener($this,$beDirty)

        $this.QueryBaseHolder = [ValueHolder]::new()  
        $this.QueryBaseHolder.AddValueChangedListener($this,$beDirty)

        $this.ElementClass = $elementClass
    }

    Reset()
    {
        $this.ResetResults()
        $this.SearchStringHolder.Subject = ""
        $this.QueryBaseHolder.Subject = ""
        $this.isSearchStringDirty = $false
        $this.esapi::Everything_Reset()
    }
    ResetResults(){
        $this.wpvResults = @()
    }

    [object]NewElement()
    {
        return($this.ElementClass::new())
    }
  
    [string]get_QueryBase(){
        return $this.QueryBaseHolder.Value()
    }
    set_QueryBase([string]$value){
        $dirinfo = EnsureSubstancePath -LiteralPath $value -ifLink {
            Param($substanceOrLink,$substanceFileInfo)
            [String]::Format('[Everything]:Target path changed to "{0}" cause it is a link',$substanceFileInfo.FullName) | write-warning
        }
        
        $this.QueryBaseHolder.Value($dirinfo.FullName)
    }

    [string]get_SearchString()
    {
        return($this.SearchStringHolder.Value())
    }
    set_SearchString([string]$value){
        $this.SearchStringHolder.Value($value)
    }

    [object]get_SortOrder()
    {
        return ([ESAPI_SORT]$this.esapi::Everything_GetSort())
    }
    
    set_SortOrder([object]$aValue)
    {
        $this.esapi::Everything_SetSort($aValue)
    }

    [object]get_RequestFlags()
    {
        return ([ESAPI_REQUEST]$this.esapi::Everything_GetRequestFlags())
    }
    set_RequestFlags([object]$aValue)
    {
        $this.esapi::Everything_SetRequestFlags($aValue)
    }

    [ESAPI_REQUEST]UnsetRequestFlag([ESAPI_REQUEST]$aFlag)
    {
        $current = $this.RequestFlags
        if( ($current -band $aFlag) -eq $aFlag)
        {
            $current -= $aFlag
            $this.RequestFlags =$current
        }
        return $current
    }
    [ESAPI_REQUEST]SetRequestFlag([ESAPI_REQUEST]$aFlag)
    {
        $current = $this.RequestFlags
        if( ($current -band $aFlag) -ne $aFlag )
        {
            $current += $aFlag
            $this.RequestFlags = $current
        }
        return $current
    }

    [object]get_LastError()
    {
        return([ESAPI_ERROR]$this.esapi::Everything_GetLastError())
    }

    [string]ResultPathAt([int]$index)
    {
        return $this.esapi::GetResultPath($index)
    }

    [string]ResultFileNameAt([int]$index)
    {
        return $this.esapi::GetResultFileName($index)
    }

    BuildSearchString(){
        if( $this.isSearchStringDirty ){
            $actualQueryString = $this.QueryBaseHolder.value()+' '+$this.SearchStringHolder.Value()
            $this.esapi::Everything_SetSearchW($actualQueryString)
            $this.isSearchStringDirty = $false
        }
    }

    [object[]]get_Results(){
        if( $null -eq $this.wpvResults ){
            $this.BuildResultSet()
        }
        return($this.wpvResults)
    }
    set_Results([object[]]$var){
        $this.wpvResults = $var
    }
    [int]get_NumberOfResults(){
        return ($this.esapi::Everything_GetNumResults())
    }

    hidden [Collections.Generic.IEnumerator[object]]ResultsEnumerator(){
        $enumr = [PluggableEnumerator]::new($this)
        $enumr.WorkingSet.NumberOfResults = $this.NumberOfResults
        $enumr.OnMoveNextBlock = {
            param($substance,$workingset)
            return($workingset.Locator -lt $workingset.NumberOfResults)
        }
        $enumr.OnCurrentBlock = {
            param($substance,$workingset)
            $elem = $substance.NewElement()
            $elem.Number = ($substance.NumberingOffset+$workingset.Locator)
            $elem.Name = $substance.ResultFileNameAt($workingset.Locator)
            $elem.ContainerPath = $substance.ResultPathAt($workingset.Locator)
            $elem.QueryBase = $substance.QueryBase
            $elem.OnInjectionComplete($elem) | out-null
            $substance.PostBuildElementListeners.Perform($elem,@{}) | out-null
            $workingset.Locator++
            return $elem
        }
        $enumr.OnResetBlock = {
            param($substance,$workingset)
            $enumr.Workingset.Locator = 0
            $enumr.Workingset.NumResults = $substance.esapi::Everything_GetNumResults()
        }
        
        $enumr.PSReset()
        return($enumr)
    }
    [Collections.Generic.IEnumerable[object]]get_ResultsEnumerable(){
        return $this.ResultsEnumerator().ToEnumerable()
    }

    BuildResultSet(){
        $this.wpvResults = @()
        $this.ResultsEnumerable.foreach{
            $this.wpvResults += $_
        }
        <#
        for($i =0;$i -lt $this.esapi::Everything_GetNumResults();$i++)
        {
            $anElement = $this.NewElement()
            $anElement.Number = ($this.NumberingOffset+$i)
            $anElement.Name =$this.ResultFileNameAt($i)
            $anElement.ContainerPath = $this.ResultPathAt($i)
            $anElement.QueryBase = $this.QueryBase
    
            $anElement.OnInjectionComplete($anElement)
            $this.PostBuildElementListeners.Perform($anElement,@{})
            $this.wpvResults += $anElement
        }
        #>
    }


    PerformQuery()
    {
        $this.wpvResults = $null
        $this.BuildSearchString()
        $this.esapi::Everything_QueryW($true)
        #$this.BuildResultSet($filter)
    }

    PerformQuery([string]$pattern)
    {
        $this.SearchStringHolder.Value($pattern)
        $this.PerformQuery()
    }

    PerformQuery([string]$queryBase,[string]$pattern)
    {
        $this.QueryBaseHolder.Value($queryBase)
        $this.SearchStringHolder.Value($pattern)
        $this.PerformQuery()
    }

    [object[]]SelectResult([scriptblock]$aScriptBlock)
    {
        [object[]]$selection = @()

        $this.Results.foreach{
            if( Invoke-Command -ScriptBlock $aScriptBlock -ArgumentList $_ ){
                $selection += $_
            }
        }

        return ($selection)
    }
}
