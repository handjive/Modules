class Config : HashTable{
    static [Config]$Current 
    [string]$Filename = $filename

    static [Config]LoadFromSpecifiedOrDefault([string]$commandPath,[string]$filename){
            $actualFilename = $filename
        if( "" -eq $filename ){
            $actualFilename = $commandPath.Trim()
            $aExt = Split-Path $actualFilename -Extension
            $actualFilename = $actualFilename.replace($aExt,'.json')
        }
        
        if( !(Test-Path -LiteralPath $actualFilename) ){
            $msg = [String]::Format('Configuration file "{0}" does not found',$actualFilename)
            throw ([System.IO.FileNotFoundException]::new($msg))
        }
        $values = Get-Content $actualFilename -Raw |ConvertFrom-Json -AsHashtable
        #Add-Member -InputObject $values -NotePropertyName Runtime -NotePropertyValue @{} 
        $values['Runtime']=@{}  # HashTable for Runtime settings
        [Config]::Current = [Config]::new($actualFilename,$values)
        
        return([Config]::Current) | out-null
    }
    
    Config([string]$filename,[Collections.IDictionary]$aHash) : base($aHash){
        $this.Filename = $filename
    }

}
