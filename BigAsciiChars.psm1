<#

###   #### #####      ####   #   ### ##### ####  #   # #####
#     #      #        #   #  #  #      #   #      # #    #
# ### ###    #   ###  ####   #  # ###  #   ###     #     #
#  #  #      #        #   #  #  #  #   #   #      # #    #
####  #####  #        ####   #  ####   #   ##### #   #   #

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

#>
$Codes = @{
    32 = 2 -shl 25   # Space width : can be between 1 and 5.
    33 = 34636801   # "!"
    34 = 106070016  # """
    35 = 179284970  # "#"
    36 = 184170686  # "$"
    37 = 194842995  # "%"
    38 = 180957773  # "&"
    39 = 68222976   # "'"
    40 = 68225089   # "("
    41 = 69239842   # ")"
    42 = 185750673  # "*"
    43 = 172129412  # "+"
    44 = 67108898   # ","
    45 = 100670464  # "-"
    46 = 67108963   # "."
    47 = 168890640  # "/"
    48 = 140813606  # "0"
    49 = 107022407  # "1"
    50 = 140806287  # "2"
    51 = 183015982  # "3"
    52 = 142949442  # "4"
    53 = 150222894  # "5"
    54 = 141834534  # "6"
    55 = 150016264  # "7"
    56 = 140810534  # "8"
    57 = 140811302  # "9"
    58 = 33587201   # ":"
    59 = 67141666   # ";"
    60 = 101781569  # "<"
    61 = 100892896  # "="
    62 = 104924228  # ">"
    63 = 140806276  # "?"
    64 = 200007183  # "@"
    65 = 183041585  # "A"
    66 = 199817790  # "B"
    67 = 141828359  # "C"
    68 = 199804478  # "D"
    69 = 199782943  # "E"
    70 = 150221064  # "F"
    71 = 183000670  # "G"
    72 = 143965481  # "H"
    73 = 34636833   # "I"
    74 = 175180366  # "J"
    75 = 143995209  # "K"
    76 = 142876943  # "L"
    77 = 196794033  # "M"
    78 = 186439281  # "N"
    79 = 183027246  # "O"
    80 = 150256904  # "P"
    81 = 200853443  # "Q"
    82 = 149207369  # "R"
    83 = 182990894  # "S"
    84 = 200413316  # "T"
    85 = 143959343  # "U"
    86 = 186172740  # "V"
    87 = 186177194  # "W"
    88 = 185930065  # "X"
    89 = 185929860  # "Y"
    90 = 200347935  # "Z"
    91 = 70322243   # "["
    92 = 184815681  # "\"
    93 = 70288419   # "]"
    94 = 102924288  # "^"
    95 = 134217743  # "_"
    96 = 69238784   # "`"
    97 = 0          # "a"
    98 = 0          # "b"
    99 = 0          # "c"
    100 = 0         # "d"
    101 = 0         # "e"
    102 = 0         # "f"
    103 = 0         # "g"
    104 = 0         # "h"
    105 = 0         # "i"
    106 = 0         # "j"
    107 = 0         # "k"
    108 = 0         # "l"
    109 = 0         # "m"
    110 = 0         # "n"
    111 = 0         # "o"
    112 = 0         # "p"
    113 = 0         # "q"
    114 = 0         # "r"
    115 = 0         # "s"
    116 = 0         # "t"
    117 = 0         # "u"
    118 = 0         # "v"
    119 = 0         # "w"
    120 = 0         # "x"
    121 = 0         # "y"
    122 = 0         # "z"
    123 = 103878723 # "{"
    124 = 34636833  # "|"
    125 = 107021382 # "}"
    126 = 139788288 # "~"
    127 = 150250799 # "" Used as the "unknown character" symbol
    128 = 150223247 # "€"
}

function GetLetterRow {
    <#
    .Synopsis
    Helper function to get
    #>
    
    param(
        # The char to return
        [Parameter(Mandatory)]
        [char]$Char,

        # The row number to get, starting from the top (0-indexed)
        [Parameter(Mandatory)]
        [ValidateRange(0,4)]
        [int[]]
        $Row,

        # The Dictionary to use as the lookup for character data
        [System.Collections.IDictionary]
        $Dictionary = $Codes,

        #The character to use as the output. Defaults to the hash sign '#'
        [char]
        $OutChar = '#'
    )
    Begin{

    }
    Process{
        if (!$Dictionary.Contains([int]$Char))
        {
            $Code = 150250799
        }
        else{
            $Code = $Dictionary[[int]$Char]
        }
        
        $Width = ($Code -band (7 -shl 25)) -shr 25
        
        
        
        ForEach ($r in $row)
        {
            $OutChars = "     ".ToCharArray()
            # Shift the bits for the required row to the least significant position and zero the remaining bits
            $5Bits = ($Code -shr (20 - 5 * $r)) -band 31
            $i = 4
            While ($5Bits -gt 0)
            {
                If (($5Bits -band 1) -eq 1)
                {
                    $OutChars[$i] = $OutChar
                }
                --$i
                $5Bits = $5Bits -shr 1
            }

            $OutString = -join $OutChars
            $OutString.Substring(5-$Width,$Width)
        }
    }

}

