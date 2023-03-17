class ListAdaptor{
    [Collections.IList]$Subject

    [int]Size(){
        $this.Subject.Size()
    }
}

class ListSizeLimiter : ListAdaptor{

}

interface hoge{

}

$la = [AbstractListAdaptor]::new()
$la.Subject = [handjive.ObjectList]::new()