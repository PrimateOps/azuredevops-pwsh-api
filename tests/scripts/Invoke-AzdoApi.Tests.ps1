BeforeAll{ 
    # this BeforeAll{} block should be used as a generic test header for all tests. It provides access
    . ([IO.Path]::Combine($PSscriptRoot,"$env:BHProjectPath\.helpers\initialiseTest.ps1")) -Path $PSCommandPath
}

Describe 'Test Initialisation'{
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
        it 'uri is mandatory'{
            $commandProps.Parameters.uri.Attributes.Mandatory | Should -BeTrue
        }
        
        it 'method should be mandatory'{
            $commandProps.Parameters.method.Attributes.Mandatory | Should -BeTrue
        }

        it 'requestBody should be optional'{
            $commandProps.Parameters.requestBody.Attributes.Mandatory | Should -BeFalse
        }

        it 'azdoToken should be mandatory'{
            $commandProps.Parameters.azdoToken.Attributes.Mandatory | Should -BeTrue -Because 'this is the core calling API function and it must always get the token passed in'
        }

        it 'authType should be optional'{
            $commandProps.Parameters.authType.Attributes.Mandatory | Should -BeFalse
        }

        it 'includeResponseHeaders should be optional'{
            $commandProps.Parameter.includeResponseHeaders.Attributes.Mandatory | Should -BeFalse
        }

    }
}

Describe 'Testing function logic handling'{
    BeforeAll {}

    Context "Testing Invoke-RestMethod with whitespaces"{
        BeforeAll{
            # set up mocks
            $invokeParameters = @{
                uri       = "https://dev.azure.com/someorg/anapicall/_apis/has a space"
                method    = 'GET'
                azdoToken = 'aldsfkjwldsjfnotatokenadflkjasdf'
    
            }

            Mock Invoke-RestMethod {
                return [PSCustomObject]@{Result='Success'}
            } -ParameterFilter {
                                            # imitating function behaviour to validate call
                                            $Uri -eq ($invokeParameters.uri.Replace(' ', '%20'))
                                            $ContentType -eq "application/json"
                                            $Method -eq $invokeParameters.method
                                            $Authentication -eq 'Basic'
                                            
                                        }
            Mock Invoke-WebRequest {}

            
        }
        
        it 'Will call Invoke-RestMethod once:
        Authentication : [Basic]
        Method         : [GET]
        Will replace whitespace in the uri string with a "%20" character AND
        Will NOT call Invoke-WebRequest in this flow'{
            $result = Invoke-AzdoApi @invokeParameters
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
            Should -Invoke Invoke-WebRequest -Times 0
            $result.result | Should -Be 'Success'
        }
    }

    Context "Testing Invoke-RestMethod with Bearer Auth"{
        
        BeforeAll{
            # set up mocks
            $invokeParameters = @{
                uri       = "https://dev.azure.com/someorg/anapicall/_apis/someversion"
                method    = 'GET'
                authType  = 'Bearer'
                azdoToken = 'aldsfkjwldsjfnotatokenadflkjasdf'
    
            }

            Mock Invoke-RestMethod {
                return [PSCustomObject]@{Result='Success'}
            } -ParameterFilter {
                # immitating function behaviour to validate call
                $Uri -eq $invokeParameters.uri
                $Authentication -eq $invokeParameters.authType
                $method -eq $invokeParameters.method
            }
            Mock Invoke-WebRequest {}
            
        }
        
        it 'Will call Invoke-RestMethod once:
        Authentication : [Bearer]
        Method         : [Get]
        Will NOT call Invoke-WebRequest in this flow'{
            $result = Invoke-AzdoApi @invokeParameters
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
            Should -Invoke Invoke-WebRequest -Times 0
            $result.result | Should -Be 'Success'
        }

    }

    Context "Testing Invoke-RestMethod with Body payload"{
        
        BeforeAll{
            # set up mocks
            $payload = @{
                Request = 'post something!!'
            }
            $invokeParameters = @{
                uri         = "https://dev.azure.com/someorg/anapicall/_apis/someversion"
                method      = 'POST'
                authType    = 'Basic'
                azdoToken   = 'aldsfkjwldsjfnotatokenadflkjasdf'
                requestBody = ($payload | Convertto-Json -Depth 20)
            }
            

            Mock Invoke-RestMethod {
                return [PSCustomObject]@{Result='Success'}
            } -ParameterFilter {
                # immitating function behaviour to validate call
                $Uri -eq $invokeParameters.uri
                $Authentication -eq $invokeParameters.authType
                $method -eq $invokeParameters.method
                $body -eq $invokeParameters.requestBody
            }
            Mock Invoke-WebRequest {}
            
        }
        
        it 'Will call Invoke-RestMethod once:
        Authentication : [Basic]
        Method         : [POST]
        Body           : [included]
        Will NOT call Invoke-WebRequest in this flow'{
            $result = Invoke-AzdoApi @invokeParameters
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
            Should -Invoke Invoke-WebRequest -Times 0
            $result.result | Should -Be 'Success'
        }
    }

    Context "Testing Invoke-RestMethod Error comes back"{
        
        BeforeAll{
            # set up mocks
            $invokeParameters = @{
                uri         = "https://dev.azure.com/someorg/anapicall/_apis/someversion"
                method      = 'GET'
                authType    = 'Basic'
                azdoToken   = 'aldsfkjwldsjfnotatokenadflkjasdf'
            }
            

            Mock Invoke-RestMethod {
                throw 'I have an error!'
            } -ParameterFilter {
                # immitating function behaviour to validate call
                $Uri -eq $invokeParameters.uri
                $Authentication -eq $invokeParameters.authType
                $method -eq $invokeParameters.method
            }
            Mock Invoke-WebRequest {}
            
        }
        
        it 'Will call Invoke-RestMethod once:
        Invoke-RestMethod will THROW EXCEPTION.
        Will NOT call Invoke-WebRequest in this flow'{
            {Invoke-AzdoApi @invokeParameters} | Should -Throw
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly
            Should -Invoke Invoke-WebRequest -Times 0
        }
    }
            
}

