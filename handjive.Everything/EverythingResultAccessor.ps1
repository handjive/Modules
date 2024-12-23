using namespace handjive.Everything
using module handjive.Adaptors

enum EV_EverythingResultAccessor{ ConversionFinished; }

class EverythingResultAccessor : PluggableIndexer, IEverythingResultAccessor{
    static $CONVERTERCLASS = [EverythingResultConverter]
    
    [type]$pvResultType
    [IEverything]$es
    
    EverythingResultAccessor([IEverything]$es) : base($this.ConverterFor($es,$es.ResultType)){ 
        $this.es = $es
        $this.ResultType = $es.ResultType
    }
    EverythingResultAccessor([IEverything]$es,[type]$resultType) : base($this.ConverterFor($es,$resultType)){ 
        $this.es = $es
        $this.ResultType = $resultType
    }

    hidden [EverythingResultConverter]ConverterFor([IEverything]$es,[type]$type){
        return $this.gettype()::CONVERTERCLASS::ConverterFor($es,$type)
    }

    hidden [void]Initialize(){
        ([PluggableIndexer]$this).Initialize()
        $this.BuildBlocks()
    }

    hidden [void]BuildBlocks(){
        $this.GetCountBlock = { 
            param($adaptor) 
            $adaptor.Subject.Count 
        }
        $this.GetItemBlock = { 
            param($adaptor,$index) 
            $result = $adaptor.Subject.Convert($index) 
            $this.TriggerEvent([EV_EverythingResultAccessor]::ConversionFinished,@($result))
            $result
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
        $this.ConverterFor($this.es,$type)
    }
        
    [void]SelectConverter([type]$type){
        # コンバータがあるtypeか確認?
        $this.Subject = $this.ConverterFor($this.es,$type)
    }
}