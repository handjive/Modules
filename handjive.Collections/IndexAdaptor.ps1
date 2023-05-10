<#
    $ixa = [IndexAdaptor]::new($aBag)
    $ixa.GetItemBlock[[int]] = { param($substance,$index) $substance.elements[$index] }
    $ixa.GetItemBlock[[object]] = { param($substance,$index,$value) $substance.elements[[int]$index] = $value }
    $ixa.GetItemBlock[[object]] = { param($substance,$index,$value) $substance.elements[[object]$index] = $value }
#>

<# 
# IndexAdaptorのデフォルト集
#>
class DefaultProvider_IndexAdaptor{
    # GetCountBlock,(Get|Set)IndexBlock,On(Get|Set)IndexOutofRange,IndexRangeValidatorに渡される処理対象を取り出す
    [ScriptBlock]$GetSubjectBlock = { 
        param(
             $substance     # Adaptorの対象となるオブジェクト
            ,$workingset    # 作業用領域
            ,$resultHolder  # 処理対象となるオブジェクトの格納先(ScriptBlockがIEnumeratorを返すと自動展開されてしまうためこれを経由)
        )      
        $resultHolder.Value = $substance # デフォルトではAdaptorの対象オブジェクトがそのまま返る
    }

    # Enumeratorを取得するブロック
    [ScriptBlock]$GetEnumeratorBlock = {
        param(
             $subject       # Enumeratorを取得するために使用するオブジェクト(GetSubjectBlockの戻り値)
            ,$workingset    # 作業用領域
            ,$result        # 処理対象となるオブジェクトの格納先(ScriptBlockがIEnumeratorを返すと自動展開されてしまうためこれを経由)
        )
        $methods = $subject.gettype().GetMethods() | where-object { $_.Name -eq 'GetEnumerator' }
        if( $null -eq $methods ){
            $result.Value = [PluggableEnumerator]::Empty()
        }
        else{
            $enumerator = $subject.GetEnumerator()
            if( $enumerator -is [Collections.Generic.IEnumerator[object]] ){
                $enumerator.Reset()
                $result.Value = $enumerator
            }
            else{
                $enumerator.Reset()
                $result.Value = [PluggableEnumerator]::InstantWrapOn($enumerator)
            }
        }
    }

    # プロパティ"Count"の実行ブロック
    [ScriptBlock]$GetCountBlock = {
        param(
             $subject           # Countを取得するために使用するオブジェクト(GetSubjectBlockの戻り値)
            ,$workingset        # 作業用領域
        )
        $subject.Count          # Countとして返される値
    }

    # "object this[](T index)"の実行ブロック(Get)
    [HashTable]$GetItemBlock = @{
        Int={                   # "object this[](int index)"の実行ブロック
            param(
                 $subject        # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                ,$workingset    # 作業用領域
                ,[int]$index     # インデックス
            )         
            $subject[$index]    # []の戻り値
        };
        Object={                # "object this[](object index)"の実行ブロック
            param(
                 $subject        # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                ,$workingset    # 作業用領域
                ,[object]$index # インデックス
            ) 
            $subject[$index]  # []の戻り値
        }; 
    }

    # "object this[](T index)"の実行ブロック(Set)
    [HashTable]$SetItemBlock = @{
        Int={                   # "object this[](int index)"の実行ブロック
            param(
                  $subject      # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                 ,$workingset   # 作業用領域
                 ,[int]$index   # インデックス
                ,$value         # セットする値
            )
            $subject[$index]= $value 
        }; 
        Object={                # "object this[](object index)"の実行ブロック
            param(
                  $subject       # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                 ,$workingset    # 作業用領域
                 ,[object]$index # インデックス
                ,$value         # セットする値
            )        
            $subject[$index]= $value 
        }; 
    }
    
    # インデックスの範囲検証
    # ブロックの評価結果が $true=範囲内、$false=範囲外
    [Hashtable]$IndexRangeValidator = @{
        Int={ 
            param(
                  $substance     # GetSubjectBlockの戻り値
                 ,$workingset    # 作業用領域
                 ,$index         # 指定されたインデックス
                )
            $true 
        }; 
        Object={
            param(
                  $substance     # GetSubjectBlockの戻り値
                 ,$workingset    # 作業用領域
                 ,$index         # 指定されたインデックス
            ) 
            $true 
        }; 
    }

