$ErrorActionPreference = 'Stop'
$taskRun = 'C:\Users\semin5\IdeaProjects\danjeolha-pet\run-20261018'
$taskTarget = 'C:\Users\semin5\.codex\pets\danjeolha'
$taskRequiredChecks = @{
    'qa\review.json' = 'ok'
    'final\validation-extended.json' = 'ok'
    'qa\chroma-despill-extended.json' = 'ok'
    'qa\direction-blind-validation.json' = 'ok'
    'qa\direction-semantics.json' = 'approved'
    'qa\standard-visual-review.json' = 'approved_all9'
    'qa\final-visual-review.json' = 'approved'
}
foreach ($taskCheck in $taskRequiredChecks.GetEnumerator()) {
    $taskData = Get-Content -LiteralPath (Join-Path $taskRun $taskCheck.Key) -Raw | ConvertFrom-Json
    if ($taskData.($taskCheck.Value) -ne $true) { throw ('QA gate failed: ' + $taskCheck.Key) }
}
$taskSemantics = Get-Content -LiteralPath ($taskRun + '\qa\direction-semantics.json') -Raw | ConvertFrom-Json
if ($taskSemantics.directions.Count -ne 16 -or @($taskSemantics.directions | Where-Object verdict -eq 'fail').Count -gt 0) { throw 'Incomplete or failed direction semantics' }
$taskStagedHash = (Get-FileHash -LiteralPath ($taskRun + '\final\spritesheet-extended.webp') -Algorithm SHA256).Hash
$taskBlindKey = Get-Content -LiteralPath ($taskRun + '\qa\direction-blind-answer-key.json') -Raw | ConvertFrom-Json
if ($taskBlindKey.atlas_sha256 -ne $taskStagedHash -or $taskSemantics.atlas_sha256 -ne $taskStagedHash) { throw 'Final atlas differs from independently reviewed atlas' }
$taskMetadata = Get-Content -LiteralPath ($taskRun + '\final\pet.json') -Raw | ConvertFrom-Json
if ($taskMetadata.id -ne 'danjeolha' -or $taskMetadata.displayName -ne '단절하' -or $taskMetadata.spriteVersionNumber -ne 2) { throw 'Unexpected pet identity/version' }
$taskPreserved = Get-Content -LiteralPath ($taskRun + '\qa\preserved-pets.json') -Raw | ConvertFrom-Json
foreach ($taskEntry in $taskPreserved.files.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath $taskEntry.Name -Algorithm SHA256).Hash -ne $taskEntry.Value) { throw ('Existing pet changed: ' + $taskEntry.Name) }
}
if (Test-Path -LiteralPath $taskTarget) { throw 'Pet target already exists; refusing overwrite' }
if ([System.IO.Path]::GetFullPath($taskTarget) -ne 'C:\Users\semin5\.codex\pets\danjeolha') { throw 'Unexpected install target' }
New-Item -ItemType Directory -Path $taskTarget | Out-Null
Copy-Item -LiteralPath ($taskRun + '\final\pet.json') -Destination ($taskTarget + '\pet.json')
Copy-Item -LiteralPath ($taskRun + '\final\spritesheet-extended.webp') -Destination ($taskTarget + '\spritesheet.webp')
$taskExpectedHash = (Get-FileHash -LiteralPath ($taskRun + '\final\spritesheet-extended.webp') -Algorithm SHA256).Hash
if ((Get-FileHash -LiteralPath ($taskTarget + '\spritesheet.webp') -Algorithm SHA256).Hash -ne $taskExpectedHash) { throw 'Installed atlas hash mismatch' }
foreach ($taskEntry in $taskPreserved.files.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath $taskEntry.Name -Algorithm SHA256).Hash -ne $taskEntry.Value) { throw ('Existing pet changed: ' + $taskEntry.Name) }
}
[pscustomobject]@{installed=$true;path=$taskTarget;sha256=$taskExpectedHash;existingPetsUnchanged=$true;automaticallySelected=$false} | ConvertTo-Json
