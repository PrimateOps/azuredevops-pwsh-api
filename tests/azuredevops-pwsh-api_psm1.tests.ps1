BeforeAll{ 
    # this BeforeAll{} block should be used as a generic test header for all tests. It provides access
    . ([IO.Path]::Combine($PSscriptRoot,"$env:BHProjectPath\.helpers\initialiseTest.ps1")) -Path $PSCommandPath
}

Describe ('Validating {0}.psm1' -f $env:BHProjectName){
    Context 'Checking Read-AzdoApiList'{
        BeforeAll {
            # set up the mock
            Mock -ModuleName $moduleName Read-AzdoApiList {}
        }

        it 'Should invoke Read-AzdoApiList when invoked'{
            InModuleScope $moduleName {
                Read-AzdoApiList
                Should -Invoke Read-AzdoApiList -Times 1 -Exactly
            }
        }
    }
}