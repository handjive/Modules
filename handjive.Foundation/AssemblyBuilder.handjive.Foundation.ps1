param([switch]$Build,[switch]$Load)
import-module handjive.AssemblyBuilder -force

$cscode = @"
using System;
using SCG = System.Collections.Generic;
using SC = System.Collections;

namespace handjive
{
    namespace Foundation{
        //
        // Interfaces
        //
        public interface IValueable{
            object Value{ get; set; }
        }

        public interface IAdaptor{
            object Subject{ get; set; }
        }

        public interface IDependencyServer{
            object Events{ get; }
            object Dependents{ get; }
        }

        public interface IDependencyListenerEntry{
        }

        public interface IDependencyHolder{
            SCG.Dictionary<string,SCG.List<object>>Subscribers{ get; }
        }

        public interface IValueModel : IValueable,IDependencyServer{
        }

        //
        // Classes
        //
        public class SubclassResponsibilityException : Exception    
        {
            public SubclassResponsibilityException(){}
            public SubclassResponsibilityException(string message) : base(message){  }
            public SubclassResponsibilityException(string message, Exception inner) : base(message, inner){}
        }
        public class SubjectNotAssignedException : Exception    
        {
            public SubjectNotAssignedException(){}
            public SubjectNotAssignedException(string message) : base(message){  }
            public SubjectNotAssignedException(string message, Exception inner) : base(message, inner){}
        }
    }
}
"@

$DLLNAME = 'handjive.foundation.typelibrary.dll'
$REFS = @( 'System.dll','System.Collections.dll') 

if( $Build ){
    AssemblyBuilder -typeDefinition -Source $cscode -AssemblyName $DLLNAME -Refs @($REFS) -Destination $PSScriptRoot
}
if( $Load ){
    [reflection.Assembly]::LoadFrom("$PSScriptRoot\$DLLNAME")
}