<#

# Commenting this out for potential future retry. This was an attempt to remove the duplication of code by crafting
# a single script block (in the beforeall) and leveraging the foreach function to declare the test parameters.
# Problem is that the tests array in BeforeDiscovery isn't available to the Invoke-RestAPI at runtime (BeforeAll bock).
# Same happens when wrapped around a BeforeAll block (instread of BeforeDiscovery)

Describe 'Testing Invoke-RestMethod flow' {
    BeforeDiscovery{
        # set test cases
        $tests = @(
            @{
                TestCase = 'Testing with a whitespace in the uri'
                Parameters = @{ 
                    uri       = 'https://dev.azure.com/has a space'
                    method    = 'GET'
                    authType  = 'Basic'
                    azdoToken = 'aldsfkjwldsjfnotatokenadflkjasdf'   
                }
            },
            @{
                TestCase = 'Testing with Bearer auth'
                Parameters = @{
                    uri       = "https://dev.azure.com/someorg/anapicall/_apis/someversion"
                    method    = 'GET'
                    authType  = 'Bearer'
                    azdoToken = 'aldsfkjwldsjfnotatokenadflkjasdf'
                }
            }
        )
    }

    Context "<TestCase>" -ForEach $tests{
        BeforeAll {
            Mock Invoke-RestMethod {
                return [PSCustomObject]@{Result='Success'}
            } -ParameterFilter {
                # immitating function behaviour to validate call
                $Uri -eq ($_.Parameters.uri.Replace(' ', '%20'))
                $Authentication -eq $_.Parameters.authType
                $method -eq $_.Parameters.method
            }

            Mock Invoke-WebRequest {}
            $invokeParams = $_.Parameters
            $result = Invoke-AzdoApi @invokeParams
        }

        it 'Will call Invoke-RestMethod once'{
            Should -Invoke Invoke-RestMethod -time 1
        }

        it 'Will not call Invoke-WebRequest cmdlet in this specific logic flow'{
            Should -Invoke Invoke-WebRequest -Times 0
        }

        it 'Will return the expected result'{
            $result.result | Should -Be 'Success'
        }

    }
}

#>