#region Header, Unit and Module testing
$ModuleName = "BigAsciiChars"

$ModuleMetaDataPath = join-path -path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "BigAsciiChars.psd1"

# Remove any module instance

Get-Module -Name $ModuleName | remove-module -ErrorAction SilentlyContinue

$ImportedModule = Import-Module -Name $ModuleMetaDataPath -Force -PassThru




Describe "$ModuleName Manifest Testing"{




    Context "$ModuleName Module manifest" {


        It "Should contains RootModule" {
            $ImportedModule.RootModule | Should not BeNullOrEmpty
        }

        It "Should contains Author" {
            $ImportedModule.Author | Should -Not -BeNullOrEmpty
        }

        It "Should contains Company Name" {
             $ImportedModule.CompanyName|Should -Not -BeNullOrEmpty
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
            $ImportedModule.tags.count | Should -BeGreaterThan 0
        }

    }
    InModuleScope $ModuleName {
        Context "$($ModuleName) Cmdlet testing"  {

            it "Write-BigText Should return the correct length for A" {
                (Write-BigText -Text "A").length   | Should -be 5
            }

            it "Write-BigText Should trhow with an empty string" {
                { Write-BigText -Text "" }   | Should -Throw 
            }

            it "Write-BigText Should trhow with a null value" {
                { Write-BigText -Text $null }    | Should -Throw 
            }

            it "GetLetterColumn Should return an array of Object" {
                (GetLetterColumn -Character "a").getType().Name  | Should -Be 'Object[]'
            }

            it "GetLetterColumn Should return an array with 6 member" {
                (GetLetterColumn -Character "a").count  | Should -Be 6
            }

            it "GetLetterColumn Should throw if using a string" {
                { GetLetterColumn -Character "aa" } | Should -Throw 
            }

            it "GetCharWidth Should throw if using a string" {
                { GetCharWidth -Char "aa" } | Should -Throw 
            }

            it "GetCharWidth Should return an int32 value" {
                (GetCharWidth -Char  "a").getType().Name  | Should -Be 'int32'
            }

            it "GetCharWidth Should return 5 for the letter a" {
                GetCharWidth -Char  "a" | Should -Be 5
            }

            it "GetCharWidth Should return 3 for the char -" {
                GetCharWidth -Char  "-" | Should -Be 3
            }

            it "GetCharWidth Should throw if using a string" {
                { GetCharWidth -Char "aa" } | Should -Throw 
            }
        }

    }


}
