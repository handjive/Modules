using namespace System.Collections.Generic
using namespace handjive.Everything

using module handjive.Collections
using module handjive.EverythingAPI
using module handjive.Foundation


# IClonableの実装いるみたい…

class Everything : IEverything {
    static [object]$DEFULAT_RESULT_TYPE = [hashtable]

    [object]$esapi
    hidden [ValueHolder]$SearchStringHolder
    hidden [ValueHolder]$QueryBaseHolder
    hidden [bool]$isSearchStringDirty
    
    [type]$ResultType
    [EverythingResultAccessor]$pvResults

    Everything()
    {
        $this.Initialize()
        $this.Reset()
    }
    Everything([object]$elementClass){
        $this.Initialize()
        $this.Reset()
    }

    hidden Initialize(){
        $this.esapi = [handjive.Everything.EverythingAPI]
        $this.ResultType = $this.gettype()::DEFULAT_RESULT_TYPE
        
        $beDirty={ param($receiver,$args1,$args2,$workingset)
            $receiver.isSearchStringDirty = $true }

        $this.SearchStringHolder = [ValueHolder]::new()
        $this.SearchStringHolder.Dependents.Add([EV_ValueModel]::ValueChanged,$this,$beDirty)

        $this.QueryBaseHolder = [ValueHolder]::new()  
        $this.QueryBaseHolder.Dependents.Add([EV_ValueModel]::ValueChanged,$this,$beDirty)
    }

    <#
    # Property Accessors
    #>
    hidden [string]get_QueryBase(){
        return $this.QueryBaseHolder.Value
    }
    hidden set_QueryBase([string]$value){
        if( $value -eq '' ){
            $this.QueryBaseHolder.Value = $value
        }
        else{
            # QueryBaseがリンクだったら、実体パスに変換
            $dirinfo = EnsureSubstancePath -LiteralPath $value -ifLink {
                Param($substanceOrLink,$substanceFileInfo)
                [String]::Format('[Everything]:Target path changed to "{0}" cause it is a link',$substanceFileInfo.FullName) | write-warning
            }
            
            $this.QueryBaseHolder.Value = $dirinfo.FullName
        }
    }

    hidden [string]get_SearchString()
    {
        return($this.SearchStringHolder.Value)
    }
    hidden set_SearchString([string]$value){
        $this.SearchStringHolder.Value = $value
    }

    hidden [object]get_SortOrder()
    {
        return ([ESAPI_SORT]$this.esapi::Everything_GetSort())
    }
    
    hidden set_SortOrder([object]$aValue)
    {
        $this.esapi::Everything_SetSort($aValue)
    }

    hidden [object]get_RequestFlags()
    {
        return ([ESAPI_REQUEST]$this.esapi::Everything_GetRequestFlags())
    }
    hidden set_RequestFlags([object]$aValue)
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

    hidden [object]get_LastError()
    {
        return([ESAPI_ERROR]$this.esapi::Everything_GetLastError())
    }

    hidden [System.Collections.IEnumerable]get_Results(){
        if( $null -eq $this.pvResults ){
            $this.pvResults = [EverythingResultAccessor]::new($this)
        }
        return $this.pvResults
    }

    hidden [int]get_NumberOfResults(){
        return ($this.esapi::Everything_GetNumResults())
    }


    <#
    # Methods
    #>
    hidden BuildSearchString(){
        if( $this.isSearchStringDirty ){
            $actualQueryString = $this.QueryBaseHolder.value+' '+$this.SearchStringHolder.Value
            $this.esapi::Everything_SetSearchW($actualQueryString)
            $this.isSearchStringDirty = $false
        }
    }

    SelectResultType([type]$type)
    {
        $this.ResultType = $type
    }

    Reset()
    {
        $this.pvResults = $null
        $this.SearchStringHolder.Value = ""
        $this.QueryBaseHolder.Value = ""
        $this.isSearchStringDirty = $false
        $this.esapi::Everything_Reset()
    }

    PerformQuery()
    {
        $this.BuildSearchString()
        $this.esapi::Everything_QueryW($true)
        $this.pvResults =  $null
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
}
