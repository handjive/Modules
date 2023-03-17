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


class EverythingSearchResultElement
{
    [int]$Number
    [string]$Name
    [string]$ContainerPath

    EverythingSearchResultElement([int]$anIndex,[string]$aName,[string]$aContainer)
    {
        $this.Number = $anIndex
        $this.Name = $aName
        $this.ContainerPath = $aContainer
    }

    [string]AsFullPath()
    {
        return Join-Path -Path $this.ContainerPath -ChildPath $this.Name
    }
    [object]AsFilesystemInfo()
    {
        return Get-Item -literalPath $this.AsFullPath()
    }
<#
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> 'C:\Users\handjive\Scripts.PowerShell\Modules\ConfigurationUtilities\'.split('\')  
C:  
Users
handjive
Scripts.PowerShell
Modules
ConfigurationUtilities

PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> 'C:\Users\handjive\Scripts.PowerShell\Modules\ConfigurationUtilities\'.replace('C:\Users\handjive\Scripts.PowerShell','')
\Modules\ConfigurationUtilities\
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $path = 'C:\Users\handjive\Scripts.PowerShell\Modules\ConfigurationUtilities\Test-ConfigurationUtilities.ps1'
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $containerPath = Split-path -Path $path
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $containerPath
C:\Users\handjive\Scripts.PowerShell\Modules\ConfigurationUtilities
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner>
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $containerPath.split('\').count
6
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $base = 'C:\Users\handjive\Scripts.PowerShell\'
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $base = 'C:\Users\handjive\Scripts.PowerShell' 
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $based = $containerPath -replace($base,'')
InvalidOperation: The regular expression pattern C:\Users\handjive\Scripts.PowerShell is not valid.
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $based = $containerPath.replace($base,'')     
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $based
\Modules\ConfigurationUtilities
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $based.split('\')

Modules
ConfigurationUtilities
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $based.split('\').count
3
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner> $based
\Modules\ConfigurationUtilities
PS C:\Users\handjive\Workspaces.PowerShell\BookArchiveCleaner>#>

    <#
        

    [int]Depth()
    {
        $this.ContainerPath.split('\').Count
    }
        #>
}

class Everything{
    [object]$esapi
    [object[]]$results = @()
    [ValueHolder]$SearchStringHolder
    [ValueHolder]$QueryBaseHolder
    [bool]$isSearchStringDirty

    Everything()
    {
        $this.esapi = [EverythingAPI]::DefaultAPI()

        $this.SearchStringHolder = [ValueHolder]::new("")
        $this.SearchStringHolder.onSubjectChanged = {
            $this.isSearchStringDirty = $true
        }
        $this.QueryBaseHolder = [ValueHolder]::new("")  
        $this.QueryBaseHolder.onSubjectChanged = {
            $this.isSearchStringDirty = $true
        }

        $this.Reset()
    }

    Reset()
    {
        $this.results = @()
        $this.SearchStringHolder.Subject("")
        $this.QueryBaseHolder.Subject("")
        $this.isSearchStringDirty = $false
        #$this.esapi::Everything_Reset()
    }

  
    [bool]Regex()
    {
        throw 'Regex() is OBSOLETE. Use modifier in SearchString'
        return ($this.esapi)::Everything_GetRegex()
    }

    [bool]Regex([bool]$aValue)
    {
        throw 'Regex() is OBSOLETE. Use modifier in SearchString'
        $this.esapi::Everything_SetRegex($aValue)
        return ($aValue)
    }

    [bool]MatchesCase()
    {
        throw 'MatchesCase() is OBSOLETE. Use modifier in SearchString'
        return $this.esapi::Everything_GetMatchCase()
    }
    [bool]MatchesCase([bool]$aValue)
    {
        throw 'MatchesCase() is OBSOLETE. Use modifier in SearchString'
        $this.esapi::Everything_SetMatchCase($aValue)
        return ($aValue)
    }
    [bool]MatchesPath()
    {
        throw 'MatchesPath() is OBSOLETE. Use modifier in SearchString'
        return ($this.esapi::Everything_GetMatchPath())
    }
    [bool]MatchesPath([bool]$bEnable)
    {
        throw 'MatchesPath() is OBSOLETE. Use modifier in SearchString'
        $this.esapi::Everything_SetMatchPath($bEnable)
        return($bEnable)
    }

    [string]QueryBase(){
        return($this.QueryBaseHolder.Value())
    }
    [string]QueryBase([string]$queryBase){
        $this.QueryBaseHolder.Value($queryBase)
        return($queryBase)
    }

    [string]SearchString(){
        return($this.SearchStringHolder.Value())
    }
    [string]SearchString([string]$searchString){
        $this.SearchStringHolder.Value($searchString)
        return($this.SearchString())
    }


    [ESAPI_SORT]SortOrder()
    {
        return ($this.esapi::Everything_GetSort())
    }
    [ESAPI_SORT]SortOrder([ESAPI_SORT]$aValue)
    {
        $this.esapi::Everything_SetSort($aValue)
        return ($aValue)
    }

    [ESAPI_REQUEST]RequestFlags()
    {
        return $this.esapi::Everything_GetRequestFlags()
    }
    [ESAPI_REQUEST]RequestFlags([ESAPI_REQUEST]$aValue)
    {
        $this.esapi::Everything_SetRequestFlags($aValue)
        return ($aValue)
    }

    [ESAPI_REQUEST]UnsetRequestFlag([ESAPI_REQUEST]$aFlag)
    {
        $current = $this.RequestFlags()
        if( ($current -band $aFlag) -eq $aFlag)
        {
            $current -= $aFlag
            $this.RequestFlags($current)
        }
        return $current
    }
    [ESAPI_REQUEST]SetRequestFlag([ESAPI_REQUEST]$aFlag)
    {
        $current = $this.RequestFlags()
        if( ($current -band $aFlag) -ne $aFlag )
        {
            $current += $aFlag
            $this.RequestFlags($current)
        }
        return $current
    }

    [ESAPI_ERROR]LastError()
    {
        return($this.esapi::Everything_GetLastError())
    }

    [string]ResultPathAt([int]$index)
    {
        return $this.esapi::GetResultPath($index)
    }

    [string]ResultFileNameAt([int]$index)
    {
        return $this.esapi::GetResultFileName($index)
    }

    SetSearchString(){
        if( $this.isSearchStringDirty ){
            $actualQueryString = $this.QueryBaseHolder.value()+' '+$this.SearchStringHolder.Value()
            $this.esapi::Everything_SetSearchW($actualQueryString)
            $this.isSearchStringDirty = $false
        }
    }

    [EverythingSearchResultElement[]]BuildResultSet([scriptblock]$filter){
        $this.results = @()
        for($i =0;$i -lt $this.esapi::Everything_GetNumResults();$i++)
        {
            $anElement = [EverythingSearchResultElement]::new(($i+1),$this.ResultFileNameAt($i),$this.ResultPathAt($i))
            if( (&$filter $anElement))
            {
                $this.results += $anElement
            }
        }
        return ($this.results)
    }

    [EverythingSearchResultElement[]]PerformQuery([scriptBlock]$filter)
    {
        $this.SetSearchString()
        $this.esapi::Everything_QueryW($true)
        return ($this.BuildResultSet($filter))
    }

    [EverythingSearchResultElement[]]PerformQuery()
    {
        return ($this.PerformQuery({$true}))
    }

    [EverythingSearchResultElement[]]PerformQuery([string]$pattern)
    {
        $this.SearchStringHolder.Value($pattern)
        return($this.PerformQuery())
    }

    [EverythingSearchResultElement[]]PerformQuery([string]$pattern,[scriptBlock]$filter)
    {
        $this.SearchStringHolder.Value($pattern)
        return($this.PerformQuery($filter))
    }

    [EverythingSearchResultElement[]]PerformQuery([string]$queryBase,[string]$pattern,[scriptBlock]$filter)
    {
        $this.QueryBaseHolder.Value($queryBase)
        $this.SearchStringHolder.Value($pattern)
        return($this.PerformQuery($filter))
    }

    [object[]]LastResults()
    {
        return ($this.results)
    }
    [object[]]ResultAt($index)
    {
        return ($this.results[$index])
    }

    [object[]]SelectResult([scriptblock]$aScriptBlock)
    {
        [object[]]$selection = @()

        $this.LastResults().foreach{
            if( Invoke-Command -ScriptBlock $aScriptBlock -ArgumentList $_ ){
                $selection += $_
            }
        }

        return ($selection)
    }
}
