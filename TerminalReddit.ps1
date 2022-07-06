#TODO: Functions export: Don't include Truncate-String and Divide-Int
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
    
    #TODO: If Terminal is too small, don't start the application
    if (($TerminalX -lt 20) -or $TerminalY -lt 10) {
        Write-Host "Window too small!" -ForegroundColor Red
        Return
    }

    # Prepare Application
    Clear-Host
    Init-Cache
    Init-Prompt 

    # Load a subreddit if passed through as an argument
    if ($Subreddit -ne "") {
        Get-RedditPage -Subreddit $Subreddit
    } 

    #TODO: Not happy with this. Have a switch statement here
    # Prompt for user interaction
    $CloseApp = $false
    do {
        $CloseApp = Start-Prompt
    } while ( $CloseApp -ne $True )
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
}

function Display-SubredditContent {
    # Variables
    $MaxCharsSubreddit = Divide-Int -Multiples 1 -Divisor 5 -IntToDivide ($TerminalX - 5)
    $MaxCharsWhiteSpace = $MaxCharsSubreddit + 1
    $MaxCharsTitle = Divide-Int -Multiples 4 -Divisor 5 -IntToDivide ($TerminalX - 5)
    
    # Reset cursor
    [System.Console]::SetCursorPosition(0,0)
    
    $NumberOfResults = 1000
    if ($NumberOfResults -gt 99 ) { $NumberOfResults = 99 }
    if ($NumberOfResults -gt $SiteContent.Count) { $NumberOfResults = $SiteContent.Count }
    if ($NumberOfResults -gt $TerminalY) { $NumberOfResults = $TerminalY - 3 }

    # Display results and save them in a cache file
    for ($i = 0; $i -lt $NumberOfResults; $i++) {
        $Subreddit = Truncate-String -Text $SiteContent.Subreddit_name_prefixed[$i] -NewSize $MaxCharsSubreddit
        $Title = Truncate-String -Text $SiteContent.Title[$i] -NewSize $MaxCharsTitle
        $NoOfSpaces = $MaxCharsWhiteSpace - $Subreddit.Length

        Write-Host [$i] -ForegroundColor Blue         -NoNewline
        if ($i -lt 10) { Write-Host " "               -NoNewline }            
        Write-Host $Subreddit -ForegroundColor Yellow -NoNewline
        Write-Host (" " * $NoOfSpaces)                -NoNewline
        Write-Host $Title -ForegroundColor Green
    }

    for ($i = 0; $i -lt ($TerminalY - $NumberOfResults - 3); $i++) {
        Write-Host ""
    }
}

function Init-Prompt {
    [System.Console]::SetCursorPosition(0, $TerminalY - 3)
    for ($i = 0; $i -lt $TerminalX; $i++) {
        Write-Host "-" -NoNewline
    } 

    # Need this to pull screen into view, and then reset the cursor back.
    Write-Host " "
    [System.Console]::SetCursorPosition(0,$TerminalY - 2)
}

function Start-Prompt {
    $validCommand = $false
    $char = ""
    $userInput = ""
    do {
        $userInput += $char
        $char = [System.Console]::Read()
    } while ([int]$char -ne 10)

    [System.Console]::SetCursorPosition(0, $TerminalY - 2)
    
    Write-Host "x" -NoNewline -ForegroundColor Red
    return $false
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