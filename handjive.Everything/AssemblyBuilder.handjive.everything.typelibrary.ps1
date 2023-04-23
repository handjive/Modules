import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Everything{
        public interface ISearchResultElement{
            string QueryBase{ get; set; }
            int Number{ get; set; }
            string Name{ get; set; }
            string ContainerPath{ get;set; }
            string FullName{ get; }
       }
       public interface IEverything{
            System.Collections.Generic.IEnumerable<object> ResultsEnumerable{ get; }
            object[] Results{ get; }
            string QueryBase{ get; set; }
            string SearchString{ get; set; }
            object LastError{ get; }
            object SortOrder{ get; set; }
            object RequestFlags{ get; set; }
            int NumberOfResults{ get; }
        }
    }
}
"@

AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName 'handjive.everything.typelibrary.dll' -Destination $PSScriptRoot
