using namespace System.Collections.Generic
<#

####  #  ###    ###   ###   ### # #   ### #  #  ###  ###   ###
#   # # #      #   # #     #    # #  #    #  # #   # #  # #
####  # # ###  #####  ###  #    # #  #    #### ##### ###   ###
#   # # #  #   #   #     # #    # #  #    #  # #   # # #      #
####  # ####   #   #  ###   ### # #   ### #  # #   # #  #  ###



 Codes are formed as per the following:
 4 most significant bits: ignored, set to 0
 3 next most significant bits = width of the character (value left shifted 25 places)
 25 remaining bits are subdivided into chunks of 5, each representing a row of character data, left to right

 X = Null
 W = Width
 1 = Top row
 2 = Row 2
 3 = Row 3
 4 = Row 4
 5 = Row 5

 MSB                                  LSB
         a bcde abcd  eabc deab cdea bcde
 XXXX WWW1 1111 2222  2333 3344 4445 5555
 0000 0000 0000 0000  0000 0000 0000 0000
 0000 0001 0000 1000  0100 0010 0001 0000

This can be viewed on a grid as:
  a,b,c,d,e
  - - - - -
1|
2|
3|
4|
5|

 When a width is less than 5, the most significant bits for each row are zero filled.
 That is, the character is shifted to the right of the 5x5 grid

TODO: Incorporate the $Codes hashtable into a class derived from "ASCIIFont" or similar.
This will enable multiple fonts all sharing a base class. Char width can be calculated automatically,
allowing 8x8 fonts to take up all bits of an int64

#>

# Represents the int64 value and width of a given character
class CharInfo
{
    [int64]$Value
    [int]$Width

    CharInfo([int64]$value)
    {
        $this.Value = $value
        $this.Width = 0
    }
    CharInfo([int64]$value, [int]$width)
    {
        $this.Value = $value
        $this.Width = $width
    }
}


# Base class for any derived fonts
class FontBase
{
    [Dictionary[int, CharInfo]]$Codes
    [int]$Width
    [int]$Height

    FontBase()
    {
        if ($this.GetType() -eq ([FontBase]))
        {
            throw [System.InvalidOperationException]::new("Abstract class cannot be instantiated")
        }
    }
    
    [Dictionary[int, CharInfo]]Build([hashtable]$codes)
    {
        $Dictionary = [Dictionary[int, CharInfo]]::new()
        foreach ($key in $codes.Keys)
        {
            if ($key -eq 32)
            {
                # The space character is handled differently to every other. As the value needs to be zero,
                # the value is used as the width instead
                $CharWidth = $codes[$key]
                $Dictionary.Add($key, [CharInfo]::new(0, $CharWidth ))
            }
            else
            {
                $CharWidth = GetCharWidth -Code ($codes[$key]) -FontHeight $this.Height -FontWidth $this.Width
                $Dictionary.Add($key, [CharInfo]::new($codes[$key], $CharWidth ))
            }
        }

        return $Dictionary
    }

    [bool]IsCharSupported([char]$c)
    {
        return $this.Codes.ContainsKey([int]$c)
    }

    [CharInfo]GetCharInfo([char]$c)
    {
        if (!$this.IsCharSupported($c))
        {
            return [CharInfo]::new((GetUnknownSymbol($this.Height, $this.Width)))
        }
        return $this.Codes[[int]$c]
    }

    static [int64]GetUnknownSymbol([int]$height, [int]$width)
    {
        $TopRow = (1 -shl ($width - 1)) - 1
        $MiddleRow = (1 -shl ($width - 2)) -bor 1
        [int64]$out = 0
        for ($i = 0; $i -lt $height; $i++)
        {
            $value = $MiddleRow
            if (($i - $height + 1) % ($height - 1) -eq 0) # true for first and last
            {
                $value = $TopRow
            }
            $shiftAmount = ($height - $i - 1) * ($width)
            $out = $out -bor ($value -shl $shiftAmount)
        }
        return $out
    }

    [int64]GetColumnMask()
    {
        return [FontBase]::ColumnMaskCalc($this.Height, $this.Width)
    }
    
    static [int64]ColumnMaskCalc([int]$height, [int]$width)
    {
        [int64]$out = 0
        for ($i = 0; $i -lt $height; $i++)
        {
            [int64]$start = 1 -shl ($width - 1)
            $Shifted = ($start -shl ($i * $width))
            $out = $out -bor $Shifted

        }
        return $out
    }
}


