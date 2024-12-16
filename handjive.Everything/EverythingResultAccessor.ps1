class EverythingResultAccessor{
    static [EverythingResultAccessor]$Default = [EverythingResultAccessor]::new()

    hidden [handjive.Everything.EverythingAPI]$esapi = [handjive.Everything.EverythingAPI]


    [string]PathAt([int]$index)
    {
        return $this.esapi::GetResultPath($index)
    }
    [string]FileNameAt([int]$index)
    {
        return $this.esapi::GetResultFileName($index)
    }

}
