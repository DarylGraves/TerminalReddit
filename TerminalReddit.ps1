#TODO: Functions export: Don't include Truncate-String and Divide-Int
function Get-RedditPage {
    param (
        # Subreddit
        [Parameter(Mandatory=$false)]
        [String]
        $Subreddit,
        # Number of results to display
        [Parameter(Mandatory=$false)]
        [Int]
        $NumberOfResults = 26
    )
    
    # Variables
    #TODO: $UserData isn't Linux Compatible is it...
    $UserData = $Env:APPDATA + "\PowershellTools\TerminalReddit"
    $TerminalX = [System.Console]::WindowWidth
    $TerminalY = [System.Console]::WindowHeight
    $MaxCharsSubreddit = Divide-Int -Multiples 1 -Divisor 5 -IntToDivide ($TerminalX - 5)
    $MaxCharsWhiteSpace = $MaxCharsSubreddit + 1
    $MaxCharsTitle = Divide-Int -Multiples 4 -Divisor 5 -IntToDivide ($TerminalX - 5)

    Init-Cache -Path $UserData

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

    # Display results and save them in a cache file
    Clear-Host
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

    for ($i = 0; $i -lt $TerminalY - ($NumberOfResults + 1); $i++) {
        Write-Host " "
    }
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
    param (
        [String]
        $Path
    )
   
    if ((Test-Path -Path $Path) -ne $True) {
        New-Item -Path $Path -ItemType Directory
    }
}

Get-RedditPage 