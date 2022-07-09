function Start-TerminalReddit {
    param (
    )
    
    $Global:ScreenWidth = [System.Console]::BufferWidth
    $Global:ScreenHeight = [System.Console]::BufferHeight
    $Global:BorderPosition = 3
   
    if (($ScreenWidth -lt 58) -or ($ScreenHeight -lt 30)) {
        Write-Host "Screen too small" -ForegroundColor Red
        Return
    }

    # On Startup, always load /r/popular
    Create-Borders
    $Posts = Get-RedditPosts -Subreddit "popular"
    Display-RedditPosts -Posts $Posts -StartNumber 0 -NumberToDisplay ($ScreenWidth - $BorderPosition)

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
                    "S" {} #TODO: Search
                    "R" {} #TODO: Refresh
                    "N" {} #TODO: Next
                    "P" {} #TODO: Previous
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
        $WebRequest = Invoke-WebRequest -Uri "https://old.reddit.com/r/$Subreddit/.json?limit=1000"
    }
    catch {
        #TODO: Invalid website? Close app or just return nothing?
    }

    $Posts = $WebRequest.Content | ConvertFrom-Json
    Return $Posts
}

function Display-RedditPosts {
    param (
        [PSCustomObject]$Posts,
        [Int]$NumberToDisplay,
        [Int]$StartNumber = 0,
        [Bool]$Gui = $True
    )
    
    if ($Gui) {
        [System.Console]::SetCursorPosition(0, 0)
    }

    # Variables
    $MaxCharsSubreddit = Divide-Int -Multiples 1 -Divisor 5 -IntToDivide ($ScreenWidth - 5)
    $MaxCharsWhiteSpace = $MaxCharsSubreddit + 1
    $MaxCharsTitle = Divide-Int -Multiples 4 -Divisor 5 -IntToDivide ($ScreenWidth - 5)

    for ($i = 0; $i -lt $Posts.data.children.Count; $i++) {
        $Number = if ($i -lt 10) { "[$i ]" } else { "[$i]" }
        $Subreddit = Truncate-String -Text $Posts.data.children[$i].data.Subreddit -NewSize $MaxCharsSubreddit
        $Title = Truncate-String -Text $Posts.data.children[$i].data.title -NewSize $MaxCharsTitle
        
        #TODO: Display-RedditPosts: Ability for user to change colours
        #TODO: Display-RedditPosts: If the subreddit name varies in length, column should still be the same width... (example of this is loading popular)
        Write-Host "$Number " -ForegroundColor Blue -NoNewline
        Write-Host "$Subreddit " -ForegroundColor Yellow -NoNewline
        Write-Host $Title -ForegroundColor Green
    }

    Cursor-ToBottom
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
    Write-Host "(S)earch, (R)efresh, (N)ext, (P)rev, (Q)uit or post number: " -NoNewline
    #TODO: Set-PromptText - Highlight options in a different colour?
}

function Get-UserInput {
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
                $userInput += $char.Key
                $charCount += 1
            }
        }
    } while (($charCount -lt 5) -and ($char.Key -ne "Enter"))

    return $userInput 
}

Start-TerminalReddit