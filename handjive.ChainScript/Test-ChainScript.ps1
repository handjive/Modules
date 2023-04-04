switch($args){
    1 {
        $element1 = [ChainScriptElement]::new()
        $element1.Context.Start = 0
        $element1.Context.Stop = 9
        $element1.Block = { 
            param($context,$workingset,$control,$depth)
            if( $null -eq $workingset.Current[$depth] ){
                $workingset.Current[$depth] = $context.Start
                $control.Flow = [ChainFlow]::Forward
            }
            elseif( $workingset.Current[$depth] -lt $context.Stop ){
                $workingset.Current[$depth]++
                $control.Flow = [ChainFlow]::Forward
            }
            else{
                $control.Flow = [ChainFlow]::Terminate
            }
        }

        $element2 = [ChainScriptElement]::new()
        $element2.Context.Start = 0
        $element2.Context.Stop = 9
        $element2.Block = { 
            param($context,$workingset,$control,$depth)
            if( $null -eq $workingset.Current[$depth] ){
                $workingset.Current[$depth] = $context.Start
                $control.Flow = [ChainFlow]::Forward
            }
            elseif( $workingset.Current[$depth] -lt $context.Stop ){
                $workingset.Current[$depth]++
                $control.Flow = [ChainFlow]::Forward
            }
            else{
                $workingset.Current[$depth] = $null
                $control.Flow = [ChainFlow]::Backward
            }
        }

        $element3 = [ChainScriptElement]::new()
        $element3.Context.Start = 0
        $element3.Context.Stop = 9
        $element3.Block = { 
            param($context,$workingset,$control,$depth)
            if( $null -eq $workingset.Current[$depth] ){
                $workingset.Current[$depth] = $context.Start
                $control.Flow = [ChainFlow]::Ready
            }
            elseif( $workingset.Current[$depth] -eq $context.Stop ){
                $workingset.Current[$depth] = $null
                $control.Flow = [ChainFlow]::Backward
            }
            else{
                $workingset.Current[$depth]++
                $control.Flow = [ChainFlow]::Ready
            }
        }

        $chain = [ChainScript]::new()
        $chain.InitializeBlock = {
            param($substance)
            $substance.workingset.Current = @($null,$null,$null)
        }
        ($element1,$element2,$element3).foreach{ $chain.AddChain($_) }
        $chain.Initialize()
        while( $chain.Perform() ){
            write-host $chain.workingset.Current
            $chain |out-null
        }
    }
    2 {
        $dict = [Collections.Specialized.OrderedDictionary]::new()
        $dict.add(0,@( 0..9 ))
        $dict.add(1,@(10..19))
        $dict.add(2,@(20..29))
        $dict.add(3,@(30..39))
        $dict.add(4,@(40..49))

        $chain = [ChainScript]::new()
        $elem1 = $chain.NewElement()
        $elem1.context.Dictionary = $dict
        $elem1.context.keyEnumerator = $dict.Keys.GetEnumerator()
        $elem1.Block = {
            param($context,$workingset,$control,$depth)
            $stat = $context.keyEnumerator.MoveNext()
            if( $stat ){
                $aKey = $context.keyEnumerator.Current
                $workingset.valueEnumerator = $context.Dictionary[$aKey].GetEnumerator()
                $control.Flow = [ChainFlow]::Forward
            }
            else{
                $control.Flow = [ChainFlow]::Terminate
            }
        }
        $elem2 = $chain.NewElement()
        $elem2.Block = {
            param($context,$workingset,$control,$depth)
            if( $workingset.valueEnumerator.MoveNext() ){
                $control.Flow = [ChainFlow]::Ready
            }
            else{
                $control.Flow = [ChainFlow]::Backward
            }
        }

        while($chain.Perform() ){
            write-host $chain.chain[0].context.keyEnumerator.Current $chain.workingset.valueEnumerator.Current
        }
    }
}