class DefaultFont : FontBase
{
    DefaultFont()
    {
        $this.Height = 5
        $this.Width = 5
        $FontHashTable = @{
            32  = 2           # Space width : can be between 1 and 5.
            33  = 34636801    # "!"
            34  = 106070016   # """
            35  = 179284970   # "#"
            36  = 184170686   # "$"
            37  = 194842995   # "%"
            38  = 180957773   # "&"
            39  = 68222976    # "'"
            40  = 68225089    # "("
            41  = 69239842    # ")"
            42  = 185750673   # "*"
            43  = 172129412   # "+"
            44  = 67108898    # ","
            45  = 100670464   # "-"
            46  = 67108963    # "."
            47  = 168890640   # "/"
            48  = 140813606   # "0"
            49  = 107022407   # "1"
            50  = 140806287   # "2"
            51  = 183015982   # "3"
            52  = 142949442   # "4"
            53  = 150222894   # "5"
            54  = 141834534   # "6"
            55  = 150016264   # "7"
            56  = 140810534   # "8"
            57  = 140811302   # "9"
            58  = 33587201    # ":"
            59  = 67141666    # ";"
            60  = 101781569   # "<"
            61  = 100892896   # "="
            62  = 104924228   # ">"
            63  = 140806276   # "?"
            64  = 200007183   # "@"
            65  = 183041585   # "A"
            66  = 199817790   # "B"
            67  = 141828359   # "C"
            68  = 199804478   # "D"
            69  = 199782943   # "E"
            70  = 150221064   # "F"
            71  = 183000670   # "G"
            72  = 143965481   # "H"
            73  = 34636833    # "I"
            74  = 175180366   # "J"
            75  = 143995209   # "K"
            76  = 142876943   # "L"
            77  = 196794033   # "M"
            78  = 186439281   # "N"
            79  = 183027246   # "O"
            80  = 150256904   # "P"
            81  = 200853443   # "Q"
            82  = 149207369   # "R"
            83  = 182990894   # "S"
            84  = 200413316   # "T"
            85  = 143959343   # "U"
            86  = 186172740   # "V"
            87  = 186177194   # "W"
            88  = 185930065   # "X"
            89  = 185929860   # "Y"
            90  = 200347935   # "Z"
            91  = 70322243    # "["
            92  = 184815681   # "\"
            93  = 70288419    # "]"
            94  = 102924288   # "^"
            95  = 134217743   # "_"
            96  = 69238784    # "`"
            97  = 199278127   # "a"
            98  = 185550398   # "b"
            99  = 183026222   # "c"
            100 = 169330223  # "d"
            101 = 183041551  # "e"
            102 = 184054288  # "f"
            103 = 183024702  # "g"
            104 = 185550385  # "h"
            105 = 34604065   # "i"
            106 = 168854590  # "j"
            107 = 186217041  # "k"
            108 = 185090575  # "l"
            109 = 178968245  # "m"
            110 = 199804465  # "n"
            111 = 183027246  # "o"
            112 = 199804880  # "p"
            113 = 184075745  # "q"
            114 = 191676944  # "r"
            115 = 184039486  # "s"
            116 = 185483838  # "t"
            117 = 186173037  # "u"
            118 = 186165572  # "v"
            119 = 190502570  # "w"
            120 = 186169905  # "x"
            121 = 186170430  # "y"
            122 = 200347935  # "z"
            123 = 103878723  # "{"
            124 = 34636833   # "|"
            125 = 107021382  # "}"
            126 = 139788288  # "~"
            127 = 150250799  # "" Used as the "unknown character" symbol
            128 = 150223247  # "€"
        }
        $this.Codes = $this.Build($FontHashTable)
    }
}

