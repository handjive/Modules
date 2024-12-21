using namespace handjive.Everything
using module handjive.Adaptors

class EverythingResultAccessor : PluggableIndexer, IEverythingResultAccessor{
    static $CONVERTERCLASS = [EverythingResultConverter]
    
    [type]$pvResultType
    [EverythingResultConverter]$pvConverter
    [IEverything]$es
    
    EverythingResultAccessor([IEverything]$es) : base(){ 
        $this.es = $es
        $this.Subject = $this.ConverterFor($es,$es.ResultType)
        $this.Initialize()
    }
    EverythingResultAccessor([IEverything]$es,[type]$resultType) : base(){ 
        $this.es = $es
        $this.Subject = $this.ConverterFor($es,$resultType)
        $this.Initialize()
    }

    hidden [EverythingResultConverter]ConverterFor([IEverything]$es,[type]$type){
        return $this.gettype()::CONVERTERCLASS::ConverterFor($es,$type)
    }

    hidden [void]Initialize(){
        $this.BuildBlocks()
    }

    hidden [void]BuildBlocks(){
        $this.GetCountBlock = { 
            param($adaptor) 
            $adaptor.Subject.Count 
        }
        $this.GetItemBlock = { 
            param($adaptor,$index) 
            $adaptor.Subject.Convert($index) 
        }
        $this.SetItemBlock = { 
            param($adaptor,$index,$value) 
            throw "Unable to set item for this object" 
        }

    }

    hidden [object]get_ResultType(){
        return $this.pvResultType
    }
    hidden set_ResultType([object]$type){
        $this.pvResultType = $type
        $this.SelectConverterFor($type)
    }
        
    [void]SelectConverter([type]$type){
        # コンバータがあるtypeか確認?
        $this.Subject = $this.ConverterFor($this.es,$type)
    }
}