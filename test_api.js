/**
 * CheqPrint API - Script de test Node.js
 * =======================================
 *
 * Usage:
 *    1. Créez un fichier .env avec votre clé API:
 *       API_KEY=sk_live_VOTRE_CLE
 *
 *    2. Installez les dépendances:
 *       npm install
 *
 *    3. Lancez le script:
 *       node test_api.js
 */

require('dotenv').config();
const readline = require('readline');

// Configuration
const BASE_URL = "https://xwpgblfdmlrrkksmuazy.supabase.co/functions/v1";
const API_KEY = process.env.API_KEY || "";

// Couleurs
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

function printHeader(text) {
  console.log(`\n${colors.bold}${colors.blue}${'='.repeat(60)}${colors.reset}`);
  console.log(`${colors.bold}${colors.blue}  ${text}${colors.reset}`);
  console.log(`${colors.bold}${colors.blue}${'='.repeat(60)}${colors.reset}\n`);
}

function printSuccess(text) {
  console.log(`${colors.green}✓ ${text}${colors.reset}`);
}

function printError(text) {
  console.log(`${colors.red}✗ ${text}${colors.reset}`);
}

function printInfo(text) {
  console.log(`${colors.yellow}→ ${text}${colors.reset}`);
}

async function makeRequest(method, endpoint, data = null, auth = true) {
  const url = `${BASE_URL}/${endpoint}`;
  const headers = { "Content-Type": "application/json" };

  if (auth && API_KEY) {
    headers["Authorization"] = `Bearer ${API_KEY}`;
  }

  try {
    const options = {
      method,
      headers
    };

    if (data) {
      options.body = JSON.stringify(data);
    }

    const response = await fetch(url, options);
    const responseData = await response.json().catch(() => ({}));

    return {
      status: response.status,
      data: responseData,
      success: response.status < 400
    };
  } catch (error) {
    return {
      status: 0,
      data: { error: error.message },
      success: false
    };
  }
}

async function testBanks() {
  printInfo("GET /banks - Liste des banques disponibles");

  const result = await makeRequest("GET", "banks", null, false);

  if (result.success) {
    const banks = result.data.data || [];
    printSuccess(`Trouvé ${banks.length} banque(s)`);
    banks.slice(0, 5).forEach(bank => {
      console.log(`   - ${bank.name || bank.code || 'N/A'}`);
    });
  } else {
    printError(`Erreur: ${JSON.stringify(result.data)}`);
  }

  return result.success;
}

async function testTemplates() {
  printInfo("GET /templates - Templates de chèques");

  const result = await makeRequest("GET", "templates");

  if (result.success) {
    const templates = result.data.data || [];
    printSuccess(`Trouvé ${templates.length} template(s)`);
  } else {
    printError(`Erreur: ${JSON.stringify(result.data)}`);
  }

  return result.success;
}

async function testCompanies() {
  printInfo("GET /companies - Vos sociétés");

  const result = await makeRequest("GET", "companies");

  if (result.success) {
    const companies = result.data.data || [];
    printSuccess(`Trouvé ${companies.length} société(s)`);
    companies.slice(0, 5).forEach(company => {
      console.log(`   - ${company.name || 'N/A'}`);
    });
    return companies;
  } else {
    printError(`Erreur: ${JSON.stringify(result.data)}`);
    return [];
  }
}

async function testChequeBooks() {
  printInfo("GET /cheque-books - Vos carnets de chèques");

  const result = await makeRequest("GET", "cheque-books");

  if (result.success) {
    const books = result.data.data || [];
    printSuccess(`Trouvé ${books.length} carnet(s)`);
    books.slice(0, 5).forEach(book => {
      const remaining = (book.totalCheques || 0) - (book.usedCheques || 0);
      const status = book.isActive ? "actif" : "inactif";
      console.log(`   - ${book.companyName} / ${book.bankName} (${remaining} restants, ${status})`);
    });
    return books;
  } else {
    printError(`Erreur: ${JSON.stringify(result.data)}`);
    return [];
  }
}

