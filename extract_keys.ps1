Get-ChildItem -Path lib -Filter *.dart -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    [regex]::Matches($content, "(['\""])([^'\""]+)\1\.tr") | ForEach-Object {
        $_.Groups[2].Value
    }
} | Sort-Object -Unique | Out-File -FilePath unique_keys.txt -Encoding utf8
