using module BigAsciiChars

InModuleScope -ModuleName BigAsciiChars -ScriptBlock {

    Describe '[CharInfo]-[Constructors]' {
        It "Should have default width when SkipWidthCalc param is true" {
            [int64]$value = 999
            # -- Act
            $info = [CharInfo]::New($value)

            $info.Width | Should -Be 0
        }
        
        It 'Should instantiate with passed value' {
            # -- Arrange
            [int64]$value = 999
            # -- Act
            $info = [CharInfo]::New($value)
            # -- Assert
            $info.Value | Should -Be $value
            $info.Width | Should -Be 0 # default value

        }# end of it block

        It 'Should instantiate with passed value and width' {
            # -- Arrange
            [int64]$value = 999
            [int]$Width = 5
            # -- Act
            $info = [CharInfo]::New($value, $Width)
            # -- Assert
            $info.Value | Should -Be $value
            $info.Width | Should -Be $Width

        }# end of it block
    }# end of Describe block
    
    Describe '[FontBase]-[Constructors]' {
        It 'Should throw if trying to instantiate a pseudo-abstract class' {
            # -- Arrange
            # -- Act
            # -- Assert
            { [FontBase]::New() } | Should -Throw "Abstract class cannot be instantiated"

        }# end of it block
    }# end of Describe block

    Describe 'FontBase-static_ColumnMaskCalc' {
        It "returns an int64 for valid inputs" {
            [FontBase]::ColumnMaskCalc(2,2) | Should -BeOfType ([Int64])
        }
        It "returns known good values for sample inputs" {
            [FontBase]::ColumnMaskCalc(2,2) | Should -Be 10
            [FontBase]::ColumnMaskCalc(5,5) | Should -Be 17318416
        }
    }
    Describe '[DefaultFont]-[Constructors]' {
        It "Should instantiate in under 200ms" {
            (Measure-Command {[DefaultFont]::new()}).TotalMilliseconds | Should -BeLessOrEqual 200
        }
        
        It "Sets up default height and width" {
            $Font = [DefaultFont]::New()
            $Font.Height | Should -Be 5
            $Font.Width | Should -Be 5
        }

        It "Uses the value in the position for the space (char 32) as the literal width and zeroes the value" {
            $Font = [DefaultFont]::New()
            $Font.Codes[32].Value | Should -Be 0
            $Font.Codes[32].Width | Should -BeGreaterThan 0
            $Font.Codes[32].Width | Should -BeLessOrEqual 8
        }
    }# end of Describe block
    
    Context "DefaultFont" {
        BeforeAll {
            $Font = [DefaultFont]::new()
        }
        Describe "[DefaultFont]-[GetCharInfo]" {
            It "Returns a charInfo object for a known good char" {
                $Info = $Font.GetCharInfo("a")
                $Info | Should -BeOfType ([CharInfo])
            }
            It "Returns known good data for a known input char" {
                $Info = $Font.GetCharInfo("a")
                $Info.Value | Should -BeOfType ([Int64])
                $Info.Value | Should -Be 199278127
                $Info.Width | Should -BeOfType ([int])
                $Info.Width | Should -Be 5
            }
            
        }

    }

}#End InModuleScope


