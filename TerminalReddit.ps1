function Start-TerminalReddit {
    param (
    )
    
    $Global:ScreenWidth = [System.Console]::BufferWidth
    $Global:ScreenHeight = [System.Console]::BufferHeight
   
    if (($ScreenWidth -lt 58) -or ($ScreenHeight -lt 30)) {
        Write-Host "Screen too small" -ForegroundColor Red
        Return
    }
    Clear-MainWindow
    Get-RedditPosts -Subreddit "powershell"
    Prepare-Prompt

    while ($True) {
       #Something here 
    }
}

function Create-Borders {
    [System.Console]::SetCursorPosition(0, $ScreenHeight - 3)
    
    $Border = "_" * $ScreenWidth
    Write-Host $Border
}

function Get-RedditPosts {
    param (
        [String]$Subreddit = "popular"
    )
    
    try {
        $WebRequest = Invoke-WebRequest -Uri "https://old.reddit.com/r/$Subreddit/.json"
    }
    catch {
        #TODO: Invalid website? Close app or just return nothing?
    }

    $Posts = $WebRequest.Content | ConvertFrom-Json
    Display-RedditPosts -Posts $Posts
}

function Display-RedditPosts {
    param (
        [PSCustomObject]$Posts,
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
        
        #TODO: Ability for user to change colours
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

function Clear-MainWindow {
    Clear-Host
    Create-Borders
}

function Cursor-ToBottom {
    [System.Console]::SetCursorPosition(0, $ScreenHeight - 2)
}

function Prepare-Prompt {
    Write-Host "(R)efresh, (N)ext, (P)rev or type a number: " -NoNewline    
}
Start-TerminalReddit