async function testPrintHistory() {
  printInfo("GET /print-history - Historique des impressions");

  const result = await makeRequest("GET", "print-history?limit=5");

  if (result.success) {
    const data = result.data.data || {};
    const records = data.records || [];
    const total = data.total || 0;
    printSuccess(`Total: ${total} impression(s)`);
    records.slice(0, 5).forEach(record => {
      console.log(`   - Chèque #${record.chequeNumber} : ${record.beneficiary} - ${record.amount} FCFA`);
    });
  } else {
    printError(`Erreur: ${JSON.stringify(result.data)}`);
  }

  return result.success;
}

async function testPrintCheque(companyName, bankName) {
  printInfo("POST /print-cheque - Imprimer un chèque");

  const data = {
    beneficiaire: "TEST API NODEJS",
    montant: "234567",
    selectedBank: bankName,
    companyName: companyName,
    lieu: "ABIDJAN"
  };

  console.log(`   Données: ${JSON.stringify(data, null, 2)}`);

  const result = await makeRequest("POST", "print-cheque", data);

  if (result.success) {
    const cheque = result.data.data || {};
    printSuccess("Chèque imprimé avec succès!");
    console.log(`   Numéro: ${cheque.chequeNumber}`);
    console.log(`   Montant en lettres: ${cheque.montantEnLettres}`);
  } else {
    printError(`Erreur: ${JSON.stringify(result.data)}`);
  }

  return result.success;
}

async function testPrintBatch(companyName, bankName) {
  printInfo("POST /print-batch - Imprimer plusieurs chèques");

  const data = {
    selectedBank: bankName,
    companyName: companyName,
    cheques: [
      { beneficiaire: "BATCH JS 1", montant: "60000" },
      { beneficiaire: "BATCH JS 2", montant: "85000" }
    ]
  };

  console.log(`   Nombre de chèques: ${data.cheques.length}`);

  const result = await makeRequest("POST", "print-batch", data);

  if (result.success) {
    const batch = result.data.data || {};
    printSuccess(`Lot imprimé: ${batch.totalProcessed} chèques`);
    console.log(`   Montant total: ${batch.totalAmount} FCFA`);
    (batch.cheques || []).forEach(cheque => {
      console.log(`   - #${cheque.chequeNumber}: ${cheque.beneficiaire} - ${cheque.montant} FCFA`);
    });
  } else {
    printError(`Erreur: ${JSON.stringify(result.data)}`);
  }

  return result.success;
}

function askQuestion(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise(resolve => {
    rl.question(question, answer => {
      rl.close();
      resolve(answer);
    });
  });
}

async function main() {
  printHeader("CheqPrint API - Tests Node.js");

  // Vérifier la clé API
  if (!API_KEY) {
    printError("Clé API non configurée!");
    printInfo("Créez un fichier .env avec: API_KEY=sk_live_VOTRE_CLE");
    printInfo("Ou définissez la variable d'environnement API_KEY");
    return;
  }

  printInfo(`Clé API: ${API_KEY.substring(0, 20)}...`);
  printInfo(`URL: ${BASE_URL}`);

  // Tests de lecture
  printHeader("Tests de lecture");

  await testBanks();
  await testTemplates();
  await testCompanies();
  const books = await testChequeBooks();
  await testPrintHistory();

  // Trouver un carnet actif
  let activeBook = null;
  for (const book of books) {
    if (book.isActive) {
      const remaining = (book.totalCheques || 0) - (book.usedCheques || 0);
      if (remaining >= 3) {
        activeBook = book;
        break;
      }
    }
  }

  if (activeBook) {
    printHeader("Tests d'écriture");
    printInfo(`Utilisation du carnet: ${activeBook.companyName} / ${activeBook.bankName}`);

    const response = await askQuestion("\n⚠️  Ces tests vont consommer des numéros de chèques. Continuer? (o/N): ");

    if (response.toLowerCase() === 'o') {
      await testPrintCheque(activeBook.companyName, activeBook.bankName);
      await testPrintBatch(activeBook.companyName, activeBook.bankName);
    } else {
      printInfo("Tests d'écriture ignorés");
    }
  } else {
    printHeader("Tests d'écriture");
    printError("Aucun carnet actif avec assez de chèques trouvé");
    printInfo("Créez un carnet de chèques dans l'app CheqPrint");
  }

  printHeader("Tests terminés");
}

main().catch(console.error);
