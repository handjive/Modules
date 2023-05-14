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
    <#
    # SubstanceからEnumeration,Index[in],Index[object]の処理主体を取り出すためのデフォルトブロック
    # 処理を指定しない限り、Subject=Substance
    #>
    # GetCountBlock,(Get|Set)IndexBlock,On(Get|Set)IndexOutofRange,IndexRangeValidatorに渡される処理対象を取り出す
    [HashTable]$GetSubjectBlock = @{
        Enumerable = { 
            param(
                 $adaptor       # IndexAdaptor本体
                ,$substance     # Adaptorの対象となるオブジェクト
                ,$workingset    # 作業用領域
                ,$result        # 処理対象となるオブジェクトの格納先(ScriptBlockがIEnumeratorを返すと自動展開されてしまうためこれを経由)
            )      
            $adaptor.subjects.Enumerable = $substance # デフォルトではAdaptorの対象オブジェクトがそのまま返る
        };
        IntIndex = { 
            param(
                 $adaptor       # IndexAdaptor本体
                ,$substance     # Adaptorの対象となるオブジェクト
                ,$workingset    # 作業用領域
                ,$result        # 処理対象となるオブジェクトの格納先(ScriptBlockがIEnumeratorを返すと自動展開されてしまうためこれを経由)
            )      
            $adaptor.Subjects.IntIndex = $substance # デフォルトではAdaptorの対象オブジェクトがそのまま返る
        };
        ObjectIndex = { 
            param(
                 $adaptor       # IndexAdaptor本体
                ,$substance     # Adaptorの対象となるオブジェクト
                ,$workingset    # 作業用領域
                ,$result        # 処理対象となるオブジェクトの格納先(ScriptBlockがIEnumeratorを返すと自動展開されてしまうためこれを経由)
            )      
            $adaptor.Subjects.ObjectIndex = $substance # デフォルトではAdaptorの対象オブジェクトがそのまま返る
        };
    }

    <#
    # Enumeratorを取得するブロック
    # ここで渡されるSubject(GetSubjectBlockForEnumの戻り値)がGeneric.IGetEnumerator[object]/IGetEnumerator
    # に応えられ、それが目的のEnumeratorる場合はこのデフォルト処理で充分。
    # SubjectがGetEnumeratorに答えられない場合は、このブロックの上書きが必要。
    # (デフォルトでは、空Enumeratorが返される)
    #>
    [ScriptBlock]$GetEnumeratorBlock = {
        param(
             $adaptor       # IndexAdaptor本体
            ,$subject       # Enumeratorを取得するために使用するオブジェクト(GetSubjectBlock.Enumerableの戻り値)
            ,$workingset    # 作業用領域
            ,$result        # 処理対象となるオブジェクトの格納先(ScriptBlockがIEnumeratorを返すと自動展開されてしまうためこれを経由)
        )

        $methods = $subject.gettype().GetMethods() | where-object { $_.Name -eq 'GetEnumerator' }
        if( $null -eq $methods ){
            $result.Value = [PluggableEnumerator]::Empty()  # 空Enumerator
        }
        else{
            $enumerator = $subject.GetEnumerator()
            if( $enumerator -is [Collections.Generic.IEnumerator[object]] ){
                $enumerator.Reset()
                $result.Value = $enumerator # Subjectが返すGeneric.IEnumerator[object]そのまま
            }
            else{
                $enumerator.Reset()
                $result.Value = [PluggableEnumerator]::InstantWrapOn($enumerator)   # IEnumeratorをWrapし、Generic.IEnumerator[object]として返す
            }
        }
    }

    <#
    # プロパティ"Count"の実行ブロック
    # Subject(GetSubjectBlock.IntIndex,GetSubjectBlock.ObjectIndex)がCountに応えることが前提
    #>
    [Hashtable]$GetCountBlock = @{
        IntIndex = {
            param(
                 $adaptor           # IndexAdaptor本体
                ,$subject           # GetSubjectBlock.IntIndexの戻り値
                ,$workingset        # 作業用領域
            )
            $subject.Count          
        };
        ObjectIndex = {
            param(
                 $adaptor           # IndexAdaptor本体
                ,$subject           # GetSubjectBlock.ObjectIndex
                ,$workingset        # 作業用領域
            )
            $subject.Count          # Countとして返される値
        };
    }

    <#
    # "object this[](T index)"の実行ブロック(Get)
    #>
    [HashTable]$GetItemBlock = @{
        IntIndex={                  # "object this[](int index)"の実行ブロック
            param(
                 $adaptor           # IndexAdaptor本体
                ,$subject           # []の実行に使用するオブジェクト(GetSubjectBlock.IntIndexの戻り値)
                ,$workingset        # 作業用領域
                ,[int]$index        # インデックス
            )         
            $subject[$index]        # []の戻り値
        };
        ObjectIndex={               # "object this[](object index)"の実行ブロック
            param(
                 $adaptor           # IndexAdaptor本体
                ,$subject           # []の実行に使用するオブジェクト(GetSubjectBlockの戻り値)
                ,$workingset        # 作業用領域
                ,[object]$index     # インデックス
            ) 
            $subject[$index]        # []の戻り値
        }; 
    }

    <#
    # "object this[](T index)"の実行ブロック(Set)
    #>
    [HashTable]$SetItemBlock = @{
        IntIndex={                  # "object this[](int index)"の実行ブロック
            param(
                 $adaptor           # IndexAdaptor本体
                ,$subject           # []の実行に使用するオブジェクト(GetSubjectBlock.IntIndexの戻り値)
                ,$workingset        # 作業用領域
                ,[int]$index        # インデックス
                ,$value             # セットする値
            )
            $subject[$index]= $value 
        }; 
        ObjectIndex={                    # "object this[](object index)"の実行ブロック
            param(
                 $adaptor           # IndexAdaptor本体
                ,$subject           # []の実行に使用するオブジェクト(GetSubjectBlock.ObjectIndexの戻り値)
                ,$workingset        # 作業用領域
                ,[object]$index     # インデックス
                ,$value             # セットする値
            )        
            $subject[$index]= $value 
        }; 
    }
    
    <#
    # インデックスの範囲検証
    # ブロックの評価結果が $true=範囲内、$false=範囲外
    #>
    [Hashtable]$IndexRangeValidator = @{
        IntIndex={ 
            param(
                 $adaptor      # IndexAdaptor
                ,$subject      # GetSubjectBlock.IntIndexの戻り値
                ,$workingset   # 作業用領域
                ,$index        # 指定されたインデックス
            )
            return ($index -lt $adaptor.Count('IntIndex'))
        }; 
        ObjectIndex={
            param(
                 $adaptor      # IndexAdaptor
                ,$substance    # GetSubjectBlock.ObjectIndexの戻り値
                ,$workingset   # 作業用領域
                ,$index        # 指定されたインデックス
            ) 
            $true   # ObjectIndexの場合、妥当なデフォルト処理が無いので常に$true
        }; 
    }

    <#
    # Getインデックスが範囲外だった時の処理
    # IndexRangeValidatorが$falseを返したときに実行される。
    # このブロックの戻り値がitem[index]の戻り値となる。
    # デフォルトとしてExceptionはthrowせず$nullを返す。
    #>
    [Hashtable]$OnGetIndexOutofRange = @{
        IntIndex={       # 整数インデックス用
            param(
                 $adaptor       # IndexAdaptor
                ,$subject       # GetSubjectBlockの戻り値
                ,$workingset    # 作業用領域
                ,$index         # 指定されたインデックス
            ) 
            $null               
        };
        ObjectIndex={    # オブジェクトインデックス用
            param(
                 $adaptor       # IndexAdaptor
                ,$substance     # GetSubjectBlockの戻り値
                ,$workingset    # 作業用領域
                ,$index         # 指定されたインデックス
            ) 
            $null               
        };
    }    

    <#
    # Setインデックスが範囲外だった時の処理
    # IndexRangeValidatorが$falseを返したときに実行される
    # デフォルトでは"何もしない"
    #>
    [Hashtable]$OnSetIndexOutofRange = @{
        IntIndex={       # 整数インデックス用
            param(
                 $adaptor       # IndexAdaptor
                ,$substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
                ,$workingset    # 作業用領域
                ,$value         # セットしようとしたオブジェクト
            ) 
        }; 
        ObjectIndex={    # オブジェクトインデックス用
            param(
                 $adaptor       # IndexAdaptor
                ,$substance     # GetSubjectBlockの戻り値
                ,$index         # 指定されたインデックス
                ,$workingset    # 作業用領域
                ,$value         # セットしようとしたオブジェクト
            ) 
        };
    }
}

