#TODO: Functions export: Don't include anything other than Start-TerminalReddit
function Start-TerminalReddit {
    param(
        [String]
        $Subreddit,
        [Int]
        $NoOfPosts = 1000
    )
    
    # Variables
    $Global:TerminalX = [System.Console]::WindowWidth
    $Global:TerminalY = [System.Console]::WindowHeight
    $Global:CacheFolder = $Env:APPDATA + "/PowershellTools/TerminalReddit"
    $Global:PostsQueryLimit = $NoOfPosts
    $Global:SiteContent = $null
    $Global:PostToStartFrom = 0
    $Global:SubRedditPrompt = "(N)ext, (P)revious, (S)ubreddit, enter a Post Number or (Q)uit: " 

    # If Terminal is too small, don't start the application
    # 53 is the longest string hard coded - "(N)ext, (P)revious, etc"
    if (($TerminalX -lt 53) -or $TerminalY -lt 10) {
        Write-Host "Window too small!" -ForegroundColor Red
        Return
    }

    # Prepare Application
    Clear-Host
    $ProgressPreference = "SilentlyContinue" # No Progress Bar on Web Requests
    Init-Cache

    # Load a subreddit if passed through as an argument
    if ($Subreddit -ne "") {
        Get-RedditPage -Subreddit $Subreddit
    }
    else {
        Init-Prompt
    } 

    # Prompt for user interaction
    $closingApp = $false
    do {
        $userInput = Start-Prompt
        Clear-Prompt
        
        # For some weird reason $key.char returns numbers with a 'D' prefixed...
        $userInputasInt = $userInput.Replace("D", "")  -as [int]
        
        if ($userInputasInt -ne $null) {
            #TODO: Open an actual Reddit Post
        }
        else {
            if ($userInput.Length -eq 1) {
                switch ($userInput[0]) {
                    "N" { Get-RedditPage -Subreddit $Subreddit}
                    "P" {}
                    "Q" { $closeApp = $True }
                    Default {}
                }
            }
        }
    } while ( $closeApp -ne $True )

    Clear-Host
}


function Get-RedditPage {
    param (
        # Subreddit
        [String]
        $Subreddit,
        # Number of results to display
        [Int]
        $NumberOfResults = 26
    )
    
    # Retrieve data from Reddit
    if ($Subreddit -eq "") { $Subreddit = "popular" }
    try {
        $Page = Invoke-WebRequest -Uri "https://old.reddit.com/r/$Subreddit/.json?limit=$PostsQueryLimit"
        
    }
    catch {
        Write-Host "Error accessing this site" -ForegroundColor red
        return
    }
    
    # Manipulating the data just received
    $Page = $Page | ConvertFrom-Json
    $Global:SiteContent = $Page.Data.Children.Data

    Display-SubredditContent
    Init-Prompt
}

function Display-SubredditContent {
    # Variables
    $MaxCharsSubreddit = Divide-Int -Multiples 1 -Divisor 5 -IntToDivide ($TerminalX - 5)
    $MaxCharsWhiteSpace = $MaxCharsSubreddit + 1
    $MaxCharsTitle = Divide-Int -Multiples 4 -Divisor 5 -IntToDivide ($TerminalX - 5)
    
    # Reset cursor
    [System.Console]::SetCursorPosition(0,0)
    
    $NumberOfResults = $TerminalY - 3
    if ($NumberOfResults -gt $SiteContent.Count) { $NumberOfResults = $SiteContent.Count }

    # Display results
    for ($i = $PostToStartFrom; $i -lt $NumberOfResults; $i++) {
        $Subreddit = Truncate-String -Text $SiteContent.Subreddit_name_prefixed[$i] -NewSize $MaxCharsSubreddit
        $Title = Truncate-String -Text $SiteContent.Title[$i] -NewSize $MaxCharsTitle
        $NoOfSpaces = $MaxCharsWhiteSpace - $Subreddit.Length

        Write-Host [$i] -ForegroundColor Blue         -NoNewline
        if ($i -lt 10) { Write-Host " "               -NoNewline }            
        Write-Host $Subreddit -ForegroundColor Yellow -NoNewline
        Write-Host (" " * $NoOfSpaces)                -NoNewline
        Write-Host $Title -ForegroundColor Green
    }
    
    $PostToStartFrom = $PostToStartFrom + $NumberOfResults

    for ($i = 0; $i -lt ($TerminalY - $NumberOfResults - 3); $i++) {
        Write-Host ""
    }
}

function Init-Prompt {
    [System.Console]::SetCursorPosition(0, $TerminalY - 3)
    for ($i = 0; $i -lt $TerminalX; $i++) {
        Write-Host "-" -NoNewline
    } 

    [System.Console]::SetCursorPosition(0,$TerminalY -2)
    Write-Host $SubRedditPrompt -NoNewline
}

function Clear-Prompt {
    [System.Console]::SetCursorPosition(0,$TerminalY - 2)
    Write-Host (" " * $TerminalX)
    Init-Prompt       
}

function Start-Prompt {
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
        # 53 is the count for the "(N)ext, (P)revious etc..."
    } while (($charCount -lt ($TerminalX - $SubRedditPrompt.Length)) -and ($char.Key -ne "Enter"))

    return $userInput
}

function Truncate-String {
    param (
        [String]
        $Text,
        [Int]
        $NewSize,
        [Bool]
        $Trailoff = $False
    )
   
    if ($Text.Length -gt $NewSize)
    {
        $Text = $Text.Substring(0, $NewSize - 3)
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

function Init-Cache {
    if ((Test-Path -Path $CacheFolder) -ne $True) {
        New-Item -Path $CacheFolder -ItemType Directory
    }
}

Start-TerminalReddit -Subreddit Powershell