param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
[DllImport("Everything64.dll", CharSet = CharSet.Unicode)]
public static extern UInt32 Everything_SetSearchW(string lpSearchString);
[DllImport("Everything64.dll")]
public static extern IntPtr Everything_GetSearchW();

[DllImport("Everything64.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr Everything_GetResultExtension(UInt32 nIndex);
[DllImport("Everything64.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr Everything_GetResultFileListFileName(UInt32 nIndex);
[DllImport("Everything64.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr Everything_GetResultFileName(UInt32 nIndex);
[DllImport("Everything64.dll", CharSet = CharSet.Unicode)]
public static extern IntPtr Everything_GetResultPath(UInt32 nIndex);

[DllImport("Everything64.dll", CharSet = CharSet.Unicode)]
public static extern void Everything_GetResultFullPathName(UInt32 nIndex, System.Text.StringBuilder lpString, UInt32 nMaxCount);

[DllImport("Everything64.dll")]
public static extern void Everything_SetMatchPath(bool bEnable);
[DllImport("Everything64.dll")]
public static extern void Everything_SetMatchCase(bool bEnable);
[DllImport("Everything64.dll")]
public static extern void Everything_SetMatchWholeWord(bool bEnable);
[DllImport("Everything64.dll")]
public static extern void Everything_SetRegex(bool bEnable);
[DllImport("Everything64.dll")]
public static extern void Everything_SetMax(UInt32 dwMax);
[DllImport("Everything64.dll")]
public static extern void Everything_SetOffset(UInt32 dwOffset);

[DllImport("Everything64.dll")]
public static extern bool Everything_GetMatchPath();
[DllImport("Everything64.dll")]
public static extern bool Everything_GetMatchCase();
[DllImport("Everything64.dll")]
public static extern bool Everything_GetMatchWholeWord();
[DllImport("Everything64.dll")]
public static extern bool Everything_GetRegex();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetMax();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetOffset();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetLastError();

[DllImport("Everything64.dll")]
public static extern bool Everything_QueryW(bool bWait);

[DllImport("Everything64.dll")]
public static extern void Everything_SortResultsByPath();

[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetNumFileResults();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetNumFolderResults();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetNumResults();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetTotFileResults();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetTotFolderResults();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetTotResults();
[DllImport("Everything64.dll")]
public static extern bool Everything_IsVolumeResult(UInt32 nIndex);
[DllImport("Everything64.dll")]
public static extern bool Everything_IsFolderResult(UInt32 nIndex);
[DllImport("Everything64.dll")]
public static extern bool Everything_IsFileResult(UInt32 nIndex);
[DllImport("Everything64.dll")]
public static extern void Everything_Reset();


[DllImport("Everything64.dll")]
public static extern void Everything_SetSort(UInt32 dwSortType);
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetSort();
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetResultListSort();
[DllImport("Everything64.dll")]
public static extern void Everything_SetRequestFlags(UInt32 dwRequestFlags);
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetRequestFlags();

[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetResultListRequestFlags();

[DllImport("Everything64.dll")]
public static extern bool Everything_GetResultSize(UInt32 nIndex, out long lpFileSize);

[DllImport("Everything64.dll")]
public static extern bool Everything_GetResultDateCreated(UInt32 nIndex, out long lpFileTime);
[DllImport("Everything64.dll")]
public static extern bool Everything_GetResultDateModified(UInt32 nIndex, out long lpFileTime);
[DllImport("Everything64.dll")]
public static extern bool Everything_GetResultDateAccessed(UInt32 nIndex, out long lpFileTime);
[DllImport("Everything64.dll")]
public static extern bool Everything_GetResultDateRun(UInt32 nIndex, out long lpFileTime);
[DllImport("Everything64.dll")]
public static extern bool Everything_GetResultDateRecentlyChanged(UInt32 nIndex, out long lpFileTime);

[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetResultAttributes(UInt32 nIndex);
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetResultRunCount(UInt32 nIndex);

[DllImport("Everything64.dll")]
public static extern UInt32 Everything_GetRunCountFromFileName(string lpFileName);
[DllImport("Everything64.dll")]
public static extern bool Everything_SetRunCountFromFileName(string lpFileName, UInt32 dwRunCount);
[DllImport("Everything64.dll")]
public static extern UInt32 Everything_IncRunCountFromFileName(string lpFileName);


// Wrapper by C#
public static string GetSearchString()
{
    return(System.Runtime.InteropServices.Marshal.PtrToStringUni(Everything_GetSearchW()));
}

public static string GetResultFileName(UInt32 nIndex)
{
    return (System.Runtime.InteropServices.Marshal.PtrToStringUni(Everything_GetResultFileName(nIndex)));
}

public static string GetResultPath(UInt32 nIndex)
{
    return (System.Runtime.InteropServices.Marshal.PtrToStringUni(Everything_GetResultPath(nIndex)));
}

public static DateTime GetResultDateCreated(UInt32 nIndex)
{
    long aDate;
    Everything_GetResultDateCreated(nIndex,out aDate);
    return(DateTime.FromFileTime(aDate));
}
public static DateTime GetResultDateModified(UInt32 nIndex)
{
    long aDate;
    Everything_GetResultDateModified(nIndex,out aDate);
    return(DateTime.FromFileTime(aDate));
}
public static DateTime GetResultDateAccessed(UInt32 nIndex)
{
    long aDate;
    Everything_GetResultDateAccessed(nIndex,out aDate);
    return(DateTime.FromFileTime(aDate));
}
public static DateTime GetResultDateRun(UInt32 nIndex)
{
    long aDate;
    Everything_GetResultDateRun(nIndex,out aDate);
    return(DateTime.FromFileTime(aDate));
}
public static DateTime GetResultDateRecentlyChanged(UInt32 nIndex)
{
    long aDate;
    Everything_GetResultDateRecentlyChanged(nIndex,out aDate);
    return(DateTime.FromFileTime(aDate));
}

public static long GetResultSize(UInt32 nIndex)
{
    long aSize;
    Everything_GetResultSize(nIndex,out aSize);
    return(aSize);
}
public static UInt32 GetResultAttributes(UInt32 nIndex)
{
    return (Everything_GetResultAttributes(nIndex));
}
public static UInt32 GetNumFileResults()
{
    return(Everything_GetNumFileResults());
}
public static UInt32 GetNumFolderResults()
{
    return(Everything_GetNumFolderResults());
}

"@
$DLLNAME = 'handjive.everythingapi.dll'
$MODULENAME = 'EverythingAPI'
$NAMESPACE = 'handjive.Everything'
#$REFS = @( 'handjive.Foundation.dll'  )
#$REFS = [Reflection.Assembly]::LoadFrom('handjive.Foundation.dll')
#$REFS = [Reflection.Assembly]::Load('handjive.Foundation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=22b2bd9641469b21, processorArchitecture=MSIL')

<#
if( $Build ){
    #add-type -typeDefinition $cscode -OutputAssembly "$PSScriptROOT\$DLLNAME" -ReferencedAssemblies @($REFS) -OutputType Library
    AssemblyBuilder -MemberDefinition -Name $MODULENAME -Namespace $NAMESPACE -Source $cscode -AssemblyName $DLLNAME -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
#>
Add-Type -MemberDefinition $cscode -Name 'EverythingAPI' -Namespace 'handjive.Everything' -OutputAssembly "$PSScriptRoot\handjive.everythingapi.dll" -OutputType Library
<#
$DESTINATION_PATH = 'C:\Users\handjive\Scripts.PowerShell\Modules\assemblies'
$ASSEMBLY_NAME = 'handjive.everythingapi.dll'
$ASSEMBLY_PATH = Join-Path -Path $DESTINATION_PATH -childPath $ASSEMBLY_NAME

if( Test-Path -LiteralPath $ASSEMBLY_PATH ){
    Write-Host 'Saving current assembly '
    $newName = [String]::Format('{0}-saved{1}',$ASSEMBLY_NAME,(Get-Date -format 'yyyyMMddhhMMss'))
    $newPath = Join-Path -Path $DESTINATION_PATH -childPath $newName
    Move-Item -LiteralPath $ASSEMBLY_PATH -Destination $newPath
}
Write-Host 'Generating assembly'
#add-type -typeDefinition $cscode -OutputAssembly $ASSEMBLY_PATH -OutputType Library

add-type -Name 'EverythingAPIDLL' -memberDefinition $esapi_cscode -OutputAssembly $ASSEMBLY_PATH -OutputType Library
#>[