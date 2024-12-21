using namespace handjive.Everything
using module handjive.Collections
using module handjive.Adaptors

class EverythingSearchResultElement : ISearchResultElement,IComparable, ICloneable {
    static [object]$DefaultComparer = [AspectComparer]::new('Name')
    hidden [string]$wpvQueryBase
    hidden [int]$wpvNumber
    hidden [string]$wpvName
    hidden [string]$wpvContainerPath
    [object]$Comparer

    EverythingSearchResultElement([int]$anIndex,[string]$aName,[string]$aContainer)
    {
        $this.Number = $anIndex
        $this.Name = $aName
        $this.ContainerPath = $aContainer
        $this.Comparer = [EverythingSearchResultElement]::DefaultComparer
    }
    EverythingSearchResultElement()
    {
        $this.Comparer = [EverythingSearchResultElement]::DefaultComparer

        
    }

    <# Reponsibility for IComparable #>
    [int] CompareTo([object]$left){
        return ($this.Comparer.PSCompare($this,$left))
    }

    <# Responsibility for ICloneable #>
    [object]Clone(){
        $newOne = ($this.gettype())::new()
        $newOne.Number = $this.Number
        $newOne.Name = $this.Name
        $newOne.ContainerPath = $this.ContainerPath
        return $newOne
    }

    <# Property Accessors #>
    hidden [string]get_QueryBase(){
        return ($this.wpvQueryBase)
    }
    hidden set_QueryBase([string]$value){
        $this.wpvQueryBase = $value
    }

    hidden [int]get_Number(){
        return ($this.wpvNumber)
    }
    hidden set_Number([int]$value){
        $this.wpvNumber = $value
    }

    hidden [string]get_Name(){
        return ($this.wpvName)
    }
    hidden set_Name([string]$value){
        $this.wpvName = $value
    }

    [string]get_ContainerPath(){
        return($this.wpvContainerPath)
    }
    set_ContainerPath([string]$value){
        $this.wpvContainerPath = $value
    }

    [string]get_FullName(){
        return $this.AsFullPath()
    }


    <# Public Methods #>
    [string]AsFullPath()
    {
        return (Join-Path -Path $this.ContainerPath -ChildPath $this.Name)
    }
    [object]AsFilesystemInfo()
    {
        return Get-Item -literalPath $this.AsFullPath()
    }

    OnInjectionComplete([object]$elem)
    {
    }
}
