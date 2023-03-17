import-module handjive.AssemblyBuilder -force

$cscode = @"
namespace handjive{
    namespace Everything{
        public interface ISearchResultElement{
            string QueryBase{ get; set; }
            int Number{ get; set; }
            string Name{ get; set; }
            string ContainerPath{ get;set; }
       }
       public interface IEverything{
            object[] Results{ get; }
            string QueryBase{ get; set; }
            string SearchString{ get; set; }
            object LastError{ get; }
            object SortOrder{ get; set; }
            object RequestFlags{ get; set; }
       }
    }
}
"@

AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName 'handjive.everythingif.dll' -Destination $PSScriptRoot
