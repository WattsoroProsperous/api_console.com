#!/usr/bin/env python3
"""
CheqPrint API - Script de test Python
======================================

Usage:
    1. Créez un fichier .env avec votre clé API:
       API_KEY=sk_live_VOTRE_CLE

    2. Installez les dépendances:
       pip install requests python-dotenv

    3. Lancez le script:
       python test_api.py
"""

import os
import json
import requests
from datetime import datetime

# Essayer de charger python-dotenv si disponible
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

# Configuration
BASE_URL = "https://xwpgblfdmlrrkksmuazy.supabase.co/functions/v1"
API_KEY = os.getenv("API_KEY", "")

# Couleurs pour le terminal
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}  {text}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*60}{Colors.RESET}\n")

def print_success(text):
    print(f"{Colors.GREEN}✓ {text}{Colors.RESET}")

def print_error(text):
    print(f"{Colors.RED}✗ {text}{Colors.RESET}")

def print_info(text):
    print(f"{Colors.YELLOW}→ {text}{Colors.RESET}")

def make_request(method, endpoint, data=None, auth=True):
    """Effectue une requête à l'API"""
    url = f"{BASE_URL}/{endpoint}"
    headers = {"Content-Type": "application/json"}

    if auth and API_KEY:
        headers["Authorization"] = f"Bearer {API_KEY}"

    try:
        if method == "GET":
            response = requests.get(url, headers=headers)
        elif method == "POST":
            response = requests.post(url, headers=headers, json=data)
        else:
            raise ValueError(f"Méthode non supportée: {method}")

        return {
            "status": response.status_code,
            "data": response.json() if response.text else {},
            "success": response.status_code < 400
        }
    except requests.exceptions.RequestException as e:
        return {
            "status": 0,
            "data": {"error": str(e)},
            "success": False
        }

def test_banks():
    """Test 1: Liste des banques (sans authentification)"""
    print_info("GET /banks - Liste des banques disponibles")

    result = make_request("GET", "banks", auth=False)

    if result["success"]:
        banks = result["data"].get("data", [])
        print_success(f"Trouvé {len(banks)} banque(s)")
        for bank in banks[:5]:  # Afficher max 5
            print(f"   - {bank.get('name', bank.get('code', 'N/A'))}")
    else:
        print_error(f"Erreur: {result['data']}")

    return result["success"]

def test_templates():
    """Test 2: Liste des templates"""
    print_info("GET /templates - Templates de chèques")

    result = make_request("GET", "templates")

    if result["success"]:
        templates = result["data"].get("data", [])
        print_success(f"Trouvé {len(templates)} template(s)")
    else:
        print_error(f"Erreur: {result['data']}")

    return result["success"]

def test_companies():
    """Test 3: Liste des sociétés"""
    print_info("GET /companies - Vos sociétés")

    result = make_request("GET", "companies")

    if result["success"]:
        companies = result["data"].get("data", [])
        print_success(f"Trouvé {len(companies)} société(s)")
        for company in companies[:5]:
            print(f"   - {company.get('name', 'N/A')}")
        return companies
    else:
        print_error(f"Erreur: {result['data']}")
        return []

def test_cheque_books():
    """Test 4: Liste des carnets de chèques"""
    print_info("GET /cheque-books - Vos carnets de chèques")

    result = make_request("GET", "cheque-books")

    if result["success"]:
        books = result["data"].get("data", [])
        print_success(f"Trouvé {len(books)} carnet(s)")
        for book in books[:5]:
            remaining = book.get('totalCheques', 0) - book.get('usedCheques', 0)
            status = "actif" if book.get('isActive') else "inactif"
            print(f"   - {book.get('companyName')} / {book.get('bankName')} ({remaining} restants, {status})")
        return books
    else:
        print_error(f"Erreur: {result['data']}")
        return []

