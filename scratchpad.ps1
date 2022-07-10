$Site = Invoke-WebRequest "https://old.reddit.com/r/IdiotsInCars/comments/vv7pbp/guy_takes_1300_horsepower_car_on_public_streets/.json"

$Json = $Site.Content | ConvertFrom-Json

$Comments = $Json.Data[1].children[0].data.body
$Name = $Json.Data[1].children[0].data.name
$UpVotes = $Json.Data[1].children[0].data.ups
Write-Host "$Name($UpVotes) - $Comments"
#$ReplyToAComment = $Json.Data.children[0].data.replies.data.children[0].data.body