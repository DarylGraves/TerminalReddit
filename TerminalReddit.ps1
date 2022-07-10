function Start-TerminalReddit {
    param (
        [String]$Subreddit = "Popular"
    )
    
    $Global:ScreenWidth = [System.Console]::BufferWidth
    $Global:ScreenHeight = [System.Console]::BufferHeight
    $Global:BorderPosition = 3
    $Global:RowsToDisplay = $ScreenHeight - $BorderPosition
       
    if (($ScreenWidth -lt 58) -or ($ScreenHeight -lt 30)) {
        Write-Host "Screen too small" -ForegroundColor Red
        Return
    }

    # On Startup, always load a subreddit
    Clear-MainWindow
    $Posts = Get-RedditPosts -Subreddit $Subreddit
    $FirstPostNo = 0
    $LastPostNo = $ScreenHeight - $BorderPosition
    Display-RedditPosts -Posts $Posts -StartNumber $FirstPostNo -NumberToDisplay $LastPostNo

    # Now get user input:
    $closeApp = $false
    while ($closeApp -ne $true) {
        Set-PromptText
        $userInput = Get-UserInput

        # For some weird reason $key.char returns numbers with a 'D' prefixed...
        $userInputasInt = $userInput.Replace("D", "")  -as [int]
        
        if ($userInputasInt -ne $null) {
            #TODO: Open a Reddit Post
        }
        else {
            if ($userInput.Length -eq 1) {
                switch ($userInput[0]) {
                    "S" {
                        Subreddit-PromptText
                        $UserInput = Get-UserInput
                    } #TODO: Search
                    "R" {
                        Refreshing-PromptText
                        $Posts = Get-RedditPosts -Subreddit $Subreddit
                        $FirstPostNo = 0
                        $LastPostNo = $RowsToDisplay
                        Clear-MainWindow
                        Display-RedditPosts -Posts $Posts -StartNumber $FirstPostNo -NumberToDisplay $LastPostNo
                    }
                    "N" {
                        if ($LastPostNo  -lt $Posts.Count) {
                            $FirstPostNo = $LastPostNo
                            $LastPostNo += $RowsToDisplay
                            
                            if($LastPostNo -gt $Posts.Count){
                                $LastPostNo = $Posts.Count
                            }

                            Display-RedditPosts -Posts $Posts -StartNumber $FirstPostNo -NumberToDisplay $LastPostNo
                        }
                    }
                    "P" {
                        if ($FirstPostNo -gt 0) {
                            $FirstPostNo = $FirstPostNo - $RowsToDisplay
                            $LastPostNo = $FirstPostNo + $RowsToDisplay
                        
                            if($FirstPostNo -le 0){
                                $FirstPostNo = 0
                                $LastPostNo = $FirstPostNo + $RowsToDisplay
                            }

                            Display-RedditPosts -Posts $Posts -StartNumber $FirstPostNo -NumberToDisplay $LastPostNo
                        }
                    }
                    "Q" { $closeApp = $True }
                    Default {}
                }
            }
        }
    }

    Clear-Host
}

function Create-Borders {
    [System.Console]::SetCursorPosition(0, $ScreenHeight - $BorderPosition)
    
    $Border = "_" * $ScreenWidth
    Write-Host $Border
}

function Get-RedditPosts {
    param (
        [String]$Subreddit = "popular"
    )
    
    try {
        $WebRequest = Invoke-WebRequest -Uri "https://old.reddit.com/r/$Subreddit/.json?limit=99"
    }
    catch {
        #TODO: Invalid website? Close app or just return nothing?
    }

    $Posts = $WebRequest.Content | ConvertFrom-Json
    Return $Posts.Data.Children
}

function Display-RedditPosts {
    param (
        [PSCustomObject]$Posts,
        [Int]$NumberToDisplay,
        [Int]$StartNumber = 0,
        [Bool]$Gui = $True
    )

    Clear-MainWindow
    
    if ($Gui) {
        [System.Console]::SetCursorPosition(0, 0)
    }

    # Variables
    $MaxCharsSubreddit = Divide-Int -Multiples 1 -Divisor 5 -IntToDivide ($ScreenWidth - 5)
    $MaxCharsWhiteSpace = $MaxCharsSubreddit + 1
    $MaxCharsTitle = Divide-Int -Multiples 4 -Divisor 5 -IntToDivide ($ScreenWidth - 5)

    for ($i = $StartNumber; $i -lt $NumberToDisplay; $i++) {
        $Number = if ($($i+1) -lt 10) { "[$($i+1) ]" } else { "[$($i+1)]" }
        $Subreddit = Truncate-String -Text $Posts[$i].data.Subreddit -NewSize $MaxCharsSubreddit
        $Title = Truncate-String -Text $Posts[$i].data.title -NewSize $MaxCharsTitle
        
        #TODO: Display-RedditPosts: Ability for user to change colours
        #TODO: Display-RedditPosts: If the subreddit name varies in length, column should still be the same width... (example of this is loading popular)
        Write-Host "$Number" -ForegroundColor Blue -NoNewline
        Write-Host "$Subreddit " -ForegroundColor Yellow -NoNewline
        Write-Host $Title -ForegroundColor Green
    }

    Cursor-ToBottom
    #TODO: Display-RedditPosts shows the character from the previous entry
}

