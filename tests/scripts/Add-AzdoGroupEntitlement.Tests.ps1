BeforeAll{ 
    # this BeforeAll{} block should be used as a generic test header for all tests. It provides access
    . ([IO.Path]::Combine($PSscriptRoot,"$env:BHProjectPath\.helpers\initialiseTest.ps1")) -Path $PSCommandPath
}

Describe 'Test Initialisation'{
    BeforeAll{
        Write-Host $functionName
        Write-Host $sut
    }
    it ("Ensuring we are testing a valid function") {
        {Get-Command $functionName} | Should -Not -Throw
    }
}

Describe 'Parameter Validation'{
    BeforeDiscovery{
        # dataset for parameter validation
        # diversion from these values suggests that the core function has changed -
        # if valid, update the tests. If not - check the function!!

        # all functions need to have these parameters - validate they're there
        $shouldHaveParams = @(
            @{
                Name = 'azdoToken'
                Type = 'String'
            },
            @{
                Name = 'authType'
                Type = 'String'
            },
            @{
                Name = 'includeResponseHeaders'
                Type = 'SwitchParameter'
            }
        )
    }
    BeforeAll{
            $commandProps = Get-Command $functionName
    }

    Context 'Checking common module parameter <_.Name>' -ForEach $shouldHaveParams {
        it 'Should be included as function parameter' {
            $commandProps.Parameters.ContainsKey($_.Name) | Should -BeTrue
        }

        it 'Should be of type <_.Type>'{
            $commandProps.Parameters.($_.Name).ParameterType.Name | Should -Be $_.Type
        }
    }

    Context 'Parameter Validation'{
        it 'organisationName is optional'{
            $commandProps.Parameters.organisationName.Attributes.Mandatory | Should -BeFalse -Because "an organisation can be stored as an environment variable - the function will check for it"
        }
        
        it 'groupDisplayName should be mandatory'{
            $commandProps.Parameters.groupDisplayName.Attributes.Mandatory | Should -BeTrue
        }

        it 'groupId should be mandatory'{
            $commandProps.Parameters.groupId.Attributes.Mandatory | Should -BeTrue
        }

        it 'licenceMapping should be mandatory'{
            $commandProps.Parameters.licenceMapping.Attributes.Mandatory | Should -BeTrue
        }

        it 'azdoToken should be optional'{
            $commandProps.Parameters.azdoToken.Attributes.Mandatory | Should -BeFalse -Because 'we have an alternative mechanism for sourcing the PAT, which will throw an error if the PAT cannot be sourced.'
        }

        it 'authType should be optional'{
            $commandProps.Parameters.authType.Attributes.Mandatory | Should -BeFalse
        }

        it 'includeResponseHeaders should be optional'{
            $commandProps.Parameter.includeResponseHeaders.Attributes.Mandatory | Should -BeFalse
        }

    }
}