<#

Indexアクセスを実装していないオブジェクトにIndexアクセスを偽装するアダプタ

[プロパティ(デフォルトはDefaultProvider_IndexAdaptorを参照)]

    [object]$substance                          Generic.IEnumerable[object]になれる何か(或いはその処理主体)

    [HashTable]$GetSubjectBlock                 key=Enumerable,IntIndex,ObjectIndex: Substanceからそれぞれの処理用オブジェクトを取り出すブロック。
    [HashTable]$GetCountBlock                   key=IntIndex,ObjectIndex: Countの取り出し処理
    [HashTable]$GetItemBlock                    key=IntIndex,ObjectIndex: item[index]に答える処理
    [HashTable]$SetItemBlock                    key=IntIndex,ObjectIndex: item[index]=valueの処理
    [HashTable]$OnGetIndexOutofRange            key=IntIndex,ObjectIndex: GetのIndexが範囲外だった時の処理
    [HashTable]$OnSetIndexOutofRange            key=IntIndex,ObjectIndex: SetのIndexが範囲外だった時の処理
    [HashTable]$IndexRangeValidator             key=IntIndex,ObjectIndex: Indexの範囲チェック処理

    [ScriptBlock]$GetEnumeratorBlock            SubjectからEnumeratorを取り出す処理
    [HashTable]$WorkingSet                      各Blockに共通で渡される作業領域

