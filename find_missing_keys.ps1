$jsonPath = "d:\TheekaOnline\assets\languages\translations.json"
$keysPath = "d:\TheekaOnline\unique_keys.txt"

$jsonContent = Get-Content $jsonPath -Raw | ConvertFrom-Json
$jsonKeys = $jsonContent | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

$usedKeys = Get-Content $keysPath

$missingKeys = $usedKeys | Where-Object { $_ -notin $jsonKeys }

$missingKeys | Out-File -FilePath missing_keys.txt -Encoding utf8
Write-Host "Found $($missingKeys.Count) missing keys."
