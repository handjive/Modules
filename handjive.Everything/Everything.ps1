using namespace handjive.Everything

using module handjive.Collections
using module handjive.EverythingAPI
using module handjive.Adaptors


# IClonableの実装いるみたい…

class Everything : IEverything {
    static [object]$DefaultElementClass = [EverythingSearchResultElement]

    static [void]Search([string]$queryString){
        [Everything]::Search('.',$queryString)
    }
    static [void]Search([string]$queryBase,[string]$queryString){
        $es = [Everything]::new()
        $es.QueryBase = $queryBase
        $es.PerformQuery($queryString)
        Write-Host ([String]::Format('Status: {0}',$es.LastError))
        Write-Host ([String]::Format('Number of results: {0}',$es.NumberOfResults))
        Write-Host ''

        $es.Results.foreach{
            write-host $_.FullName
        }
        <#for( $i=0; $i -lt $es.NumberOfResults; $i++ ){
            write-host ($es.Results[$i]).FullName
        }#>
    }

    static [object]$DEFULAT_RESULT_TYPE = [hashtable]

    [object]$ElementClass
    [object]$esapi
    hidden [object]$wpvResults = @()
    hidden [ValueHolder]$SearchStringHolder
    hidden [ValueHolder]$QueryBaseHolder
    hidden [bool]$isSearchStringDirty
    hidden [DependencyHolder]$PostBuildElementListeners
    [int]$NumberingOffset = 1
    [type]$ResultType

    Everything()
    {
        $this.Initialize([Everything]::DefaultElementClass)
        $this.Reset()
    }
    Everything([object]$elementClass){
        $this.Initialize($elementClass)
        $this.Reset()
    }

    hidden Initialize([object]$elementClass){
        $this.esapi = [handjive.Everything.EverythingAPI]
        $this.ResultType = $this.gettype()::DEFULAT_RESULT_TYPE
        
        $this.PostBuildElementListeners = [DependencyHolder]::new()

        $beDirty={ param($receiver,$args1,$args2,$workingset)
            $receiver.isSearchStringDirty = $true }

        $this.SearchStringHolder = [ValueHolder]::new()
        $this.SearchStringHolder.AddValueChangedListener($this,$beDirty)

        $this.QueryBaseHolder = [ValueHolder]::new()  
        $this.QueryBaseHolder.AddValueChangedListener($this,$beDirty)

        $this.ElementClass = $elementClass
    }

    SelectResultType([type]$type)
    {
        $this.ResultType = $type
    }

    Reset()
    {
        $this.ResetResults()
        $this.SearchStringHolder.Subject = ""
        $this.QueryBaseHolder.Subject = ""
        $this.isSearchStringDirty = $false
        $this.esapi::Everything_Reset()
    }
    hidden ResetResults(){
        $this.wpvResults = @()
    }

    [object]NewElement()
    {
        return($this.ElementClass::new())
    }
  
    [string]get_QueryBase(){
        return $this.QueryBaseHolder.Value
    }
    set_QueryBase([string]$value){
        if( $value -eq '' ){
            $this.QueryBaseHolder.Value = $value
        }
        else{
            $dirinfo = EnsureSubstancePath -LiteralPath $value -ifLink {
                Param($substanceOrLink,$substanceFileInfo)
                [String]::Format('[Everything]:Target path changed to "{0}" cause it is a link',$substanceFileInfo.FullName) | write-warning
            }
            
            $this.QueryBaseHolder.Value = $dirinfo.FullName
        }
    }

    [string]get_SearchString()
    {
        return($this.SearchStringHolder.Value)
    }
    set_SearchString([string]$value){
        $this.SearchStringHolder.Value = $value
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

    [void]UnsetRequestFlag([ESAPI_REQUEST]$aFlag)
    {
        $current = $this.RequestFlags
        if( ($current -band $aFlag) -eq $aFlag)
        {
            $current -= $aFlag
            $this.RequestFlags =$current
        }
    }
    [void]SetRequestFlag([ESAPI_REQUEST]$aFlag)
    {
        $current = $this.RequestFlags
        if( ($current -band $aFlag) -ne $aFlag )
        {
            $current += $aFlag
            $this.RequestFlags = $current
        }
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

    hidden BuildSearchString(){
        if( $this.isSearchStringDirty ){
            $actualQueryString = $this.QueryBaseHolder.value+' '+$this.SearchStringHolder.Value
            $this.esapi::Everything_SetSearchW($actualQueryString)
            $this.isSearchStringDirty = $false
        }
    }

    [object]get_Results(){
        if( $null -eq $this.wpvResults ){
            $ixa = [IndexAdaptor]::new($this)
            $ixa.GetSubjectBlock.Enumerable = {
                param($adaptor,$substance,$workingset)
                $adaptor.Subjects.Enumerable = $substance.ResultsEnumerator().ToEnumerable()
            }
            $ixa.GetItemBlock.IntIndex = {
                param($adaptor,$subject,$workingset,$index)
                $elem = $subject.createElement($subject,$index)
                return $elem
            }
            $ixa.GetCountBlock = {
                param($adaptor,$workingset)
                $adaptor.substance.NumberOfResults
            }
   
            $this.wpvResults = $ixa
        }
        return($this.wpvResults)
    }
    set_Results([object[]]$var){
        $this.wpvResults = $var
    }
    [int]get_NumberOfResults(){
        return ($this.esapi::Everything_GetNumResults())
    }

    [String]ResultFullpathAt([int]$index){
        return Join-Path -Path $this.ResultPathAt($index) -ChildPath $this.ResultFileNameAt($index) 
    }

    [void]ResultIndexDo([ScriptBlock]$performer){
        for($i=0; $i -lt $this.NumberOfResults; $i++ ){
            Write-Output (&$performer $i)
        }
    }

    hidden [EverythingSearchResultElement]createElement([Everything]$substance,[int]$index){
        $elem = $substance.NewElement()
        $elem.Number = ($substance.NumberingOffset+$index)
        $elem.Name = $substance.ResultFileNameAt($index)
        $elem.ContainerPath = $substance.ResultPathAt($index)
        $elem.QueryBase = $substance.QueryBase
        $elem.OnInjectionComplete($elem) | out-null
        $substance.PostBuildElementListeners.Perform($elem,@{}) | out-null
        return $elem
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
            $elem = $substance.createElement($substance,$workingset.Locator)
            $workingset.Locator++
            return $elem
        }
        $enumr.OnResetBlock = {
            param($substance,$workingset)
            $workingset.Locator = 0
            $workingset.NumResults = $substance.esapi::Everything_GetNumResults()
        }
        
        $enumr.PSReset()
        return($enumr)
    }
    [Collections.Generic.IEnumerable[object]]get_ResultsEnumerable(){
        return $this.ResultsEnumerator().ToEnumerable()
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
        $this.SearchStringHolder.Value = $pattern
        $this.PerformQuery()
    }

    PerformQuery([string]$queryBase,[string]$pattern)
    {
        $this.QueryBaseHolder.Value = $queryBase
        $this.SearchStringHolder.Value = $pattern
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
