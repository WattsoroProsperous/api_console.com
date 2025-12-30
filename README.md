# CheqPrint API - Projet de Test

Ce dossier contient des exemples pour tester l'API CheqPrint dans différents langages.

## Configuration

### 1. Obtenir une clé API

1. Ouvrez l'application CheqPrint sur votre appareil
2. Allez dans **Paramètres** > **Clés API**
3. Cliquez sur **Nouvelle clé API**
4. Donnez un nom (ex: "Test Local")
5. Sélectionnez les scopes nécessaires :
   - `read` - Pour lire les données
   - `print:write` - Pour imprimer des chèques
   - `companies:write` - Pour créer des sociétés
   - `cheque-books:write` - Pour gérer les carnets
6. Copiez la clé générée (elle ne sera plus visible après !)

### 2. Configurer la clé

Créez un fichier `.env` dans ce dossier :

```
API_KEY=sk_live_VOTRE_CLE_ICI
```

**IMPORTANT**: Ne partagez jamais votre clé API !

---

## Tests disponibles

### Python (`test_api.py`)

```bash
# Installer les dépendances
pip install requests python-dotenv

# Lancer les tests
python test_api.py
```

### JavaScript/Node.js (`test_api.js`)

```bash
# Installer les dépendances
npm install

# Lancer les tests
node test_api.js
```

### HTML (`test_api.html`)

Ouvrez simplement le fichier dans un navigateur web.
Entrez votre clé API dans le champ prévu.

### cURL (`test_api.sh`)

```bash
# Rendre exécutable
chmod +x test_api.sh

# Lancer (remplacez la clé)
API_KEY="sk_live_VOTRE_CLE" ./test_api.sh
```

### PowerShell (`test_api.ps1`)

```powershell
# Lancer
.\test_api.ps1 -ApiKey "sk_live_VOTRE_CLE"
```

---

## Endpoints de l'API

| Endpoint | Méthode | Description | Scopes requis |
|----------|---------|-------------|---------------|
| `/banks` | GET | Liste des banques disponibles | Aucun |
| `/templates` | GET | Templates de chèques | `read` |
| `/companies` | GET | Liste de vos sociétés | `read` |
| `/companies` | POST | Créer une société | `companies:write` |
| `/cheque-books` | GET | Liste des carnets | `read` |
| `/cheque-books` | POST | Créer un carnet | `cheque-books:write` |
| `/print-cheque` | POST | Imprimer un chèque | `print:write` |
| `/print-batch` | POST | Imprimer plusieurs chèques | `print:write` |
| `/print-history` | GET | Historique des impressions | `read` |

---

## Exemples de requêtes

### Imprimer un chèque

```json
POST /print-cheque
{
  "beneficiaire": "FOURNISSEUR ABC",
  "montant": "150000",
  "selectedBank": "CORIS BANK",
  "companyName": "MA SOCIETE",
  "lieu": "ABIDJAN",
  "date": "2025-01-15"
}
```

**Réponse :**
```json
{
  "success": true,
  "data": {
    "chequeNumber": 123,
    "beneficiaire": "FOURNISSEUR ABC",
    "montant": "150000",
    "montantEnLettres": "CENT CINQUANTE MILLE FRANCS CFA",
    "lieu": "ABIDJAN",
    "date": "2025-01-15"
  }
}
```

### Imprimer plusieurs chèques (batch)

```json
POST /print-batch
{
  "selectedBank": "CORIS BANK",
  "companyName": "MA SOCIETE",
  "cheques": [
    {"beneficiaire": "FOURNISSEUR A", "montant": "100000"},
    {"beneficiaire": "FOURNISSEUR B", "montant": "250000"},
    {"beneficiaire": "FOURNISSEUR C", "montant": "75000"}
  ]
}
```

### Créer un carnet de chèques

```json
POST /cheque-books
{
  "companyName": "MA SOCIETE",
  "bankName": "CORIS BANK",
  "firstChequeNumber": 1000001,
  "totalCheques": 50
}
```

---

## Codes d'erreur

| Code | Description |
|------|-------------|
| 400 | Requête invalide (données manquantes ou incorrectes) |
| 401 | Clé API invalide ou expirée |
| 402 | Plan expiré |
| 403 | Permissions insuffisantes (scope manquant) |
| 404 | Ressource non trouvée |
| 429 | Trop de requêtes (rate limit) |
| 500 | Erreur serveur |

---

## Banques disponibles

- `CORIS BANK`
- `BMS-CI`
- `NSIA`
- `GTBANK`

---

## Support

En cas de problème, vérifiez :
1. La clé API est valide et non expirée
2. Les scopes nécessaires sont activés
3. Un carnet de chèques actif existe pour la banque/société
4. Il reste des chèques dans le carnet
