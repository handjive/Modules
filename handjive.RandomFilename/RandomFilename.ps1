class RandomFilename : System.IDisposable{
    [string]$name
    [string]$path
    [string]$FullPath
    
    RandomFilename([string]$path){
        $this.Path = $path
        $this.Name = [String]::Format('{0}-{1}',$golbal:PID,([IO.Path]::GetRandomFileName()))
        $this.FullPath = Join-Path -Path $this.Path -ChildPath $this.name
    }

    Dispose(){
        if( Test-Path -Path $this.FullPath ){
            Remove-Item -LiteralPath $this.FullPath
        }
    }
}