function Truncate-String {
    param (
        [String]
        $Text,
        [Int]
        $NewSize
    )
   
    if ($Text.Length -gt $NewSize)
    {
        $Text = $Text.Substring(0, $NewSize - $BorderPosition)
        $Text = $Text + "..."
    }

    return $Text
}

function Divide-Int {
    param (
        [parameter(Mandatory=$true)]
        [Int]
        $Multiples,
        [parameter(Mandatory=$true)]
        [Int]
        $Divisor,
        [Int]
        $IntToDivide  
    )

    $Calculation = $IntToDivide / $Divisor

    if ($Calculation % 2 -eq 0){
        return $Calculation * $Multiples
    }
    else {
        return [int]($Calculation * $Multiples)
    }
}

function Clear-MainWindow {
    Clear-Host
    Create-Borders
}

function Cursor-ToBottom {
    [System.Console]::SetCursorPosition(0, $ScreenHeight - ($BorderPosition - 1))
}

function Set-PromptText {
    # Clear whatever is already there...
    [System.Console]::SetCursorPosition(0, $RowsToDisplay + 1)
    $Text = (" " * $ScreenWidth)
    Write-Host $Text -NoNewline

    # And now print
    [System.Console]::SetCursorPosition(0, $RowsToDisplay + 1)
    Write-Host "(S)earch, (R)efresh, (N)ext, (P)rev, (Q)uit or post number: " -NoNewline

    #TODO: Set-PromptText - Highlight options in a different colour?
}

function Refreshing-PromptText {
    # Clear whatever is already there...
    [System.Console]::SetCursorPosition(0, $RowsToDisplay + 1)
    $Text = (" " * $ScreenWidth)
    Write-Host $Text -NoNewline

    # And now print
    [System.Console]::SetCursorPosition(0, $RowsToDisplay + 1)
    Write-Host "Refreshing... Please wait." -NoNewline
}
function Get-UserInput {
    Param(
        [Int]$AcceptedNoOfChars = 1
    )

    $char = ""
    $charCount = 0
    $userInput = ""
    
    do {
        $char = [System.Console]::ReadKey()

        if ($char.Key -eq "Backspace") {
            if ($charCount -gt 0) {
                # Overwrite the previous char in the console... 
                Write-Host " " -NoNewline
                $CurrentXPos = [System.Console]::CursorLeft
                $CurrentYPos = [System.Console]::CursorTop
                # ...But then you have to reset the cursor
                [System.Console]::SetCursorPosition(($CurrentXPos - 1), $CurrentYPos)

                # Update what is added to the return
                $userInput = $userInput.Substring(0, $userInput.Length - 1)
                $charCount -= 1

                #TODO: Backspace will keep going into the prompt....
            }
        }
        else {
            if ($char.Key -ne "Enter") {
                $isChar = $false
                $userInput += $char.Key
                $charCount += 1
                
                # Test to see if it's a number - If it is we act differently
                # For some weird reason $key.char returns numbers with a 'D' prefixed...
                $userInputasInt = $userInput.Replace("D", "")  -as [int]
        
                if ($userInputasInt -eq $null) {
                    $isChar = $true
                }
            }
        }
        #TODO: how do I make it so I can change between 1 char inputs and a subreddit search?
    } while ((($charCount -lt 2) -and ($char.Key -ne "Enter") -and ($isChar -ne $true)))

    return $userInput 
}

function Subreddit-PromptText {
        # Clear whatever is already there...
        [System.Console]::SetCursorPosition(0, $RowsToDisplay + 1)
        $Text = (" " * $ScreenWidth)
        Write-Host $Text -NoNewline
    
        # And now print
        [System.Console]::SetCursorPosition(0, $RowsToDisplay + 1)
        Write-Host "Please enter the subreddit to search: " -NoNewline
}

Start-TerminalReddit