using module handjive.Collections

switch($args){
    1 {
        $iv1 = [Interval]::new(1,10,2)
        $iv2 = [Interval]::new(10,0,2)

        while($iv1.MoveNext()){
            write-host $iv1.Current

        }
        write-host '------------------------'
        while($iv2.MoveNext()){
            write-host $iv2.Current
        }

        $iv3 = [Interval]::new(-10,10,1)
        write-host '------------------------'
        while($iv3.MoveNext()){
            write-host $iv3.Current
        }

        $iv3 = [Interval]::new(10,-10,1)
        write-host '------------------------'
        while($iv3.MoveNext()){
            write-host $iv3.Current
        }

        write-host '----- foreach -----'
        $iv3.foreach{ write-host $_ }
    }

    2 {
        $iv1 = [Interval]::new(1,10,2)
        $iv1.foreach{
            write-host $_
        }
    }
}