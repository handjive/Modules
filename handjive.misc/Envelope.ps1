<#
# ScriptBlockからIEnumeratorを返すと、勝手に配列展開されちゃう。
# その防止用に。
#>
class Envelope{
    static [Envelope]Seal([object]$anObject){
        $newOne = [Envelope]::new($anObject)
        return $newOne
    }

    [object]$Subject

    Envelope([object]$object){
        $this.Subject = $object
    }

    [object]Unseal(){
        return $this.Subject
    }
}