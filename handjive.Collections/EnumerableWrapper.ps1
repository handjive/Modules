# IWrapper → IAdaptorで書き換え

#using module handjive.Adaptors
using namespace handjive.Adaptors
using namespace handjive.Collections

class PluggableEnumerableWrapper : handjive.Collections.EnumerableBase, handjive.Foundation.IAdaptor{
    static [PluggableEnumerableWrapper]On([object]$Subject){
        $newOne = [PluggableEnumerableWrapper]::new($Subject)
        return $newOne
    }

    [object]$wpvSubject
    [HashTable]$WorkingSet
    [ScriptBlock]$GetEnumeratorBlock = { param($Subject,$workingset,$result) [PluggableEnumerator]::Empty() }

    PluggableEnumerableWrapper([object]$Subject){
        $this.Subject = $Subject
        $this.WorkingSet = @{}
    }

    [object]get_Subject(){
        return $this.wpvSubject
    }
    set_Subject([object]$Subject){
        $this.wpvSubject = $Subject
    }

    hidden [object]extractResult([Hashtable]$result){
        $key = $result.keys[0]
        return ($result[$key])[-1]
    }

    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        $result = @{}
        &$this.GetEnumeratorBlock $this.Subject $this.WorkingSet $result | out-null
        return($this.extractResult($result))
    }

    [Collections.Generic.IEnumerator[object]]GetEnumerator(){
        return $this.PSGetEnumerator()
    }
}

<#
    Collections.Generic.IEnumerator<object>のCollections.Generic.IEnumerable<object>へのWrapper
#>
class EnumerableWrapper : EnumerableBase ,handjive.Foundation.IAdaptor{
    static [EnumerableWrapper]On([Collections.Generic.IEnumerator[object]]$Subject){
        $newOne = [EnumerableWrapper]::new($Subject)
        return ($newOne)
    }
    static [EnumerableWrapper]On([Collections.IEnumerator]$Subject){
        $newOne = [EnumerableWrapper]::new($Subject)
        return ($newOne)
    }
    static [EnumerableWrapper]On([object]$Subject){
        $newOne = [EnumerableWrapper]::new($Subject)
        return ($newOne)
    }

    [object]$wpvSubject

    EnumerableWrapper([Collections.Generic.IEnumerator[object]]$Subject){
        $this.Subject = $Subject
    }
    EnumerableWrapper([Collections.IEnumerator]$Subject){
        $this.Subject = $Subject
    }
    EnumerableWrapper([object]$Subject){
        $methods = $Subject.gettype().GetMethods() | where-object { $_.Name -eq 'GetEnumerator' }
        if( $null -eq $methods ){
            throw ([String]::Format('{0} has not GetEnumerator.',$Subject.gettype()))
        }
        else{
            $this.Subject = $Subject
        }

    }

    [object]get_Subject(){
        return $this.wpvSubject
    }
    set_Subject([object]$Subject){
        $this.wpvSubject = $Subject
    }

    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        if( $this.Subject -is [Collections.Generic.IEnumerator[object]] ){
            $this.Subject.Reset()
            return $this.Subject
        }
        else{
            return ([PluggableEnumerator]::InstantWrapOn($this.Subject))
        }
    }

    [Collections.Generic.IEnumerator[object]]GetEnumerator(){
        return $this.PSGetEnumerator()
    }
}

