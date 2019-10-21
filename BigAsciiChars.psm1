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
            # Skip adding if value not provided - use the unknown character symbol instead
            if ($codes[$key] -eq 0) { continue }

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
            return [CharInfo]::new(([FontBase]::GetUnknownSymbol($this.Height, $this.Width)), $this.Width - 1)
        }
        return $this.Codes[[int]$c]
    }

    static [int64]GetUnknownSymbol([int]$height, [int]$width)
    {
        [int64]$TopRow = (1 -shl ($width - 1)) - 1
        [int64]$MiddleRow = (1 -shl ($width - 2)) -bor 1
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

class Simple8x8 : FontBase
{
    Simple8x8()
    {
        $this.Height = 8
        $this.Width  = 8
        $FontHashTable = @{
            32	=	2	                   # 	space
            33	=	0x0101010101010001	   # 	!
            34	=	0x0505000000000000	   # 	"
            35	=	0x12127F12127F1212	   # 	#
            36	=	0x083E48483E093E08	   # 	$
            37	=	0x0071527408172547	   # 	%
            38	=	0x384444283D45423D	   # 	&
            39	=	0x0001010000000000	   # 	'
            40	=	0x0102040404040201	   # 	(
            41	=	0x0402010101010204	   # 	)
            42	=	0x0049493E083E4949	   # 	*
            43	=	0x000008087F080800	   # 	+
            44	=	0x0000000000000102	   # 	,
            45	=	0x000000003F000000	   # 	-
            46	=	0x0000000000000303	   # 	.
            47	=	0x0102020404080810	   # 	/
            48	=	0x1C2241414141221C	   # 	0
            49	=	0x0206020202020207	   # 	1
            50	=	0x3E4141061820403F	   # 	2
            51	=	0x1E2101011E01413E	   # 	3
            52	=	0x404040447F040404	   # 	4
            53	=	0x7F40403C0201413E	   # 	5
            54	=	0x1F2040BCC281413E	   # 	6
            55	=	0x7E01020408102040	   # 	7
            56	=	0x3E4141413E41413E	   # 	8
            57	=	0x1E2121211F020C30	   # 	9
            58	=	0x0000010000000100	   # 	:
            59	=	0x0000010000010200	   # 	;
            60	=	0x030C30C0C0300C03	   # 	<
            61	=	0x0000007F007F0000	   # 	=
            62	=	0xC0300C03030C30C0	   # 	>
            63	=	0x1E21210204080008	   # 	?
            64	=	0x7C82BDA5BF80413E	   # 	@
            65	=	0x3C428181FF818181	   # 	A
            66	=	0xFC8284FC828182FC	   # 	B
            67	=	0x7E8180808080817E	   # 	C
            68	=	0xFC828181818182FC	   # 	D
            69	=	0xFE8080F8808080FF	   # 	E
            70	=	0x7F40407C40404040	   # 	F
            71	=	0x3F4080809E81413F	   # 	G
            72	=	0x4141417F41414141	   # 	H
            73	=	0x0702020202020207	   # 	I
            74	=	0x1F0202020242423E	   # 	J
            75	=	0x2126283028242221	   # 	K
            76	=	0x404040404040407F	   # 	L
            77	=	0x4163554949414141	   # 	M
            78	=	0x81C1A19189858381	   # 	N
            79	=	0x3C4281818181423C	   # 	O
            80	=	0x7E4141417E404040	   # 	P
            81	=	0x3E41414141493E01	   # 	Q
            82	=	0xFC828284F8848281	   # 	R
            83	=	0x3C4242700C42423C	   # 	S
            84	=	0x7F08080808080808	   # 	T
            85	=	0x414141414141413E	   # 	U
            86	=	0x8181424224241818	   # 	V
            87	=	0x818181425A5A2424	   # 	W
            88	=	0x8142241818244281	   # 	X
            89	=	0x8142241810204080	   # 	Y
            90	=	0xFF020408102040FF	   # 	Z
            91	=	0x0704040404040407	   # 	[
            92	=	0x1008080404020201	   # 	\
            93	=	0x0701010101010107	   # 	]
            94	=	0x040A110000000000	   # 	^
            95	=	0x000000000000007F	   # 	_
            96	=	0x0403000000000000	   # 	`
            97	=	0x00001E01011F111F	   # 	a
            98	=	0x002020203E21213E	   # 	b
            99	=	0x00001E212020211E	   # 	c
            100	=	0x000101010F11110F	   # 	d
            101	=	0x0000001E213E201E	   # 	e
            102	=	0x00000E091C080808	   # 	f
            103	=	0x00000F111F01211E	   # 	g
            104	=	0x0020202C32212121	   # 	h
            105	=	0x0002000202020201	   # 	i
            106	=	0x0001000101010906	   # 	j
            107	=	0x00080B0C080C0A09	   # 	k
            108	=	0x0002020202020201	   # 	l
            109	=	0x0000323D29292121	   # 	m
            110	=	0x0000001619111111	   # 	n
            111	=	0x0000001E2121211E	   # 	o
            112	=	0x00001719111E1010	   # 	p
            113	=	0x00000D13110F0101	   # 	q
            114	=	0x0000171810101010	   # 	r
            115	=	0x00000E100E01010E	   # 	s
            116	=	0x00101C101010111E	   # 	t
            117	=	0x000021212121231D	   # 	u
            118	=	0x000021212121120C	   # 	v
            119	=	0x0000414141492A14	   # 	w
            120	=	0x000011110A0C0A11	   # 	x
            121	=	0x000021211E022418	   # 	y
            122	=	0x00003E030408103F	   # 	z
            123	=	0x0306040202040403	   # 	{
            124	=	0x0101010101010101	   # 	|
            125	=	0x0603010202010106	   # 	}
            126	=	0x1926000000000000	   # 	~
            127	=	0x3F2121212121213F	   # 	
            128	=	0x3E41407C4078413E	   # 	€
            129	=	0                	   # 	
            130	=	0x0000000000000102	   # 	‚
            131	=	0x0302070202020206	   # 	ƒ
            132	=	0x000000000000050A	   # 	„
            133	=	0x0000000000000015	   # 	…
            134	=	0x0002070202020200	   # 	†
            135	=	0x0002070202070200	   # 	‡
            136	=	0x0002050000000000	   # 	ˆ
            137	=	0x00C2C40810205B9B	   # 	‰
            138	=	0xA040E11100E011E	   # 	Š
            139	=	0x0000000102040201	   # 	‹
            140	=	0x007F88888F88887F	   # 	Œ
            141	=	0	                   # 	
            142	=	0x0A043F020408103F	   # 	Ž
            143	=	0	                   # 	
            144	=	0	                   # 	
            145	=	0x0102030300000000	   # 	‘
            146	=	0x0303010200000000	   # 	’
            147	=	0x09121B1B00000000	   # 	“
            148	=	0x1B1B091200000000	   # 	”
            149	=	0x000000060F060000	   # 	•
            150	=	0x000000003F000000	   # 	–
            151	=	0x00000000FF000000	   # 	—
            152	=	0x1926000000000000	   # 	˜
            153	=	0xEA55550000000000	   # 	™
            154	=	0x050200070802010E	   # 	š
            155	=	0x0008040201020408	   # 	›
            156	=	0x00000077898F8877	   # 	œ
            157	=	0               	   # 	
            158	=	0x0A04001F0204081F	   # 	ž
            159	=	0x1441221408080808	   # 	Ÿ
            160	=	0               	   # 	 
            161	=	0x0100010101010101	   # 	¡
            162	=	0x041E212020211E04	   # 	¢
            163	=	0x001E20207C20207F	   # 	£
            164	=	0x110E1111110E11	   # 	¤
            165	=	0x412214087F087F08	   # 	¥
            166	=	0x0101010000010101	   # 	¦
            167	=	0x3C403C24243C023C	   # 	§
            168	=	0x0024000000000000	   # 	¨
            169	=	0x7E81BDA1A1BD817E	   # 	©
            170	=	0x06010F090F001F00	   # 	ª
            171	=	0x00050A1428140A05	   # 	«
            172	=	0x00003F0100000000	   # 	¬
            173	=	0x0000001F00000000	   # 	­
            174	=	0x3E4D5151513E0000	   # 	®
            175	=	0x0007000000000000	   # 	¯
            176	=	0x0205020000000000	   # 	°
            177	=	0x04041F0404001F00	   # 	±
            178	=	0x0205010207000000	   # 	²
            179	=	0x0601060106000000	   # 	³
            180	=	0x0102000000000000	   # 	´
            181	=	0x00002222221E2120	   # 	µ
            182	=	0x001F393919090909	   # 	¶
            183	=	0x0000000006060000	   # 	·
            184	=	0x000000000000040C	   # 	¸
            185	=	0x0103010101000000	   # 	¹
            186	=	0x1C2222221C003E00	   # 	º
            187	=	0x0028140A050A1428	   # 	»
            188	=	0x2022240A142B0200	   # 	¼
            189	=	0x2022240A15220700	   # 	½
            190	=	0xC022E42AD4274202	   # 	¾
            191	=	0x040004081010110E	   # 	¿
            192	=	0x08041C22417F4141	   # 	À
            193	=	0x04081C22417F4141	   # 	Á
            194	=	0x08141C22417F4141	   # 	Â
            195	=	0x14283C4281FF8181	   # 	Ã
            196	=	0x14001C22417F4141	   # 	Ä
            197	=	0x08140808143E4141	   # 	Å
            198	=	0x1F284888FF88888F	   # 	Æ
            199	=	0x1F202020201F040C	   # 	Ç
            200	=	0x08043F203E20203F	   # 	È
            201	=	0x04083F203E20203F	   # 	É
            202	=	0x08143F203E20203F	   # 	Ê
            203	=	0x12003F203E20203F	   # 	Ë
            204	=	0x0201020202020202	   # 	Ì
            205	=	0x0102010101010101	   # 	Í
            206	=	0x0205020202020202	   # 	Î
            207	=	0x0500020202020202	   # 	Ï
            208	=	0x003C22217921223C	   # 	Ð
            209	=	0x0A14213129252321	   # 	Ñ
            210	=	0x08043E414141413E	   # 	Ò
            211	=	0x08103E414141413E	   # 	Ó
            212	=	0x08143E414141413E	   # 	Ô
            213	=	0x0A143E414141413E	   # 	Õ
            214	=	0x14003E414141413E	   # 	Ö
            215	=	0x0000110A040A1100	   # 	×
            216	=	0x013E464A52627C80	   # 	Ø
            217	=	0x100841414141413E	   # 	Ù
            218	=	0x040841414141413E	   # 	Ú
            219	=	0x081441414141413E	   # 	Û
            220	=	0x140041414141413E	   # 	Ü
            221	=	0x0851221408080808	   # 	Ý
            222	=	0x407C424141427C40	   # 	Þ
            223	=	0x1C2222242C22212E	   # 	ß
            224	=	0x0804001E2222221D	   # 	à
            225	=	0x0408001E2222221D	   # 	á
            226	=	0x0814001E2222221D	   # 	â
            227	=	0x0A14001E2222221D	   # 	ã
            228	=	0x0014001E2222221D	   # 	ä
            229	=	0x0814081E2222221D	   # 	å
            230	=	0x000076093F484936	   # 	æ
            231	=	0x000E1110110E0418	   # 	ç
            232	=	0x1008041E213E201E	   # 	è
            233	=	0x0408101E213E201E	   # 	é
            234	=	0x0814001E213E201E	   # 	ê
            235	=	0x0014001E213E201E	   # 	ë
            236	=	0x0201000101010101	   # 	ì
            237	=	0x0102000202020202	   # 	í
            238	=	0x0205000202020202	   # 	î
            239	=	0x0005000202020202	   # 	ï
            240	=	0x000A0C020911110E	   # 	ð
            241	=	0x0A14002C32222222	   # 	ñ
            242	=	0x0804001E2121211E	   # 	ò
            243	=	0x0408001E2121211E	   # 	ó
            244	=	0x0814001E2121211E	   # 	ô
            245	=	0x0A14001E2121211E	   # 	õ
            246	=	0x0012001E2121211E	   # 	ö
            247	=	0x000008007F000800	   # 	÷
            248	=	0x00011E2529313E40	   # 	ø
            249	=	0x080421212121231D	   # 	ù
            250	=	0x040821212121231D	   # 	ú
            251	=	0x040A21212121231D	   # 	û
            252	=	0x140021212121231D	   # 	ü
            253	=	0x000204110A040810	   # 	ý
            254	=	0x0010141A11111A14	   # 	þ
            255	=	0x000A00110A040810	   # 	ÿ
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

        # The font to use for character data
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

# Two functions to get the Most and Least significant bits of an input number
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
    [CmdletBinding(DefaultParameterSetName = "FromText")]
    Param(
        # The text to scroll across the display
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = "FromText")]
        [string]
        $Text,
        
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            Position = 0,
            ParameterSetName = "FromBytes")]
        [byte[]]
        $Bytes,

        [Parameter(
            Mandatory = $false,
            ParameterSetName = "FromBytes")]
        [ValidateRange(1,8)]
        [int]
        $Height = 8,

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
        $Font = [DefaultFont]::new(),

        [Parameter(Mandatory = $false)]
        [char]
        $OnChar = [char]9679,

        [Parameter(Mandatory = $false)]
        [char]
        $OffChar = " "

    )
    Begin
    {
        if ($PSCmdlet.ParameterSetName -eq "FromText")
        {
            $Height = $Font.Height
        }
        #$OnOff = @([char]9675,[char]9679)  # Order is actually (Off, On) so you can supply a bool to the index
        $OnOff = @($OffChar, $OnChar)
        $CursorVisibility = [Console]::CursorVisible
        [Console]::CursorVisible = $false

        # Attempt to make sure there is enough room in the console buffer to display the scroller in place.
        # If there isn't, the window will scroll with all outputs. To avoid this, use clear-screen beforehand
        $BufH = [Console]::BufferHeight
        if ($BufH - [System.Console]::CursorTop -lt $Height)
        {
            [Console]::BufferHeight = [Math]::Min([short]::MaxValue, $BufH + ($Height * 2))
        }

        if ($ClearScreen)
        {
            $top = 0
        }
        else
        {
            $Top = [math]::Min([Console]::BufferHeight - 1, [Console]::CursorTop + 1)
        }

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
            
            if ($PSCmdlet.ParameterSetName -eq "FromText")
            {
                $Bytes = ($Text.ToCharArray() | GetLetterColumn -Font $Font) -as [byte[]]
            }

            $Timer = [System.Diagnostics.Stopwatch]::StartNew()

            ForEach ($tick in (NewShiftRegister -Width $Width -Array $Bytes))
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
        [ArgumentCompleter( {
                param(
                    $commandName,
                    $parameterName,
                    $wordToComplete,
                    $commandAst,
                    $fakeBoundParameters
                )
                (Get-BAAvailableFont).Where({$_ -like "$wordToComplete*"}) | ForEach-Object {$_}
            })]
        [Parameter(Mandatory = $true)]
        [string]
        $Name
    )

    New-Object -TypeName $Name
}