[メソッド]
    
    Subjectの再作成要求
    
        [void]InvalidateSubject([string]$subjectType)   # 指定したアクセスのSubject。$subjectType='Enumerable'|'IntIndex'|'ObjectIndex'
        [void]InvalidateAllSubjects()                   # 全てのSubject
    }

    サービス・メソッド

        # Generic.IEnumerable[object]の指定位置要素を取り出す
        [object]ElementAtIndexFromEnumerable([int]$index,[Collections.Generic.IEnumerable[object]]$enumerable)
        
        ex.
        $ixa.GetSubjectBlock.IntIndex = { param($adaptor,$subject,$workingset) ごにょごにょ… (Generic.IEnumerable[object]]Something }
        $ixa.GetItemBlock.IntIndex = { param($adaptor,$subject,$workingset,$index) $adaptor.ElementAtIndexFromEnumerable($subject) }

        # Generic.IEnumerable[object]の要素数を返す
        [int]CountFromEnumerable([Collections.Generic.IEnumerable[object]]$enumerable)  

        # GetCountBlockの実行結果を返す
        [int]Count([string]$subjectType)    # $subjectType='IntIndex'|'ObjectIndex'

#>


class IndexAdaptor : handjive.Collections.IndexableEnumerableBase{
    [object]$substance                          # Generic.IEnumerable[object]になれる何か

    [ScriptBlock]$GetEnumeratorBlock            # SubjectからEnumeratorを取り出す処理

    [HashTable]$GetSubjectBlock                 # SubstanceからEnumerator取り出し/index[int]/index[object]用Subjectを取り出すブロック。
    [HashTable]$GetCountBlock                   # Countの取り出し処理
    [HashTable]$GetItemBlock                    # item[index]に答える処理
    [HashTable]$SetItemBlock                    # item[index]=valueの処理
    [HashTable]$OnGetIndexOutofRange            # GetのIndexが範囲外だった時の処理
    [HashTable]$OnSetIndexOutofRange            # SetのIndexが範囲外だった時の処理
    [HashTable]$IndexRangeValidator             # Indexの範囲チェック処理

    [HashTable]$WorkingSet                      # 作業領域
    
