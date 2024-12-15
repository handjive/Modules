<#
static void DeleteDirectory(string directory, FileIO.DeleteDirectoryOption onDirectoryNotEmpty)
static void DeleteDirectory(string directory, FileIO.UIOption showUI, FileIO.RecycleOption recycle)
static void DeleteDirectory(string directory, FileIO.UIOption showUI, FileIO.RecycleOption recycle, FileIO.UICancelOption onUserCancel)}
#>

#[RecycleableRemover]::Current.Remove('C:\Users\handjive\MusicWorkshop\[真倉翔×あざらし県] 異世界大富豪勇者様！ 第01巻')

$files = Get-ChildItem -Path . -Filter '*dll-saved*' -Recurse
#[RecycleableRemover]::Current.Remove($files[0])

[RecycleableRemover]::Current.RemoveAll($files)