function GetLetterColumn {
    <#
        .Synopsis
        Helper function to get the column values for a character as an array of bytes
    #>
    [CmdletBinding()]
    param(
        # The character to process. 
        [Parameter(Mandatory, ValueFromPipeline)]
        [char]$Character,

        # The Dictionary to use as the lookup for character data
        [System.Collections.IDictionary]
        $Dictionary = $Codes
    )
    Begin {

    }
    Process {
        ForEach ($char in $Character) {
            if (!$Dictionary.Contains([int]$Char))
            {
                $Code = 150250799
            }
            else{
                $Code = $Dictionary[[int]$Char]
            }
            $Width = ($Code -band (7 -shl 25)) -shr 25

            # integer where all the 'a' bits (left column of character) are 1
            # We then shift this right to access the other columns
            $ColumnMask = 17318416

            # Shift the mask to the first column as specified by the width value:
            $InitialShift = (5 - $Width)
            Write-Debug "InitialShift: $InitialShift"

            $ColumnMask = $ColumnMask -shr $InitialShift
            
            Write-Debug "ColumnMask: $ColumnMask"

            # The amount to bump the bits to the right so that the first value is in the 2^0 position
            $NormalisingShift = $Width - 1
            for ($i = 0; $i -lt $Width; $i++) { # Loop for each column
                
                $Normalised = ($Code -band $ColumnMask) -shr $NormalisingShift
                [byte]$ColVal = 0
                
                for ($j = 0; $j -lt 5; $j++) { #Extraction Loop
                    # Todo: change to while Normalised -gt 0
                    $ColVal += ($Normalised -shr (4 * $j)) -band (1 -shl $j)
                }

                $ColVal

                $ColumnMask = $ColumnMask -shr 1
                --$NormalisingShift
                
            }
            # Insert a seperator line after each character
            [byte]0
        }
    }
}
function Get-BigText {
    param(
        [string]$Text,
        [int]$CharacterSeparation = 1
    )

    $TextArray = New-Object string[] 5
    $RowSB = [System.Text.StringBuilder]::new(4* $Text.Length, 5 * $Text.Length)

    for ($i = 0; $i -le 4; $i++)
    {
        [void]$RowSB.Clear()
        foreach ($char in $Text.ToUpper().ToCharArray())
        {
            [void]$RowSB.Append((GetLetterRow -Char $char -Row $i))
            [void]$RowSB.Append(" " * $CharacterSeparation)
        }

        $TextArray[$i] = $RowSB.ToString().TrimEnd()
    }
    
    $TextArray
}

function New-ShiftRegister ([int]$Width, [byte[]]$Array) {
    
    # Initialise the Queue and fill with zeroes
    $Queue = New-Object 'System.Collections.Generic.Queue[byte]' -ArgumentList (,[byte[]]::new($Width))

    # Build a list from the Array and pad the end with zeroes
    $List = [System.Collections.Generic.List[byte]]::new($Array)
    [void]$List.AddRange([byte[]]::new($Width))
    $TotalCount = $List.Count
    
    while ($true)
    {
        ,@($Queue.GetEnumerator())
        [void]$Queue.Dequeue()
        $Queue.Enqueue($List[0])
        try {
            [void]$List.RemoveAt(0)
        }
        catch {
            break
        }
    }
    
}
function ConvertByteToBoolArray ([byte]$Byte, [int]$Bits = 5) {
    $BoolArray = [bool[]]::new($Bits)
    $StartBit = 1 -shl ($Bits - 1)
    for ($i = 0; $i -lt $Bits; $i++)
    {
        $BoolArray[$i] = ($Byte -band $StartBit) -eq $StartBit
        $StartBit = $StartBit -shr 1
    }
    $BoolArray
}
function Write-ScrollText {
    <#
    .SYNOPSIS
        Simulates an LED scrolling display
    .DESCRIPTION
        Long description
    .EXAMPLE
        PS C:\> <example usage>
        Explanation of what the example does
    .INPUTS
        Inputs (if any)
    .OUTPUTS
        Output (if any)
    .NOTES
        General notes
    #>
    [CmdletBinding()]
    Param(
        # The text to scroll across the display
        [string]$Text,
        
        # The width of the display. The average width of a character is approx 5 columns, so a width of 100 will display approx 20 characters at once
        [int]$Width,
        
        # The number of milliseconds to pause between updating the display. Large displays will take longer to render, meaning the same delay will not result in the same speed for different widths.
        [int]$FrameDelay = 200
    )
    Begin{
        #$OnOff = @([char]9675,[char]9679)  # Order is actually (Off, On) so you can supply a bool to the index
        $OnOff = @(" ", [char]9679)
        $Height = 5
    }
    Process{
        # Set up rectangular array for our 'display'
        $Display = [bool[][]]::new($Width, $Height)
        $TextBytes = ($Text.ToUpper().ToCharArray()|GetLetterColumn) -as [byte[]]

        ForEach ($tick in (New-ShiftRegister -Width $Width -Array $TextBytes))
        {
            Write-Verbose "tick = $($tick -join ';')"
            Write-Host ("-" * $Width)
            for ($i = 0; $i -lt $Width; $i++)
            {
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
            Start-Sleep -Milliseconds $FrameDelay
        }

    }
}

Export-ModuleMember -Function *-*