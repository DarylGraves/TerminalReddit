#TODO: Functions export: Don't include Truncate-String and Divide-Int
function Start-TerminalReddit {
    param(
        [String]
        $Subreddit
    )
    
    # Variables
    $TerminalX = [System.Console]::WindowWidth
    $TerminalY = [System.Console]::WindowHeight
    
    # Prepare Application
    #TODO: If Terminal is too small, don't start the application
    $CacheFolder = Init-Cache
    Clear-Host

    # Load subreddit if requested
    if ($Subreddit -ne "") {
        Get-RedditPage -Subreddit $Subreddit -TerminalX $TerminalX -TerminalY $TerminalY
    } 

    #TODO: Not happy with this. Have a switch statement here
    # Prompt for user interaction
    $CloseApp = $false
    do {
        $CloseApp = Start-Prompt -WindowWidth $TerminalX -WindowHeight $TerminalY
    } while ( $CloseApp -ne $True )
}


function Get-RedditPage {
    param (
        # Subreddit
        [String]
        $Subreddit,
        # Number of results to display
        [Int]
        $NumberOfResults = 26,
        [Int]
        $TerminalX,
        [Int]
        $TerminalY
    )
    
    # Variables
    $MaxCharsSubreddit = Divide-Int -Multiples 1 -Divisor 5 -IntToDivide ($TerminalX - 5)
    $MaxCharsWhiteSpace = $MaxCharsSubreddit + 1
    $MaxCharsTitle = Divide-Int -Multiples 4 -Divisor 5 -IntToDivide ($TerminalX - 5)

    # Retrieve data from Reddit
    if ($Subreddit -eq "") { $Subreddit = "popular" }
    try {
        $Page = Invoke-WebRequest -Uri "https://old.reddit.com/r/$Subreddit/.json"
       
    }
    catch {
        Write-Host "Error accessing this site" -ForegroundColor red
        return
    }

    # Manipulating the data just received
    $Page = $Page | ConvertFrom-Json
    $Links = $Page.Data.Children.Data
    if ($NumberOfResults -gt 99 ) { $NumberOfResults = 99 }
    if ($NumberOfResults -gt $Links.Count) { $NumberOfResults = $Links.Count }
    if ($NumberOfResults -gt $TerminalY) { $NumberOfResults = $TerminalY - 2 }

    # Display results and save them in a cache file
    for ($i = 0; $i -lt $NumberOfResults; $i++) {
        $Subreddit = Truncate-String -Text $Links.Subreddit_name_prefixed[$i] -NewSize $MaxCharsSubreddit
        $Title = Truncate-String -Text $Links.Title[$i] -NewSize $MaxCharsTitle
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

function Start-Prompt {
    param(
        [Int]
        $WindowWidth,
        [Int]
        $WindowHeight
    )

    [System.Console]::SetCursorPosition(0, $WindowHeight - 3)
    for ($i = 0; $i -lt $WindowWidth; $i++) {
        Write-Host "-" -NoNewline
    } 

    # Need this to pull screen into view, and then reset the cursor back.
    Write-Host " "
    [System.Console]::SetCursorPosition(0,$WindowHeight - 2)
    
    $validCommand = $false
    $char = ""
    $userInput = ""
    do {
        $userInput += $char
        $char = [System.Console]::Read()
    } while ([int]$char -ne 10)

    [System.Console]::SetCursorPosition(0, $WindowHeight - 2)
    
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
    $CacheFolder = $Env:APPDATA + "/PowershellTools/TerminalReddit"

    if ((Test-Path -Path $CacheFolder) -ne $True) {
        New-Item -Path $CacheFolder -ItemType Directory
    }

    return $CacheFolder
}

Start-TerminalReddit -Subreddit Powershell