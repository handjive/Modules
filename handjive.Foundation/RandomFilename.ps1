class RandomFilename : System.IDisposable{
    [string]$Name
    [string]$Path
    [string]$FullPath
    [IO.FileSystemInfo]$FileSystemInfo
    
    RandomFilename([string]$path){
        $this.Path = $path
        $this.BuildPath()
    }
    RandomFilename(){
        $this.Path = $ENV:TEMP
        $this.BuildPath()
    }

    hidden [void]BuildPath(){
        $this.Name = [String]::Format('{0}-{1}',$global:pid,([IO.Path]::GetRandomFileName()))
        $this.FullPath = Join-Path -Path $this.Path -ChildPath $this.Name
    }
    
    [IO.FileSystemInfo]CreateFile(){
        $this.fileSystemInfo = New-Item -LiteralPath $this.FullPath -ItemType File
        return $this.FileSystemInfo
    }
    [IO.FileSystemInfo]CreateDirectory(){
        $this.fileSystemInfo = New-Item -Path $this.FullPath -ItemType Directory
        return $this.FileSystemInfo
    }

    Dispose(){
        if( Test-Path -Path $this.FullPath ){
            Remove-Item -LiteralPath $this.FullPath
        }
    }
}