using module C:\Users\davidjohnson\Documents\PowerShell\Modules\BigAsciiChars\BigAsciiChars.psm1

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
    
    Describe '[DefaultFont]-[Constructors]' {
        It '[DefaultFont]-[Constructor] - Parameterless should Not Throw' {
            # -- Arrange
            # -- Act
            # -- Assert
            { [DefaultFont]::New() } | Should Not Throw

        }# end of it block


    }# end of Describe block

}#End InModuleScope