    hidden [HashTable]$subjects = @{ Enumerable=$null; IntIndex=$null; ObjectIndex=$null; }
    hidden [bool]$StillBuild = $true

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
        $this.StillBuild = $false
    }

    hidden [object]extractResult([Hashtable]$result){
        $key = $result.keys[0]
        return ($result[$key])[-1]
    }

    hidden [object]getSubject([string]$subjectType){
        if( $null -eq $this.Subjects[$subjectType] ){
            $subs = $this.substance
            $this.subjects[$subjectType] = &($this.GetSubjectBlock[$subjectType]) $this $subs $this.WorkingSet
        }
        $result = $this.subjects[$subjectType]
           
        return ($result)
    }


    <#
    # Service methods
    #>
    [void]InvalidateSubject([string]$subjectType){
        $this.subjects[$subjectType] = $null
    }

    [void]InvalidateAllSubjects(){
        $this.subjects.keys.foreach{
            $this.subjects[$_] = $null
        }
    }

    <#
    # Generic.IEnumerable[object]から指定位置のオブジェクトを取り出す
    # Subjects.IntIndexがGeneric.IEnumerable[object]の場合、GetItemBlock.IntIndexで利用できる
    #
    # GetSubjectBlock.IntIndex = { param($adaptor,$subject,$workingset) ごにょごにょ… (Generic.IEnumerable[object]]Something }
    # GetItemBlock.IntIndex = { param($adaptor,$subject,$workingset,$index) $adaptor.ElementAtIndexFromEnumerable($subject) }
    #>
    [object]ElementAtIndexFromEnumerable([int]$index,[Collections.Generic.IEnumerable[object]]$enumerable){
        $result = [Linq.Enumerable]::ElementAt[object]($enumerable,[int]$index)
        return $result
    }

    [int]CountFromEnumerable([Collections.Generic.IEnumerable[object]]$enumerable){
        $result = [Linq.Enumerable]::Count[object]($enumerable)
        return $result
    }

    [int]Count([string]$subjectType){
        $result = &($this.GetCountBlock[$subjectType]) $this $this.getSubject($subjectType) $this.WorkingSet
        return $result
    }

    <#
    # IndexableEnumerableBase subclass responsibilities
    #>
    hidden [Collections.Generic.IEnumerator[object]]PSGetEnumerator(){
        if( $null -eq $this.GetEnumeratorBlock ){
            return [PluggableEnumerator]::Empty()
        }
        if( $this.StillBuild ){
            return [PluggableEnumerator]::Empty()
        }

        $result = @{}
        &($this.GetEnumeratorBlock) $this $this.getSubject('Enumerable') $this.WorkingSet $result | out-null
        return $this.extractResult($result)
    }

    hidden [object]PSGetItem_IntIndex([int]$index){
        $aSubject = $this.getSubject('IntIndex') 
        $aWorkingset = $this.WorkingSet

        if( ! (&$this.IndexRangeValidator.IntIndex $this $aSubject $aWorkingset $index) ){
            return &$this.OnGetIndexOutofRange.IntIndex $this $aSubject $aWorkingset $index $null
        }
        else{
            return( (&$this.GetItemBlock.IntIndex $this $aSubject $aWorkingSet $index) )
        }
    }
    hidden PSSetItem_IntIndex([int]$index,[object]$value){
        $aSubject = $this.getSubject('IntIndex') 
        $aWorkingset = $this.WorkingSet

        if( !(&$this.IndexRangeValidator.IntIndex $this $aSubject $aWorkingset $index) ){
            &$this.OnSetIndexOutofRange.IntIndex  $this $aSubject $aWorkingset $index $value
        }
        else{
            &$this.SetItemBlock.IntIndex  $this $aSubject $aWorkingset $index $value
        }
    }
    hidden [object]PSGetItem_ObjectIndex([object]$index){
        $aSubject = $this.getSubject('ObjectIndex') 
        $aWorkingset = $this.WorkingSet

        if( !(&$this.IndexRangeValidator.ObjectIndex $this $aSubject $aWorkingset $index) ){
            return &$this.OnGetIndexOutofRange.ObjectIndex $this $aSubject $aWorkingset $index
        }
        else{
            return( (&$this.GetItemBlock.ObjectIndex $this $aSubject $aWorkingset $index) )
        }
    }
    hidden PSSetItem_ObjectIndex([object]$index,[object]$value){
        $aSubject = $this.getSubject('ObjectIndex') 
        $aWorkingset = $this.WorkingSet

        if( !(&$this.IndexRangeValidator.ObjectIndex $this $aSubject $aWorkingset $index) ){
            &$this.OnSetIndexOutofRange.ObjectIndex $this $aSubject $aWorkingset $index $null
        }
        else{
            &$this.SetItemBlock.ObjectIndex $this $aSubject $aWorkingset $index $value
        }
    }
}