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
}

# Public Functions
Describe "Write-BigText" {
    
    It "Should return the correct length for A" {
        (Write-BigText -Text "A").length | Should -Be 5
    }

    It "Should throw with an empty string" {
        { Write-BigText -Text "" } | Should -Throw 
    }

    It "Should throw with a null value" {
        { Write-BigText -Text $null } | Should -Throw 
    }
    It "Contains only the requested input/output chars and newlines" {
        Write-BigText -Text "Pester Testing" -OutChar "#" -EmptyChar "_" | Out-String | Should -Not -Match "[^_#\r\n]"
    }
}

Describe "Get-BADefaultFont" {
    It "Returns a DefaultFont object" {
        (Get-BADefaultFont).GetType().Name | Should -Be "DefaultFont"
    }
}
Describe "Get-BAAvailableFont" {
    It "Returns a list containing DefaultFont" {
        (Get-BAAvailableFont) | Should -Contain "DefaultFont"
    }
}

Describe "New-BAFont" {
    It "Creates a font object when passed the name of a font" {
        (New-BAFont -Name "DefaultFont").GetType().Name | Should -Be "DefaultFont"
    }
}

Describe "Write-ScrollText" {
    It "Writes to screen with text input and exits" {
        Write-ScrollText -Text "P" -Width 2 -FrameDelay 0 | Should -BeNullOrEmpty
    }
    It "Writes to screen with byte input and exits" {
        Write-ScrollText -Bytes @(255) -Width 2 -FrameDelay 0 | Should -BeNullOrEmpty
    }
}


# Private Functions
InModuleScope $ModuleName {
    Describe "GetLetterColumn" {
        
        Context "Using default Font" {
            BeforeAll {
                $Font = [DefaultFont]::new()
            }
            It "GetLetterColumn Should return a byte array" {
                (GetLetterColumn -Character "a" -Font $Font).GetType().IsArray | Should -BeTrue
            }

            It "GetLetterColumn Should return an array with 6 items with the default font" {
                (GetLetterColumn -Character "a" -Font $Font).Count | Should -Be 6
            }

            It "GetLetterColumn Should throw if using a string" {
                { GetLetterColumn -Character "aa" -Font $Font } | Should -Throw 
            }
        }
    }

    Describe "GetMsb" {
        It "Returns the bit value of the MSB without the -Position switch parameter" {
            GetMSB -d 31 | Should -Be 16
            GetMSB -d 32 | Should -Be 32
            GetMSB -d 65 | Should -Be 64
        }

        It "Returns the position of the MSB with the -Position switch parameter" {
            GetMSB -d 31 -Position | Should -Be 4
            GetMSB -d 32 -Position | Should -Be 5
            GetMSB -d 65 -Position | Should -Be 6
        }

    }

    Describe "GetLetterRow" {
        Context "Using default Font" {
            BeforeAll {
                $Font = [DefaultFont]::new()
            }
        
            It "Returns a string for a single row" {
                (GetLetterRow -Char "a" -Row 0 -Font $Font) | Should -BeOfType ([string])
            }
            It "Returns an array for multiple rows" {
                (GetLetterRow -Char "a" -Row (0..1) -Font $Font).GetType().IsArray | Should -BeTrue
            }
            It "Should throw if passed a string to the char param" {
                { (GetLetterRow -Char "aa" -Font $Font) } | Should -Throw
            }
            It "Returns a valid byte with the -AsByte switch parameter" {
                (GetLetterRow -Char "a" -Row 0 -Font $Font -AsByte) | Should -BeOfType ([byte])
            }
            It "Returns a known good value for a given input char" {
                (GetLetterRow -Char "A" -Row 0 -Font $Font -AsByte) | Should -Be 14
            }
        }
    }

    Describe "GetCharWidth" {
        Context "Using default Font" {
            BeforeAll {
                $Font = [DefaultFont]::new()
                $LowerCaseA = $Font.GetCharInfo("a").Value
                $Dash = $Font.GetCharInfo("-").Value
                $LowerCaseI = $Font.GetCharInfo("i").Value
            }

            It "GetCharWidth Should return an int32 value" {
                (GetCharWidth -Code $LowerCaseA -FontHeight $Font.Height -FontWidth $Font.Width) | Should -BeOfType ([int])
            }

            It "GetCharWidth Should return 5 for the letter a" {
                (GetCharWidth -Code $LowerCaseA -FontHeight $Font.Height -FontWidth $Font.Width) | Should -Be 5
            }

            It "GetCharWidth Should return 3 for the char -" {
                (GetCharWidth -Code $Dash -FontHeight $Font.Height -FontWidth $Font.Width) | Should -Be 3
            }

            It "GetCharWidth Should return 1 for the char i" {
                (GetCharWidth -Code $LowerCaseI -FontHeight $Font.Height -FontWidth $Font.Width) | Should -Be 1
            }
        }
    }
    
}