    # Getインデックスが範囲外だった時の処理
    # (IndexRangeValidatorが$falseを返したときに実行される)
    [Hashtable]$OnGetIndexOutofRange = @{
        Int={       # 整数インデックス用
            param(
                 $subject       # GetSubjectBlockの戻り値
                ,$workingset    # 作業用領域
                ,$index         # 指定されたインデックス
            ) 
            $null               
        };
        Object={    # オブジェクトインデックス用
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$workingset    # 作業用領域
                ,$index         # 指定されたインデックス
            ) 
            $null               
        };
    }    
    # Setインデックスが範囲外だった時の処理
    # (IndexRangeValidatorが$falseを返したときに実行される)
    [Hashtable]$OnSetIndexOutofRange = @{
        Int={       # 整数インデックス用
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
                ,$workingset    # 作業用領域
                ,$value         # セットしようとしたオブジェクト
            ) 
        }; 
        Object={    # オブジェクトインデックス用
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
                ,$workingset    # 作業用領域
                ,$value         # セットしようとしたオブジェクト
            ) 
        };
    }
}

<#
# IEnumerableとobject this[int|object index]{get;set;}のAdaptor
#>
class IndexAdaptor : handjive.Collections.IndexableEnumerableBase,handjive.Collections.IIndexAdaptor{
    [object]$substance

    [ScriptBlock]$GetCountBlock
    [ScriptBlock]$GetSubjectBlock
    [ScriptBlock]$GetEnumeratorBlock
    [HashTable]$GetItemBlock
    [HashTable]$SetItemBlock
    [HashTable]$OnGetIndexOutofRange
    [HashTable]$OnSetIndexOutofRange
    [HashTable]$IndexRangeValidator

    [HashTable]$WorkingSet

    IndexAdaptor([Collections.Generic.IEnumerable[object]]$substance){
        $this.initialize($substance)
    }
    IndexAdaptor([Collections.IEnumerable]$substance){
        $this.initialize($substance)
    }
    IndexAdaptor([object]$substance){
        $this.initialize($substance)
    }
    
    hidden initialize([object]$substance){
        $defaults = [DefaultProvider_IndexAdaptor]::new()
        $this.GetSubjectBlock = $defaults.GetSubjectBlock
        $this.GetEnumeratorBlock = $defaults.GetEnumeratorBlock
        $this.GetCountBlock   = $defaults.GetCountBlock
        $this.GetItemBlock    = $defaults.GetItemBlock
        $this.SetItemBlock    = $defaults.SetItemBlock

        $this.IndexRangeValidator  = $defaults.IndexRangeValidator
        $this.OnGetIndexOutofRange = $defaults.OnGetIndexOutofRange
        $this.OnSetIndexOutofRange = $defaults.OnSetIndexOutofRange

        $this.WorkingSet = @{}

        $this.substance = $substance
    }

    hidden [object]extractResult([Hashtable]$result){
        $key = $result.keys[0]
        return ($result[$key])[-1]
    }
    hidden [object]getSubject(){
        $subs = $this.substance
        $result = @{}
        &($this.GetSubjectBlock) $subs $this.WorkingSet $result | out-null
        
        $subject = $this.extractResult($result)
        return ($subject)
    }


    <#
    # IIndexAdaptor members
    #>
    [int]get_Count(){
        return (&$this.GetCountBlock $this.getSubject() $this.WorkingSet)
    }

    <#
    # IndexableEnumerableBase subclass responsibilities
    #>
    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        if( $null -eq $this.GetEnumeratorBlock ){
            return [PluggableEnumerator]::Empty()
        }

        $result = @{}
        &($this.GetEnumeratorBlock) $this.getSubject() $this.WorkingSet $result | out-null
        return $this.extractResult($result)
    }

    hidden [object]PSGetItem_IntIndex([int]$index){
        if( !(&$this.IndexRangeValidator.Int $this.getSubject() $this.WorkingSet $index) ){
            return &$this.OnGetIndexOutofRange.Int $this.getSubject() $this.WorkingSet $index
        }
        else{
            return( (&$this.GetItemBlock.Int $this.getSubject() $this.WorkingSet $index) )
        }
    }
    hidden PSSetItem_IntIndex([int]$index,[object]$value){
        if( !(&$this.IndexRangeValidator.Int $this.getSubject() $this.WorkingSet $index) ){
            &$this.OnSetIndexOutofRange.Int $this.getSubject() $this.WorkingSet $index $value
        }
        else{
            &$this.SetItemBlock.Int $this.getSubject() $this.WorkingSet $index $value
        }
    }
    hidden [object]PSGetItem_ObjectIndex([object]$index){
        if( !(&$this.IndexRangeValidator.Object $this.getSubject() $this.WorkingSet $index) ){
            return &$this.OnGetIndexOutofRange.Object $this.getSubject() $this.WorkingSet $index
        }
        else{
            return( (&$this.GetItemBlock.Object $this.getSubject() $this.WorkingSet $index) )
        }
    }
    hidden PSSetItem_ObjectIndex([object]$index,[object]$value){
        if( !(&$this.IndexRangeValidator.Object $this.getSubject() $this.WorkingSet $index) ){
            &$this.OnSetIndexOutofRange.Object $this.getSubject() $this.WorkingSet $index $null
        }
        else{
            &$this.SetItemBlock.Object $this.getSubject() $this.WorkingSet $index $value
        }
    }
}