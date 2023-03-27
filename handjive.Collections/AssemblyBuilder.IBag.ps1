import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Collections{
        public interface IBag{
            System.Collections.IEnumerator Values{ get; }
            int Count{ get; }
            object this[int index]{ get; set; }
            object this[object key]{ get; set; }
            System.Collections.IEnumerator ValuesAndOccurrences{ get; }
        }

        public interface IKeyedBag{
            object[] Indices{ get; }
            object[] Values{ get; }
            int Count{ get; }
            object[] IndicesAndValues{ get; }
            object[] IndicesAndValuesAndOccurrences{ get; }
        }

        public interface IGetKeyBlock{
            object GetKeyBlock{ get; set; }
        }
    }
}
"@
<#            protected object GetKeyBlock{
                get{ return (this._GetKeyBlock); }
                set{ this._GetKeyBlock = value; }
            }
#>
AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName 'handjive.collectionsif.dll' -Destination $PSScriptRoot
