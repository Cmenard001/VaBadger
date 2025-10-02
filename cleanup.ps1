# Script de nettoyage pour VaBadger
# Supprime la tache planifiee creee par config.ps1

# Verifier les droits administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host "Verification des droits administrateur: $isAdmin" -ForegroundColor Gray

if (-not $isAdmin) {
    Write-Host "Ce script necessite des droits administrateur pour supprimer une tache planifiee." -ForegroundColor Yellow
    Write-Host "Demande d'elevation des privileges..." -ForegroundColor Cyan
    Write-Host ""

    # Relancer le script en mode administrateur
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    } catch {
        Write-Host "Erreur: Impossible d'obtenir les droits administrateur." -ForegroundColor Red
        Write-Host "Veuillez relancer PowerShell en tant qu'administrateur manuellement." -ForegroundColor Yellow
        pause
        exit 1
    }
}

Write-Host "=== Nettoyage de VaBadger ===" -ForegroundColor Cyan
Write-Host ""

# Nom de la tache creee par config.ps1
$taskName = "VaBadger_DailyAlert"

# Verifier si la tache existe
Write-Host "Recherche de la tache planifiee '$taskName'..." -ForegroundColor Yellow
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "Tache trouvee!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Details de la tache:" -ForegroundColor Cyan
    Write-Host "  - Nom: $($existingTask.TaskName)" -ForegroundColor White
    Write-Host "  - Etat: $($existingTask.State)" -ForegroundColor White
    Write-Host "  - Description: $($existingTask.Description)" -ForegroundColor White
    Write-Host ""

    # Demander confirmation
    $confirmation = Read-Host "Voulez-vous supprimer cette tache? (O/N)"

    if ($confirmation -eq 'O' -or $confirmation -eq 'o') {
        try {
            Write-Host ""
            Write-Host "Suppression de la tache planifiee..." -ForegroundColor Yellow
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop

            # Verifier que la tache a bien ete supprimee
            Start-Sleep -Milliseconds 500
            $verifyTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

            if (-not $verifyTask) {
                Write-Host ""
                Write-Host "Tache planifiee supprimee avec succes!" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "Avertissement: La tache semble toujours exister." -ForegroundColor Yellow
            }
        } catch {
            Write-Host ""
            Write-Host "Erreur lors de la suppression de la tache:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            pause
            exit 1
        }
    } else {
        Write-Host ""
        Write-Host "Suppression annulee." -ForegroundColor Yellow
    }
} else {
    Write-Host "Aucune tache planifiee '$taskName' trouvee." -ForegroundColor Yellow
    Write-Host "La tache a peut-etre deja ete supprimee ou n'a jamais ete creee." -ForegroundColor Gray
}

Write-Host ""
pause
