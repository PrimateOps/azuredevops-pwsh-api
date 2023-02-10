BeforeAll{ 
   # this BeforeAll{} block should be used as a generic test header for all tests. It provides access
   . ([IO.Path]::Combine($PSscriptRoot,"$env:BHProjectPath\.helpers\initialiseTest.ps1")) -Path $PSCommandPath
}

Describe 'Validating Module Manifest'{
    
    Context 'Validating manifest values'{

        it 'RootModule value matches root directory name'{
            $dataFile.RootModule | Should -Be ('.\{0}.psm1' -f $moduleName)
        }

        it 'ModuleVersion needs to be left as 0.1.0'{
            $dataFile.ModuleVersion | Should -Be '0.1.0'
        }

        it 'Description property must exist'{
            $dataFile.Description | Should -Not -BeNullOrEmpty -Because "We need to have a description in order to publish the module to our Gallery"
        } 

        it 'Description cannot be blank'{
            [String]::IsNullOrWhiteSpace($dataFile.Description) | Should -BeFalse -Because "Users need to have an idea of what this module does when they search our internal catalogue"
        } 

        it 'Module GUID is valid'{
            {[guid]::parse($dataFile.GUID)} | Should -Not -Throw
        }

        it 'Minimum PowerShell version supported should be 7.2.0'{
            $dataFile.PowerShellVersion | Should -Be '7.2.0'
        }

        it 'ScriptsToProcess should not be a blank list'{
            $dataFile.ScriptsToProcess.Count | Should -BeGreaterThan 0
        }

    }#context

    Context 'Testing PrivateData'{
        it 'Manfiest must have a PrivateData key'{
            $dataFile.containsKey('PrivateData') | Should -Be $true
        }

        it 'Must be a hashtable'{
            $dataFile.PrivateData | Should -BeofType Hashtable
        }

        it 'Must contain an azdoApiList entry'{
            $dataFile.PrivateData.containsKey('azdoApiList') | Should -Be $true
        }

        it 'azdoApiList value must be {moduleRoot}\azdoapi.json'{
            $dataFile.PrivateData.azdoApiList | Should -be '{moduleRoot}\azdoapi.json'
        }

        it 'Should not have a PreRelease entry (this should be commented out)'{
            $dataFile.PrivateData.PSData.containsKey('PreRelease') | Should -Be $false -Because 'this value is automatically inserted by the pipeline'
        }
    }#context
}