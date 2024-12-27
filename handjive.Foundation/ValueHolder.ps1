#using module handjive.LimitedList
class ValueHolder : ValueModel{
        
    ValueHolder() : base(){
    }
    ValueHolder([object]$value) : base($value){
    }

    hidden [void]Initialize()
    {
        Write-Debug "Initializing in $this.gettype()"
        ([ValueModel]$this).Initialize()

    }
}