def test_print_history():
    """Test 5: Historique des impressions"""
    print_info("GET /print-history - Historique des impressions")

    result = make_request("GET", "print-history?limit=5")

    if result["success"]:
        data = result["data"].get("data", {})
        records = data.get("records", [])
        total = data.get("total", 0)
        print_success(f"Total: {total} impression(s)")
        for record in records[:5]:
            print(f"   - Chèque #{record.get('chequeNumber')} : {record.get('beneficiary')} - {record.get('amount')} FCFA")
    else:
        print_error(f"Erreur: {result['data']}")

    return result["success"]

def test_print_cheque(company_name, bank_name):
    """Test 6: Imprimer un chèque"""
    print_info("POST /print-cheque - Imprimer un chèque")

    data = {
        "beneficiaire": "TEST API PYTHON",
        "montant": "123456",
        "selectedBank": bank_name,
        "companyName": company_name,
        "lieu": "ABIDJAN"
    }

    print(f"   Données: {json.dumps(data, indent=2)}")

    result = make_request("POST", "print-cheque", data)

    if result["success"]:
        cheque = result["data"].get("data", {})
        print_success("Chèque imprimé avec succès!")
        print(f"   Numéro: {cheque.get('chequeNumber')}")
        print(f"   Montant en lettres: {cheque.get('montantEnLettres')}")
    else:
        print_error(f"Erreur: {result['data']}")

    return result["success"]

def test_print_batch(company_name, bank_name):
    """Test 7: Imprimer plusieurs chèques"""
    print_info("POST /print-batch - Imprimer plusieurs chèques")

    data = {
        "selectedBank": bank_name,
        "companyName": company_name,
        "cheques": [
            {"beneficiaire": "BATCH TEST 1", "montant": "50000"},
            {"beneficiaire": "BATCH TEST 2", "montant": "75000"}
        ]
    }

    print(f"   Nombre de chèques: {len(data['cheques'])}")

    result = make_request("POST", "print-batch", data)

    if result["success"]:
        batch = result["data"].get("data", {})
        print_success(f"Lot imprimé: {batch.get('totalProcessed')} chèques")
        print(f"   Montant total: {batch.get('totalAmount')} FCFA")
        for cheque in batch.get("cheques", []):
            print(f"   - #{cheque.get('chequeNumber')}: {cheque.get('beneficiaire')} - {cheque.get('montant')} FCFA")
    else:
        print_error(f"Erreur: {result['data']}")

    return result["success"]

def main():
    print_header("CheqPrint API - Tests Python")

    # Vérifier la clé API
    if not API_KEY:
        print_error("Clé API non configurée!")
        print_info("Créez un fichier .env avec: API_KEY=sk_live_VOTRE_CLE")
        print_info("Ou définissez la variable d'environnement API_KEY")
        return

    print_info(f"Clé API: {API_KEY[:20]}...")
    print_info(f"URL: {BASE_URL}")

    # Tests de lecture (sans modification)
    print_header("Tests de lecture")

    test_banks()
    test_templates()
    companies = test_companies()
    books = test_cheque_books()
    test_print_history()

    # Trouver un carnet actif pour les tests d'écriture
    active_book = None
    for book in books:
        if book.get("isActive"):
            remaining = book.get("totalCheques", 0) - book.get("usedCheques", 0)
            if remaining >= 3:  # Au moins 3 chèques pour les tests
                active_book = book
                break

    if active_book:
        print_header("Tests d'écriture")
        print_info(f"Utilisation du carnet: {active_book.get('companyName')} / {active_book.get('bankName')}")

        # Demander confirmation
        response = input("\n⚠️  Ces tests vont consommer des numéros de chèques. Continuer? (o/N): ")

        if response.lower() == 'o':
            test_print_cheque(active_book.get("companyName"), active_book.get("bankName"))
            test_print_batch(active_book.get("companyName"), active_book.get("bankName"))
        else:
            print_info("Tests d'écriture ignorés")
    else:
        print_header("Tests d'écriture")
        print_error("Aucun carnet actif avec assez de chèques trouvé")
        print_info("Créez un carnet de chèques dans l'app CheqPrint")

    print_header("Tests terminés")

if __name__ == "__main__":
    main()
