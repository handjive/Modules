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
    static [ScriptBlock]$DefaultGetSubjectBlock = { 
        param(
            $substance          # Adaptorの対象となるオブジェクト
            ,$resultHolder      # 処理対象となるオブジェクトの格納先(ScriptBlockがIEnumeratorを返すと自動展開されてしまうためこれを経由)
        )      
        $resultHolder.Value = $substance # デフォルトではAdaptorの対象オブジェクトがそのまま返る
    }

    # プロパティ"Count"の実行ブロック
    static [ScriptBlock]$DefaultGetCountBlock = {
        param($subject)         # Countを取得するために使用するオブジェクト(GetSubjectBlockの戻り値)
        $subject.Count          # Countとして返される値
    }

    # "object this[](T index)"の実行ブロック(Get)
    static [HashTable]$DefaultGetItemBlock = @{
        Int={                   # "object this[](int index)"の実行ブロック
            param(
                $subject        # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                ,[int]$index     # インデックス
            )         
            $subject[$index]    # []の戻り値
        };
        Object={                # "object this[](object index)"の実行ブロック
            param(
                $subject        # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                ,[object]$index # インデックス
            ) 
            $substance[$index]  # []の戻り値
        }; 
    }

    # "object this[](T index)"の実行ブロック(Set)
    static $DefaultSetItemBlock = @{
        Int={                   # "object this[](int index)"の実行ブロック
            param(
                 $subject       # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                ,[int]$index    # インデックス
                ,$value         # セットする値
            )
            $subject[$index]= $value 
        }; 
        Object={                # "object this[](object index)"の実行ブロック
            param(
                 $subject       # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                ,[object]$index # インデックス
                ,$value         # セットする値
            )        
            $subject[$index]= $value 
        }; 
    }
    
    # インデックスの範囲検証
    # ブロックの評価結果が $true=範囲内、$false=範囲外
    static $DefaultIndexRangeValidator = @{
        Int={ 
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
                )
            $true 
        }; 
        Object={
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
            ) 
            $true 
        }; 
    }

    # Getインデックスが範囲外だった時の処理
    # (IndexRangeValidatorが$falseを返したときに実行される)
    static $DefaultOnGetIndexOutofRange = @{
        Int={       # 整数インデックス用
            param(
                 $subject       # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
            ) 
            $null               
        };
        Object={    # オブジェクトインデックス用
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
            ) 
            $null               
        };
    }    
    # Setインデックスが範囲外だった時の処理
    # (IndexRangeValidatorが$falseを返したときに実行される)
    static $DefaultOnSetIndexOutofRange = @{
        Int={       # 整数インデックス用
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
                ,$value         # セットしようとしたオブジェクト
            ) 
        }; 
        Object={    # オブジェクトインデックス用
            param(
                 $substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
                ,$value         # セットしようとしたオブジェクト
            ) 
        };
    }
}

<#
# IEnumerableとobject this[int|object index]{get;set;}のAdaptor
#>
class IndexAdaptor : handjive.Collections.IndexableEnumerableBase,handjive.Collections.IIndexAdaptor{
    static $DefaultProvider = [DefaultProvider_IndexAdaptor]

    [object]$substance
    [ScriptBlock]$GetCountBlock
    [ScriptBlock]$GetSubjectBlock
    [HashTable]$GetItemBlock
    [HashTable]$SetItemBlock
    [HashTable]$OnGetIndexOutofRange
    [HashTable]$OnSetIndexOutofRange
    [HashTable]$IndexRangeValidator

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
        $defaults = ($this.gettype())::DefaultProvider
        $this.substance = $substance
        $this.GetSubjectBlock = $defaults::DefaultGetSubjectBlock
        $this.GetCountBlock   = $defaults::DefaultGetCountBlock
        $this.GetItemBlock    = $defaults::DefaultGetItemBlock
        $this.SetItemBlock    = $defaults::DefaultSetItemBlock

        $this.IndexRangeValidator  = $defaults::DefaultIndexRangeValidator
        $this.OnGetIndexOutofRange = $defaults::DefaultOnGetIndexOutofRange
        $this.OnSetIndexOutofRange = $defaults::DefaultOnSetIndexOutofRange
    }

    hidden [object]getSubject(){
        $subs = $this.substance
        $resultset = @{}
        &($this.GetSubjectBlock) $subs $resultset | out-null
        $key = $resultset.keys[0]
        $subject = ($resultset[$key])[0]
        return ($subject)
    }


    <#
    # IIndexAdaptor members
    #>
    [int]get_Count(){
        return (&$this.GetCountBlock $this.getSubject())
    }

    <#
    # IndexableEnumerableBase subclass responsibilities
    #>
    [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        return $this.substance.GetEnumerator()
    }

    hidden [object]get_Item([int]$index){
        if( !(&$this.IndexRangeValidator.Int $this.getSubject() $index) ){
            return &$this.OnGetIndexOutofRange.Int $this.getSubject() $index
        }
        else{
            return( (&$this.GetItemBlock.Int $this.getSubject() $index) )
        }
    }
    hidden set_Item([int]$index,[object]$value){
        if( !(&$this.IndexRangeValidator.Int $this.getSubject() $index) ){
            &$this.OnSetIndexOutofRange.Int $this.getSubject() $index $value
        }
        else{
            &$this.SetItemBlock.Int $this.getSubject() $index $value
        }
    }

    hidden [object]get_Item([object]$index){
        if( !(&$this.IndexRangeValidator.Object $this.getSubject() $index) ){
            return &$this.OnGetIndexOutofRange.Object $this.getSubject() $index
        }
        else{
            return( (&$this.GetItemBlock.Object $this.getSubject() $index) )
        }
    }
    hidden set_Item([object]$index,[object]$value){
        if( !(&$this.IndexRangeValidator.Object $this.getSubject() $index) ){
            &$this.OnSetIndexOutofRange.Object $this.getSubject() $index $null
        }
        else{
            &$this.SetItemBlock.Object $this.getSubject() $index $value
        }
    }


    hidden [object]PSGetItem_IntIndex([int]$index){
        if( !(&$this.IndexRangeValidator.Int $this.getSubject() $index) ){
            return &$this.OnGetIndexOutofRange.Int $this.getSubject() $index
        }
        else{
            return( (&$this.GetItemBlock.Int $this.getSubject() $index) )
        }
    }
    hidden PSSetItem_IntIndex([int]$index,[object]$value){
        if( !(&$this.IndexRangeValidator.Int $this.getSubject() $index) ){
            &$this.OnSetIndexOutofRange.Int $this.getSubject() $index $value
        }
        else{
            &$this.SetItemBlock.Int $this.getSubject() $index $value
        }
    }
    hidden [object]PSGetItem_ObjectIndex([object]$index){
        if( !(&$this.IndexRangeValidator.Object $this.getSubject() $index) ){
            return &$this.OnGetIndexOutofRange.Object $this.getSubject() $index
        }
        else{
            return( (&$this.GetItemBlock.Object $this.getSubject() $index) )
        }
    }
    hidden PSSetItem_ObjectIndex([object]$index,[object]$value){
        if( !(&$this.IndexRangeValidator.Object $this.getSubject() $index) ){
            &$this.OnSetIndexOutofRange.Object $this.getSubject() $index $null
        }
        else{
            &$this.SetItemBlock.Object $this.getSubject() $index $value
        }
    }
}