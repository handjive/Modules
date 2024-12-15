using namespace handjvie.Foundation

class IndexRegurator{
    static [int]ActualIndexFrom([int]$min,[int]$max,[int]$index){
        if( $index -lt 0 ){
            $actualIndex = $max + $index
            if( $actualIndex -lt 0 ){
                return $max
            }
            else{
                return $actualIndex
            }
        }
        else{
            return $index
        }
    }
}