function GetLetterRow
{
    <#
    .Synopsis
    Helper function to get the row of bits for a given character
    #>
    [CmdletBinding(DefaultParameterSetName = "ByFont")]
    param(
        # The char to return
        [Parameter(Mandatory = $true, ParameterSetName = "ByFont")]
        [char]$Char,

        # The row number to get, starting from the top (0-indexed)
        [Parameter(Mandatory)]
        [ValidateRange(0, 7)]
        [int[]]
        $Row,

        # The Font to use to determine the output
        [Parameter(Mandatory = $true, ParameterSetName = "ByFont")]
        [FontBase]
        $Font,

        #The character to use as the output. Defaults to the hash sign '#'
        [char]
        $OutChar = '#',
        
        # The character to use as the background. Defaults to an empty space
        [char]
        $EmptyChar = ' ',

        [switch]
        $AsByte,

        [Parameter(Mandatory = $true, ParameterSetName = "ByValue")]
        [int64]
        $Code,

        [Parameter(Mandatory = $true, ParameterSetName = "ByValue")]
        [int]
        $Width,

        [Parameter(Mandatory = $true, ParameterSetName = "ByValue")]
        [int]
        $Height
    )
    Begin
    {

    }
    Process
    {
        if ($PSCmdlet.ParameterSetName -eq "ByFont")
        {
            $Width = $Font.Width
            $Height = $Font.Height
            $CharInfo = $Font.GetCharInfo($Char)
            
            $CharWidth = $CharInfo.Width
            Write-Debug ($CharInfo | convertTo-Json -Compress)
            
            $Code = $CharInfo.Value
        }
        else
        {
            $CharWidth = $Width
        }
        
        # The bit mask to extract a row for a font of this width
        $Mask = (1 -shl $Width) - 1
        # Represents the max shift that would be required for a font of this height and width
        $MaxShift = ($Height - 1) * $Width
        
        ForEach ($r in $row)
        {
            if ($r -ge $Height) {continue}

            $OutChars = [string]::new($EmptyChar, $CharWidth).ToCharArray()
            # Shift the bits for the required row to the least significant position and zero the remaining bits
            $RowBits = ($Code -shr ($MaxShift - $Width * $r)) -band $Mask
            if ($AsByte)
            {
                $RowBits
                continue;
            }
            $i = $OutChars.GetUpperBound(0)
            
            # This line has the side effect of ignoring the width
            #While ($RowBits -gt 0)
            While ($i -ge 0)
            {
                If (($RowBits -band 1) -eq 1)
                {
                    $OutChars[$i] = $OutChar
                }
                --$i
                $RowBits = $RowBits -shr 1
            }

            -join $OutChars
        }
    }

}

function GetLetterColumn
{
    <#
        .Synopsis
        Helper function to get the column values for a character as an array of bytes
    #>
    [CmdletBinding()]
    param(
        # The character to process. 
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [char]$Character,

        # The Dictionary to use as the lookup for character data
        [FontBase]
        $Font = [DefaultFont]::new()
    )
    Begin
    {
        $CharHeight = $Font.Height
    }
    Process
    {
        ForEach ($char in $Character)
        {
            $CharInfo = $Font.GetCharInfo($char)

            $Code = $CharInfo.Value
            $Width = $CharInfo.Width

            # Mask where all the 'a' bits (left column of character) are 1
            # We then shift this right to access the other columns
            # e.g. 0000 0001 0000 1000 0100 0010 0001 0000
            $ColumnMask = $Font.GetColumnMask()

            # Shift the mask to the first column as specified by the width value:
            $InitialShift = ($Font.Width - $Width)
            Write-Debug "InitialShift: $InitialShift"

            $ColumnMask = $ColumnMask -shr $InitialShift
            
            Write-Debug "ColumnMask: $ColumnMask"

            $SlideAmount = $Font.Width - 1

            # The amount to bump the bits to the right so that the first value is in the 2^0 position
            $NormalisingShift = $Width - 1
            # Loop for each column
            for ($i = 0; $i -lt $Width; $i++)
            { 
                $Normalised = ($Code -band $ColumnMask) -shr $NormalisingShift
                [byte]$ColVal = 0
                
                #Extraction Loop
                for ($j = 0; $j -lt $CharHeight; $j++)
                {
                    $ColVal += ($Normalised -shr ($SlideAmount * $j)) -band (1 -shl $j)
                }

                $ColVal

                $ColumnMask = $ColumnMask -shr 1
                --$NormalisingShift
                
            }
            # Insert a single separator column after each character
            [byte]0
        }
    }
}

function Write-BigText
{
    param
    (
        # The text to write
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]
        $Text,

        [Parameter(Mandatory = $false)]
        [int]
        $CharacterSeparation = 1,

        [Parameter(Mandatory = $false)]
        [char]
        $OutChar = "#",

        [Parameter(Mandatory = $false)]
        [char]
        $EmptyChar = " ",

        [FontBase]
        $Font = [DefaultFont]::new()

    )

    $TextArray = New-Object string[] $Font.Height
    $RowSB = [System.Text.StringBuilder]::new($Font.Width * $Text.Length)

    for ($i = 0; $i -lt $Font.Height; $i++)
    {
        [void]$RowSB.Clear()
        foreach ($char in $Text.ToCharArray())
        {
            [void]$RowSB.Append((GetLetterRow -Char $char -Row $i -OutChar $OutChar -EmptyChar $EmptyChar -Font $Font))
            [void]$RowSB.Append($EmptyChar, $CharacterSeparation)
        }

        $TextArray[$i] = $RowSB.ToString().TrimEnd()
    }
    
    $TextArray
}


