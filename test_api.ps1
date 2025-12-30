<#
.SYNOPSIS
    CheqPrint API - Script de test PowerShell

.DESCRIPTION
    Script pour tester tous les endpoints de l'API CheqPrint

.PARAMETER ApiKey
    Votre clé API CheqPrint (sk_live_... ou sk_test_...)

.EXAMPLE
    .\test_api.ps1 -ApiKey "sk_live_VOTRE_CLE"

.EXAMPLE
    $env:API_KEY = "sk_live_VOTRE_CLE"
    .\test_api.ps1
#>

param(
    [Parameter()]
    [string]$ApiKey = $env:API_KEY
)

# Configuration
$BaseUrl = "https://xwpgblfdmlrrkksmuazy.supabase.co/functions/v1"

# Fonctions d'affichage
function Write-Header($text) {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Blue
    Write-Host "  $text" -ForegroundColor Blue
    Write-Host ("=" * 60) -ForegroundColor Blue
    Write-Host ""
}

function Write-Success($text) {
    Write-Host "✓ $text" -ForegroundColor Green
}

function Write-Error($text) {
    Write-Host "✗ $text" -ForegroundColor Red
}

function Write-Info($text) {
    Write-Host "→ $text" -ForegroundColor Yellow
}

# Fonction pour faire les requêtes
function Invoke-ApiRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [bool]$Auth = $true
    )

    $url = "$BaseUrl/$Endpoint"
    $headers = @{
        "Content-Type" = "application/json"
    }

    if ($Auth -and $ApiKey) {
        $headers["Authorization"] = "Bearer $ApiKey"
    }

    try {
        $params = @{
            Uri = $url
            Method = $Method
            Headers = $headers
            ContentType = "application/json"
        }

        if ($Body) {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }

        $response = Invoke-RestMethod @params
        return @{
            Success = $true
            Data = $response
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        try {
            $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
        }
        catch {
            $errorBody = @{ error = $errorMessage }
        }
        return @{
            Success = $false
            Data = $errorBody
        }
    }
}

# Tests
function Test-Banks {
    Write-Info "GET /banks - Liste des banques disponibles"

    $result = Invoke-ApiRequest -Method "GET" -Endpoint "banks" -Auth $false

    if ($result.Success) {
        $banks = $result.Data.data
        Write-Success "Trouvé $($banks.Count) banque(s)"
        foreach ($bank in $banks[0..4]) {
            Write-Host "   - $($bank.name ?? $bank.code ?? 'N/A')"
        }
    }
    else {
        Write-Error "Erreur: $($result.Data | ConvertTo-Json)"
    }

    return $result.Success
}

function Test-Templates {
    Write-Info "GET /templates - Templates de chèques"

    $result = Invoke-ApiRequest -Method "GET" -Endpoint "templates"

    if ($result.Success) {
        $templates = $result.Data.data
        Write-Success "Trouvé $($templates.Count) template(s)"
    }
    else {
        Write-Error "Erreur: $($result.Data | ConvertTo-Json)"
    }

    return $result.Success
}

function Test-Companies {
    Write-Info "GET /companies - Vos sociétés"

    $result = Invoke-ApiRequest -Method "GET" -Endpoint "companies"

    if ($result.Success) {
        $companies = $result.Data.data
        Write-Success "Trouvé $($companies.Count) société(s)"
        foreach ($company in $companies[0..4]) {
            Write-Host "   - $($company.name ?? 'N/A')"
        }
        return $companies
    }
    else {
        Write-Error "Erreur: $($result.Data | ConvertTo-Json)"
        return @()
    }
}

function Test-ChequeBooks {
    Write-Info "GET /cheque-books - Vos carnets de chèques"

    $result = Invoke-ApiRequest -Method "GET" -Endpoint "cheque-books"

    if ($result.Success) {
        $books = $result.Data.data
        Write-Success "Trouvé $($books.Count) carnet(s)"
        foreach ($book in $books[0..4]) {
            $remaining = ($book.totalCheques ?? 0) - ($book.usedCheques ?? 0)
            $status = if ($book.isActive) { "actif" } else { "inactif" }
            Write-Host "   - $($book.companyName) / $($book.bankName) ($remaining restants, $status)"
        }
        return $books
    }
    else {
        Write-Error "Erreur: $($result.Data | ConvertTo-Json)"
        return @()
    }
}

