#region Header, Unit and Module testing
$ModuleName = "BigAsciiChars"

$ModuleMetaDataPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "BigAsciiChars.psd1"

# Remove any module instance

Get-Module -Name $ModuleName | Remove-Module -ErrorAction SilentlyContinue

$ImportedModule = Import-Module -Name $ModuleMetaDataPath -Force -PassThru




Describe "$ModuleName Manifest Testing" {


    Context "$ModuleName Module manifest" {


        It "Should contains RootModule" {
            $ImportedModule.RootModule | Should -Not -BeNullOrEmpty
        }

        It "Should contains Author" {
            $ImportedModule.Author | Should -Not -BeNullOrEmpty
        }

        It "Should contains Description" {
            $ImportedModule.Description | Should -Not -BeNullOrEmpty
        }

        It "Should contains Copyright information" {
            $ImportedModule.Copyright | Should -Not -BeNullOrEmpty
        }

        It "Should have a project URI" {
            $ImportedModule.ProjectUri | Should -Not -BeNullOrEmpty
        }

        It "Should have a License URI" {
            $ImportedModule.LicenseUri | Should -Not -BeNullOrEmpty
        }

        It "Should have at least one tag" {
            $ImportedModule.Tags.Count | Should -BeGreaterThan 0
        }

    }

    InModuleScope $ModuleName {
        Context "$($ModuleName) Cmdlet testing" {

            Describe "Write-BigText" {
                
                It "Write-BigText Should return the correct length for A" {
                    (Write-BigText -Text "A").length | Should -Be 5
                }
    
                It "Write-BigText Should throw with an empty string" {
                    { Write-BigText -Text "" } | Should -Throw 
                }
    
                It "Write-BigText Should throw with a null value" {
                    { Write-BigText -Text $null } | Should -Throw 
                }
            }

            Describe "GetLetterColumn" {
                
                It "GetLetterColumn Should return a byte array" {
                    (GetLetterColumn -Character "a") | Should -BeOfType ([byte[]])
                }
    
                It "GetLetterColumn Should return an array with 6 items" {
                    (GetLetterColumn -Character "a").Count | Should -Be 6
                }
    
                It "GetLetterColumn Should throw if using a string" {
                    { GetLetterColumn -Character "aa" } | Should -Throw 
                }
            }

            Describe "GetCharWidth" {
                
                It "GetCharWidth Should throw if using a string" {
                    { GetCharWidth -Char "aa" } | Should -Throw 
                }
    
                It "GetCharWidth Should return an int32 value" {
                    (GetCharWidth -Char "a") | Should -BeOfType ([int])
                }
    
                It "GetCharWidth Should return 5 for the letter a" {
                    GetCharWidth -Char "a" | Should -Be 5
                }
    
                It "GetCharWidth Should return 3 for the char -" {
                    GetCharWidth -Char "-" | Should -Be 3
                }

                It "GetCharWidth Should return 1 for the char i" {
                    GetCharWidth -Char "i" | Should -Be 1
                }
            }
        }
    }


}