function Write-SpinText
{
    param(
        [string]
        $Text,

        [int]
        $LoopCount = 1,

        [int]
        $FrameDelay = 100,

        [FontBase]
        $Font = [DefaultFont]::new()
    )

    begin
    {
        $SpinArray = "!/—\¡—\".ToCharArray()
        Clear-Host
    }
    end
    {
        for ($i = 0; $i -lt ($SpinArray.Length * $LoopCount); $i++)
        {
            [System.Console]::SetCursorPosition(0,0)
            $OutChar = ($SpinArray[$i % $SpinArray.Length])
            Write-BigText -Text $Text -OutChar $OutChar
            Start-Sleep -Milliseconds $FrameDelay
        }
    }
}

function NewShiftRegister ([int]$Width, [byte[]]$Array)
{
<#
    .SYNOPSIS
    Helper function to generate a Queue object to act as a shift register

    .PARAMETER Width
    The width of the register / queue

    .PARAMETER Array
    The array of bytes to feed into the register
#>
    # Initialise the Queue and fill with zeroes
    $Queue = New-Object 'System.Collections.Generic.Queue[byte]' -ArgumentList (, [byte[]]::new($Width))

    # Build a list from the Array and pad the end with zeroes
    # This enables the text to finish scrolling off the end of the display when done.
    $List = [System.Collections.Generic.List[byte]]::new($Array)
    [void]$List.AddRange([byte[]]::new($Width))
    
    while ($true)
    {
        , @($Queue.GetEnumerator())
        [void]$Queue.Dequeue()
        $Queue.Enqueue($List[0])
        try
        {
            [void]$List.RemoveAt(0)
        }
        catch
        {
            break
        }
    }
    
}
function ConvertByteToBoolArray ([byte]$Byte, [int]$Bits = 5)
{
    $BoolArray = [bool[]]::new($Bits)
    $StartBit = 1 -shl ($Bits - 1)
    for ($i = 0; $i -lt $Bits; $i++)
    {
        $BoolArray[$i] = ($Byte -band $StartBit) -eq $StartBit
        $StartBit = $StartBit -shr 1
    }
    $BoolArray
}

# Two functions to get the Most and Leasr significant bits of an input number
# The idea being that you could bitwise or all the rows of a character and use the difference 
# between the MSB and LSB to automatically calculate the character width
function GetLSB ($d, [switch]$Position)
{
    # Ensure $d is a number:
    try
    {
        [void]$d / 0
    }
    catch [System.DivideByZeroException]
    {
        # Ensure it's an integer
        if (($d -band -1) -ne $d)
        {
            throw [System.ArgumentException]::new("Argument was not an integer")
        }
        
        if ($d -eq 0) { return 0 }

        $OneLess = $d - 1 # What if equal to MinValue ?
        $PowerOfTwo = ($OneLess -bor $d) -bxor $OneLess

        if ($Position)
        {
            return [System.Math]::Log($PowerOfTwo, 2) + 1
        }
        return $PowerOfTwo

    }
    catch
    {
        throw [System.ArgumentException]::new("Argument was not a number")
    }
}

function GetMSB ($d, [switch]$Position)
{
    try
    {
        [void]$d / 0
    }
    catch [System.DivideByZeroException]
    {
        if (($d -band -1) -ne $d)
        {
            throw [System.ArgumentException]::new("Argument was not an integer")
        }
        if ($d -eq 0) { return 0 }
        $BitSize = [System.Runtime.InteropServices.Marshal]::SizeOf(($d)) * 8
        for ($i = $BitSize - 1 ; $i -ge 0 ; --$i)
        {
            if ($d -band (1 -shl $i))
            {
                if ($Position)
                {
                    return $i
                }
                return [math]::Pow(2, $i)
            }
        }

    }
    catch
    {
        throw [System.ArgumentException]::new("Argument was not a number")
    }
}

function GetCharWidth
{
    param(
        [int64]
        $Code,
        
        [int]
        $FontWidth,

        [int]
        $FontHeight
    )

    # This makes the assumption that the characters are aligned to the right
    [byte]$byte = 0
    GetLetterRow -Code $Code -Width $FontWidth -Height $FontHeight -Row (0..($FontHeight - 1)) -AsByte | ForEach-Object {
        $byte = $byte -bor $_
    }
    $MsbPos = (GetMSB -d $byte -Position)
    return 1 + $MsbPos
}



