$ErrorActionPreference = 'Stop'

$rootDir = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $PSScriptRoot 'platform-secrets.manifest'

if (-not (Test-Path $manifestPath)) {
    throw "Missing manifest $manifestPath"
}

$generatedFormats = @{}

function Resolve-Secret {
    param(
        [string]$EnvName,
        [string]$SecretName
    )

    $envValue = [Environment]::GetEnvironmentVariable($EnvName)
    if (-not [string]::IsNullOrWhiteSpace($envValue)) {
        return $envValue
    }

    $gcloud = Get-Command 'gcloud.cmd' -ErrorAction SilentlyContinue
    if ($null -ne $gcloud) {
        $value = & $gcloud.Source secrets versions access latest --secret=$SecretName
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to resolve $EnvName via gcloud secret $SecretName."
        }
        $value = ($value | Out-String).Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Secret $SecretName resolved to an empty value."
        }
        return $value
    }

    throw "Unable to resolve $EnvName. Set $EnvName or install gcloud to access secret $SecretName."
}

Get-Content $manifestPath | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) {
        return
    }

    $fields = $_.Split('|')
    if ($fields.Length -ne 5) {
        throw "Invalid manifest entry: $_"
    }

    $relativePath = $fields[0]
    $format = $fields[1]
    $outputKey = $fields[2]
    $envName = $fields[3]
    $secretName = $fields[4]

    if ($format -ne 'properties') {
        throw "Unsupported format $format in $manifestPath"
    }

    if ($generatedFormats.ContainsKey($relativePath)) {
        if ($generatedFormats[$relativePath] -ne $format) {
            throw "Conflicting formats for ${relativePath}: $($generatedFormats[$relativePath]) and $format"
        }
    } else {
        $generatedFormats[$relativePath] = $format
        $absolutePath = Join-Path $rootDir $relativePath
        $directory = Split-Path -Parent $absolutePath
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        Set-Content -Path $absolutePath -Value '' -NoNewline
    }

    $absolutePath = Join-Path $rootDir $relativePath
    $value = Resolve-Secret -EnvName $envName -SecretName $secretName
    Add-Content -Path $absolutePath -Value "$outputKey=$value"
}