function Test-PrintHistory {
    Write-Info "GET /print-history - Historique des impressions"

    $result = Invoke-ApiRequest -Method "GET" -Endpoint "print-history?limit=5"

    if ($result.Success) {
        $data = $result.Data.data
        $records = $data.records
        $total = $data.total
        Write-Success "Total: $total impression(s)"
        foreach ($record in $records[0..4]) {
            Write-Host "   - Chèque #$($record.chequeNumber) : $($record.beneficiary) - $($record.amount) FCFA"
        }
    }
    else {
        Write-Error "Erreur: $($result.Data | ConvertTo-Json)"
    }

    return $result.Success
}

function Test-PrintCheque($companyName, $bankName) {
    Write-Info "POST /print-cheque - Imprimer un chèque"

    $body = @{
        beneficiaire = "TEST API POWERSHELL"
        montant = "345678"
        selectedBank = $bankName
        companyName = $companyName
        lieu = "ABIDJAN"
    }

    Write-Host "   Données:" ($body | ConvertTo-Json)

    $result = Invoke-ApiRequest -Method "POST" -Endpoint "print-cheque" -Body $body

    if ($result.Success) {
        $cheque = $result.Data.data
        Write-Success "Chèque imprimé avec succès!"
        Write-Host "   Numéro: $($cheque.chequeNumber)"
        Write-Host "   Montant en lettres: $($cheque.montantEnLettres)"
    }
    else {
        Write-Error "Erreur: $($result.Data | ConvertTo-Json)"
    }

    return $result.Success
}

function Test-PrintBatch($companyName, $bankName) {
    Write-Info "POST /print-batch - Imprimer plusieurs chèques"

    $body = @{
        selectedBank = $bankName
        companyName = $companyName
        cheques = @(
            @{ beneficiaire = "BATCH PS 1"; montant = "70000" },
            @{ beneficiaire = "BATCH PS 2"; montant = "95000" }
        )
    }

    Write-Host "   Nombre de chèques: $($body.cheques.Count)"

    $result = Invoke-ApiRequest -Method "POST" -Endpoint "print-batch" -Body $body

    if ($result.Success) {
        $batch = $result.Data.data
        Write-Success "Lot imprimé: $($batch.totalProcessed) chèques"
        Write-Host "   Montant total: $($batch.totalAmount) FCFA"
        foreach ($cheque in $batch.cheques) {
            Write-Host "   - #$($cheque.chequeNumber): $($cheque.beneficiaire) - $($cheque.montant) FCFA"
        }
    }
    else {
        Write-Error "Erreur: $($result.Data | ConvertTo-Json)"
    }

    return $result.Success
}

# Main
Write-Header "CheqPrint API - Tests PowerShell"

# Vérifier la clé API
if (-not $ApiKey) {
    Write-Error "Clé API non configurée!"
    Write-Info "Usage: .\test_api.ps1 -ApiKey 'sk_live_VOTRE_CLE'"
    Write-Info "Ou: `$env:API_KEY = 'sk_live_VOTRE_CLE'"
    exit 1
}

Write-Info "Clé API: $($ApiKey.Substring(0, 20))..."
Write-Info "URL: $BaseUrl"

# Tests de lecture
Write-Header "Tests de lecture"

Test-Banks | Out-Null
Test-Templates | Out-Null
$companies = Test-Companies
$books = Test-ChequeBooks
Test-PrintHistory | Out-Null

# Trouver un carnet actif
$activeBook = $null
foreach ($book in $books) {
    if ($book.isActive) {
        $remaining = ($book.totalCheques ?? 0) - ($book.usedCheques ?? 0)
        if ($remaining -ge 3) {
            $activeBook = $book
            break
        }
    }
}

if ($activeBook) {
    Write-Header "Tests d'écriture"
    Write-Info "Utilisation du carnet: $($activeBook.companyName) / $($activeBook.bankName)"

    $response = Read-Host "`n⚠️  Ces tests vont consommer des numéros de chèques. Continuer? (o/N)"

    if ($response -eq 'o') {
        Test-PrintCheque $activeBook.companyName $activeBook.bankName | Out-Null
        Test-PrintBatch $activeBook.companyName $activeBook.bankName | Out-Null
    }
    else {
        Write-Info "Tests d'écriture ignorés"
    }
}
else {
    Write-Header "Tests d'écriture"
    Write-Error "Aucun carnet actif avec assez de chèques trouvé"
    Write-Info "Créez un carnet de chèques dans l'app CheqPrint"
}

Write-Header "Tests terminés"