function Write-ScrollText
{
    <#
    .SYNOPSIS
        Simulates an LED scrolling display
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        A string to display
    .OUTPUTS
        To console only
    .NOTES
        General notes
    #>
    [CmdletBinding()]
    Param(
        # The text to scroll across the display
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Text,
        
        # The width of the display. The average width of a character is approx 5 columns, so a width of 100 will display approx 20 characters at once
        [Parameter(Mandatory = $false)]
        [int]
        $Width = [math]::floor([Console]::BufferWidth / 3),
        
        # The number of milliseconds to target between display updates
        [Parameter(Mandatory = $false)]
        [Alias("interval")]
        [int]
        $FrameDelay = 50,

        # Clears the console before starting to write the scroll display
        [switch]
        [Alias("cls")]
        $ClearScreen,
        
        #  The Font to use in the display.
        [Parameter(Mandatory = $false)]
        [FontBase]
        $Font = [DefaultFont]::new()

    )
    Begin
    {
        $Height = $Font.Height
        #$OnOff = @([char]9675,[char]9679)  # Order is actually (Off, On) so you can supply a bool to the index
        $OnOff = @(" ", [char]9679)
        $CursorVisibility = [Console]::CursorVisible
        [Console]::CursorVisible = $false

        # Attempt to make sure there is enough room in the console buffer to display the scroller in place.
        # If there isn't, the window will scroll with all outputs. To avoid this, use clear-screen beforehand
        $BufH = [Console]::BufferHeight
        if ($BufH - [System.Console]::CursorTop -lt $Height)
        {
            [Console]::BufferHeight = [Math]::Min([short]::MaxValue, $BufH + 10)
        }

        $Top = [math]::Min([Console]::BufferHeight - 1, [Console]::CursorTop + 1)

        if ($ClearScreen)
        {
            Clear-Host
        }
    }
    Process
    {
        try
        {
            # Set up rectangular array for our 'display'
            $Display = [bool[][]]::new($Width, $Height)
            $TextBytes = ($Text.ToCharArray() | GetLetterColumn -Font $Font) -as [byte[]]

            $Timer = [System.Diagnostics.Stopwatch]::StartNew()

            ForEach ($tick in (NewShiftRegister -Width $Width -Array $TextBytes))
            {
                $Timer.Restart()
                [Console]::SetCursorPosition(0, $top)
                
                Write-Host ("-" * $Width)
                for ($i = 0; $i -lt $Width; $i++)
                {
                    # Convert each column byte to booleans
                    $Display[$i] = (ConvertByteToBoolArray -Byte $tick[$i] -Bits $Height)
                    Write-Debug ($Display[$i] -join ';')
                }

                $sb = [System.Text.StringBuilder]::new($Width)
            
                for ($h = 0; $h -lt $Height; $h++)
                {
                    [void]$sb.Clear()
                    for ($w = 0; $w -lt $Width; $w++)
                    {
                        [void]$sb.Append($OnOff[($Display[$w][$h] -as [int])])
                    }
                    $sb.ToString() | Out-Host
                }
                Write-Host ("-" * $Width)
                Start-Sleep -Milliseconds ([math]::Max(0, $FrameDelay - $Timer.Elapsed.TotalMilliseconds))
            }   
        }
        finally
        {
            # Force cursor re-visibility even if we Ctrl-C out of the loop
            [Console]::CursorVisible = $CursorVisibility
        }
        

    }
    End
    {
    }
}


function Get-BADefaultFont
{
    <#
    .SYNOPSIS
    Wrapper function to return a DefaultFont object
    
    .DESCRIPTION
    Calls the parameter-less constructor on the [DefaultFont] class
    
    .EXAMPLE
    $Font = Get-DefaultFont
    
    .NOTES
    
    #>
    
    return [DefaultFont]::new()
}


function Get-BAAvailableFont
{
    <#
    .SYNOPSIS
    Lists the available fonts installed with the module
    
    .EXAMPLE
    Get-AvailableFont
    
    .NOTES
    Reles on the ability to get the "ImplementingAssembly" attribute from the [psmoduleinfo]. Using Get-Module with $PSScriptRoot feels a fragile way of doing this. Open to improved suggestions
    #>
    (Get-Module).Where({([IO.FileInfo]$_.Path).Directory.FullName -eq $PSScriptRoot}).ImplementingAssembly.GetTypes().Where({$_.IsPublic -And $_.BaseType.Name -eq "FontBase"}).Name
}


function New-BAFont
{
    <#
    .SYNOPSIS
    Create a new instance of an available Ascii Font
    
    .DESCRIPTION
    Long description
    
    .PARAMETER Name
    Parameter description
    
    .EXAMPLE
    $Font = New-Font -Name "DefaultFont"
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [ArgumentCompleter({Get-AvailableFont})]
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    New-Object -TypeName $Name
}