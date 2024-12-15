class RecycleableRemover{
    static $Current = [RecycleableRemover]::new()

    hidden [__ComObject]$substance

    RecycleableRemover(){
        $this.substance = (New-Object -ComObject Shell.Application).NameSpace(10) 
    }


    Remove([IO.FileSystemInfo]$fsi){
        $this.substance.MoveHere($fsi.FullName)
    }

    Remove([string]$fullPath){
        $fsi = Get-Item -Path $fullPath
        $this.Remove($fsi)
    }

    <#Remove([string]$fileOrDirectoryname){
        $fsi = Get-Item -literalpath $fileOrDirectoryName
        $this.Remove($fsi)
    }#>

    RemoveAll([Collections.Generic.IEnumerable[object]]$filesOrDirectorys){
        $filesOrDirectorys.foreach{
            $this.Remove($_)
        }
    }
}