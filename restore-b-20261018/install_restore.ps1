$ErrorActionPreference='Stop'
$taskRun='C:\Users\semin5\IdeaProjects\danjeolha-pet\restore-b-20261018'
$taskTarget='C:\Users\semin5\.codex\pets\danjeolha'
foreach($taskCheck in @('qa\restore-proof.json','final\validation.json')){
 $taskData=Get-Content -LiteralPath (Join-Path $taskRun $taskCheck) -Raw|ConvertFrom-Json
 if($taskData.ok -ne $true){throw ('Gate failed '+$taskCheck)}
}
$taskReview=Get-Content -LiteralPath ($taskRun+'\qa\independent-restore-review.json') -Raw|ConvertFrom-Json
if($taskReview.approved -ne $true){throw 'Independent restore review failed'}
$taskStagedHash=(Get-FileHash -LiteralPath ($taskRun+'\final\spritesheet.webp') -Algorithm SHA256).Hash
if($taskStagedHash -ne $taskReview.final_sha256){throw 'Reviewed file differs'}
$taskMetadata=Get-Content -LiteralPath ($taskRun+'\final\pet.json') -Raw|ConvertFrom-Json
if($taskMetadata.id -ne 'danjeolha' -or $taskMetadata.displayName -ne '단절하' -or $taskMetadata.spriteVersionNumber -ne 2){throw 'Not expected B package'}
foreach($taskName in @('pet.json','spritesheet.webp')){
 if((Get-FileHash -LiteralPath (Join-Path $taskTarget $taskName) -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath (Join-Path ($taskRun+'\backup-A') $taskName) -Algorithm SHA256).Hash){throw 'Pet changed since A snapshot'}
}
$taskOtherPets=Get-Content -LiteralPath 'C:\Users\semin5\IdeaProjects\danjeolha-pet\run-20261018\qa\preserved-pets.json' -Raw|ConvertFrom-Json
foreach($taskEntry in $taskOtherPets.files.PSObject.Properties){if((Get-FileHash -LiteralPath $taskEntry.Name -Algorithm SHA256).Hash -ne $taskEntry.Value){throw 'Other pet changed'}}
try{
 Copy-Item -LiteralPath ($taskRun+'\final\spritesheet.webp') -Destination ($taskTarget+'\spritesheet.webp') -Force
 Copy-Item -LiteralPath ($taskRun+'\final\pet.json') -Destination ($taskTarget+'\pet.json') -Force
 if((Get-FileHash -LiteralPath ($taskTarget+'\spritesheet.webp') -Algorithm SHA256).Hash -ne $taskStagedHash){throw 'Installed hash mismatch'}
}catch{
 Copy-Item -LiteralPath ($taskRun+'\backup-A\spritesheet.webp') -Destination ($taskTarget+'\spritesheet.webp') -Force
 Copy-Item -LiteralPath ($taskRun+'\backup-A\pet.json') -Destination ($taskTarget+'\pet.json') -Force
 throw
}
foreach($taskEntry in $taskOtherPets.files.PSObject.Properties){if((Get-FileHash -LiteralPath $taskEntry.Name -Algorithm SHA256).Hash -ne $taskEntry.Value){throw 'Other pet changed'}}
[pscustomobject]@{installed=$true;mode='B';spriteVersionNumber=2;lookDirections=16;armFixPreserved=$true;sha256=$taskStagedHash;otherPetsUnchanged=$true;backupA=($taskRun+'\backup-A')}|ConvertTo-Json
