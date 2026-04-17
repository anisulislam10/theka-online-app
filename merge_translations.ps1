$jsonPath = "d:\TheekaOnline\assets\languages\translations.json"
$newJsonPath = "d:\TheekaOnline\missing_translations.json"

$currentJson = Get-Content $jsonPath -Raw | ConvertFrom-Json
$newTranslations = Get-Content $newJsonPath -Raw | ConvertFrom-Json

$currentHashtable = @{}

# Convert PSObject to Hashtable
$currentJson | Get-Member -MemberType NoteProperty | ForEach-Object {
    $currentHashtable[$_.Name] = $currentJson.$($_.Name)
}

# Add NEW translations
$newTranslations | Get-Member -MemberType NoteProperty | ForEach-Object {
    $key = $_.Name
    if (-not $currentHashtable.ContainsKey($key)) {
        $currentHashtable[$key] = $newTranslations.$key
    }
}

$finalJson = $currentHashtable | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($jsonPath, $finalJson)
