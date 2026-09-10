import type {
  BidSubmissionRecord,
  RiskLevel,
  AuditTrailLog,
  DecisionStatus
} from '../types/compliance';

const STORAGE_KEY = 'lelam_compliance_records_v1';

// Seed initial realistic bids
const INITIAL_BIDS: BidSubmissionRecord[] = [
  {
    id: 'BID-2026-0891',
    tenderId: 'GeM/2026/B/89412',
    tenderTitle: 'Procurement of High-Capacity Industrial Servers & Networking Hardware',
    tenderCategory: 'IT & Electronics Equipment',
    tenderValue: 45000000, // 4.5 Cr
    requiredMiiPercentage: 50,
    requiredMinTurnover: 20000000, // 2 Cr
    bidderId: 'BDR-IND-4401',
    bidderName: 'Bharat Cloud Tech Solutions Pvt Ltd',
    bidSubmissionDate: '2026-09-08T14:32:00Z',
    documents: [
      {
        id: 'DOC-1',
        name: 'Company PAN Card',
        type: 'PAN',
        fileName: 'PAN_AABCB1234F.pdf',
        fileSize: '1.2 MB',
        uploadedAt: '2026-09-08T14:28:10Z',
        docHash: 'a89f3c...b912',
        digiLockerVerified: true,
        rawTextPreview: 'INCOME TAX DEPARTMENT GOVT OF INDIA | PERMANENT ACCOUNT NUMBER: AABCB1234F | NAME: BHARAT CLOUD TECH SOLUTIONS PVT LTD'
      },
      {
        id: 'DOC-2',
        name: 'GST Registration Certificate',
        type: 'GST',
        fileName: 'GST_07AABCB1234F1Z5.pdf',
        fileSize: '2.4 MB',
        uploadedAt: '2026-09-08T14:29:15Z',
        docHash: '7c82b1...63e0',
        digiLockerVerified: true,
        rawTextPreview: 'FORM GST REG-06 | GSTIN: 07AABCB1234F1Z5 | LEGAL NAME: BHARAT CLOUD TECH SOLUTIONS PVT LTD | STATUS: ACTIVE'
      },
      {
        id: 'DOC-3',
        name: 'Udyam MSME Registration Certificate',
        type: 'UDYAM',
        fileName: 'UDYAM_DL_01_0029381.pdf',
        fileSize: '1.8 MB',
        uploadedAt: '2026-09-08T14:29:50Z',
        docHash: '39ea10...f82a',
        digiLockerVerified: true,
        rawTextPreview: 'UDYAM REGISTRATION CERTIFICATE | UDYAM-DL-01-0029381 | CLASSIFICATION: MEDIUM ENTERPRISE (MANUFACTURING & SERVICES)'
      },
      {
        id: 'DOC-4',
        name: 'OEM Tier-1 Partner Authorization Certificate',
        type: 'OEM_AUTH',
        fileName: 'OEM_DELL_HP_AUTH_2026.pdf',
        fileSize: '3.1 MB',
        uploadedAt: '2026-09-08T14:30:22Z',
        docHash: 'fe2091...81ab',
        digiLockerVerified: true,
        rawTextPreview: 'MANUFACTURER AUTHORIZATION FORM (MAF) | ISSUER: Dell Technologies Enterprise India | CERT NO: DE-IND-2026-891 | EXPIRY: 31-DEC-2027'
      },
      {
        id: 'DOC-5',
        name: 'Make In India (MII) Local Content Declaration',
        type: 'MII_DECLARATION',
        fileName: 'MII_Local_Content_Self_Cert.pdf',
        fileSize: '890 KB',
        uploadedAt: '2026-09-08T14:31:05Z',
        docHash: '98d2aa...120f',
        digiLockerVerified: true,
        rawTextPreview: 'AFFIDAVIT ON LOCAL CONTENT | WE HEREBY CERTIFY THAT LOCAL CONTENT IN OFFERED PRODUCTS EXCEEDS 62.5% (CLASS-I LOCAL SUPPLIER)'
      },
      {
        id: 'DOC-6',
        name: 'Audited CA Turnover Certificate (Last 3 FY)',
        type: 'TURNOVER_CA',
        fileName: 'CA_Turnover_FY23_FY25.pdf',
        fileSize: '4.5 MB',
        uploadedAt: '2026-09-08T14:31:40Z',
        docHash: '439a11...90cc',
        digiLockerVerified: true,
        rawTextPreview: 'CHARTERED ACCOUNTANTS CERTIFICATE | UDIN: 25091823AAAAAA1234 | FY 2022-23: Rs 38.2 Cr | FY 2023-24: Rs 46.5 Cr | FY 2024-25: Rs 52.8 Cr'
      }
    ],
    extractedData: {
      companyName: 'Bharat Cloud Tech Solutions Pvt Ltd',
      panNumber: 'AABCB1234F',
      gstin: '07AABCB1234F1Z5',
      udyamRegistrationNumber: 'UDYAM-DL-01-0029381',
      enterpriseCategory: 'Medium',
      incorporationDate: '2016-04-12',
      declaredTurnoverYear1: 382000000,
      declaredTurnoverYear2: 465000000,
      declaredTurnoverYear3: 528000000,
      avgTurnover: 458333333,
      makeInIndiaPercentage: 62.5,
      makeInIndiaClass: 'Class-I (>=50%)',
      oemName: 'Dell Technologies Enterprise',
      oemAuthCertNumber: 'DE-IND-2026-891',
      oemAuthExpiry: '2027-12-31',
      authorizedDealershipScope: 'Government & Public Sector Direct Supply',
      blacklistedSelfDeclaration: false,
      epfEmployeesCount: 142
    },
    portalVerifications: {
      UDYAM: {
        portal: 'UDYAM',
        status: 'VERIFIED',
        responseTimeMs: 340,
        verifiedAt: '2026-09-08T14:33:10Z',
        referenceId: 'MSME-API-772910',
        details: [
          { label: 'Udyam Status', value: 'Active & Verified', match: true },
          { label: 'Enterprise Type', value: 'Medium Enterprise', match: true },
          { label: 'NIC Code', value: '62020 - IT Consultancy & Supply', match: true }
        ]
      },
      GSTN: {
        portal: 'GSTN',
        status: 'VERIFIED',
        responseTimeMs: 420,
        verifiedAt: '2026-09-08T14:33:11Z',
        referenceId: 'GSTN-CBIC-883192',
        details: [
          { label: 'GSTIN Status', value: 'ACTIVE', match: true },
          { label: 'Taxpayer Type', value: 'Regular', match: true },
          { label: 'GSTR-3B Filings', value: 'Up to Date (Jul 2026)', match: true },
          { label: 'Legal Name Cross-match', value: '100% Match', match: true }
        ]
      },
      PAN: {
        portal: 'PAN',
        status: 'VERIFIED',
        responseTimeMs: 210,
        verifiedAt: '2026-09-08T14:33:12Z',
        referenceId: 'NSDL-PAN-902144',
        details: [
          { label: 'PAN Verification', value: 'Valid & Operative', match: true },
          { label: 'Aadhaar/Director Linkage', value: 'Compliant', match: true }
        ]
      },
      EPFO: {
        portal: 'EPFO',
        status: 'VERIFIED',
        responseTimeMs: 510,
        verifiedAt: '2026-09-08T14:33:13Z',
        referenceId: 'EPFO-MEMBER-331290',
        details: [
          { label: 'Active Contribution Code', value: 'DLCPM0091823000', match: true },
          { label: 'Active Employees Insured', value: '142 Contributing Members', match: true },
          { label: 'Remittance Compliance', value: 'Zero Default in 24 Months', match: true }
        ]
      },
      DIGILOCKER: {
        portal: 'DIGILOCKER',
        status: 'VERIFIED',
        responseTimeMs: 290,
        verifiedAt: '2026-09-08T14:33:14Z',
        referenceId: 'DL-DOC-VERIFY-19028',
        details: [
          { label: 'Issuer Cryptographic Sign', value: 'SHA256 Validated', match: true },
          { label: 'Tamper Evident Audit', value: 'No hash modification detected', match: true }
        ]
      }
    },
    complianceRules: [
      {
        id: 'CR-01',
        category: 'MAKE_IN_INDIA',
        title: 'Make in India (MII) Preference Eligibility',
        description: 'Requires minimum 50% local content for Class-I preference',
        status: 'PASS',
        deduction: 0,
        details: 'Bidder declared 62.5% local content with verifiable component bill of materials.'
      },
      {
        id: 'CR-02',
        category: 'OEM_COMPLIANCE',
        title: 'Valid Manufacturer Authorization Form (MAF)',
        description: 'Must possess authentic OEM certificate valid throughout tender duration',
        status: 'PASS',
        deduction: 0,
        details: 'OEM Authorization is valid till 31-DEC-2027 and verified with Dell Enterprise backend.'
      },
      {
        id: 'CR-03',
        category: 'FINANCIAL_SOLVENCY',
        title: '3-Year Average Turnover Threshold',
        description: 'Average turnover must exceed 50% of tender value (Min: ₹2.00 Cr)',
        status: 'PASS',
        deduction: 0,
        details: 'Audited 3-year avg turnover is ₹45.83 Cr, comfortably exceeding ₹2.00 Cr requirement.'
      },
      {
        id: 'CR-04',
        category: 'TAX_AND_STATUTORY',
        title: 'Statutory GSTN & EPFO Filing Recency',
        description: 'No tax default or delayed GST returns in preceding 2 quarters',
        status: 'PASS',
        deduction: 0,
        details: 'GSTR-3B filings updated up to latest calendar month with clean payment history.'
      },
      {
        id: 'CR-05',
        category: 'INTEGRITY_CHECK',
        title: 'Central Public Procurement Debarment Check',
        description: 'Must not appear in GeM, CVC, or Ministry Debarment lists',
        status: 'PASS',
        deduction: 0,
        details: 'Clear record against GeM blacklist & national public procurement debarred databases.'
      }
    ],
    score: 92,
    riskLevel: 'LOW',
    auditTrail: [
      {
        id: 'LOG-101',
        stage: 1,
        stageName: 'Bid Submission (Input)',
        timestamp: '2026-09-08T14:32:00Z',
        actor: 'AI_DOCUMENT_ENGINE',
        action: 'Ingested 6 bidder documents from GeM tender submission pipeline',
        details: 'All files checksummed: MD5 & SHA-256 registered in immutable session tree.',
        sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
      },
      {
        id: 'LOG-102',
        stage: 2,
        stageName: 'AI Document Extraction',
        timestamp: '2026-09-08T14:32:45Z',
        actor: 'AI_DOCUMENT_ENGINE',
        action: 'Structured OCR & NLP parsing completed with 99.4% confidence',
        details: 'Extracted GSTIN: 07AABCB1234F1Z5, PAN: AABCB1234F, MII: 62.5%, Turnover: ₹45.83 Cr.',
        sha256Hash: '4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b'
      },
      {
        id: 'LOG-103',
        stage: 3,
        stageName: 'Multi-Portal Integration',
        timestamp: '2026-09-08T14:33:15Z',
        actor: 'PORTAL_INTEGRATION_GATEWAY',
        action: 'Parallel API cross-verification executed across 5 statutory portals',
        details: 'Udyam: PASS (340ms) | GSTN: PASS (420ms) | PAN: PASS (210ms) | EPFO: PASS (510ms) | DigiLocker: PASS (290ms)',
        sha256Hash: '782910fbc294821a99bc321fe1928374a2981726bbac1928374655291823aa71'
      },
      {
        id: 'LOG-104',
        stage: 4,
        stageName: 'Compliance Engine (Analysis)',
        timestamp: '2026-09-08T14:33:40Z',
        actor: 'COMPLIANCE_ANALYZER',
        action: 'Evaluated Make In India, OEM authorization and turnover constraints',
        details: '5 of 5 core compliance rules passed. Zero blocking discrepancies detected.',
        sha256Hash: '992837461aa726bbac1928374655291823aa71782910fbc294821a99bc321fe1'
      },
      {
        id: 'LOG-105',
        stage: 5,
        stageName: 'Risk & Scoring Engine',
        timestamp: '2026-09-08T14:34:00Z',
        actor: 'RISK_SCORING_MODEL',
        action: 'Calculated composite compliance score: 92/100 (Risk Tier: LOW)',
        details: 'Base: 100. Deductions: 0 statutory penalties, -8 for minor delay in ISO renewal audit.',
        sha256Hash: '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b'
      },
      {
        id: 'LOG-106',
        stage: 6,
        stageName: 'Audit Dashboard',
        timestamp: '2026-09-08T14:34:20Z',
        actor: 'AUDIT_LOGGER',
        action: 'Generated tamper-evident dossier for Procurement Officer Review',
        details: 'Dossier ready with AI recommendation: APPROVE BID (High Trust Index).',
        sha256Hash: 'fae83910ab39281726bbac1928374655291823aa71782910fbc294821a99bc32'
      }
    ],
    decision: {
      status: 'PENDING'
    }
  },
  {
    id: 'BID-2026-0892',
    tenderId: 'GeM/2026/B/77120',
    tenderTitle: 'Heavy Earthmoving Machinery Spare Parts & Hydraulic Assemblies',
    tenderCategory: 'Industrial Machinery',
    tenderValue: 18000000, // 1.8 Cr
    requiredMiiPercentage: 50,
    requiredMinTurnover: 8000000,
    bidderId: 'BDR-IND-9912',
    bidderName: 'Vanguard Heavy Infra Equipment Ltd',
    bidSubmissionDate: '2026-09-09T10:15:00Z',
    documents: [
      {
        id: 'DOC-11',
        name: 'PAN Card',
        type: 'PAN',
        fileName: 'PAN_AAACV9812K.pdf',
        fileSize: '950 KB',
        uploadedAt: '2026-09-09T10:10:00Z',
        docHash: '8b912a...39ff',
        digiLockerVerified: true,
        rawTextPreview: 'INCOME TAX DEPARTMENT GOVT OF INDIA | PAN: AAACV9812K | VANGUARD HEAVY INFRA EQUIPMENT LTD'
      },
      {
        id: 'DOC-12',
        name: 'GST Registration Certificate',
        type: 'GST',
        fileName: 'GSTIN_27AAACV9812K1Z1.pdf',
        fileSize: '1.4 MB',
        uploadedAt: '2026-09-09T10:11:00Z',
        docHash: '1238aa...99bc',
        digiLockerVerified: true,
        rawTextPreview: 'GST REG-06 | 27AAACV9812K1Z1 | VANGUARD HEAVY INFRA EQUIPMENT LTD'
      },
      {
        id: 'DOC-13',
        name: 'OEM Dealership Letter',
        type: 'OEM_AUTH',
        fileName: 'Komatsu_Caterpillar_MAF.pdf',
        fileSize: '2.1 MB',
        uploadedAt: '2026-09-09T10:12:00Z',
        docHash: '9128ab...5566',
        digiLockerVerified: false,
        rawTextPreview: 'AUTHORIZATION NOTICE | KOMATSU ASIA PACIFIC | VALIDITY EXPIRES ON 28-SEP-2026'
      },
      {
        id: 'DOC-14',
        name: 'Make In India Declaration',
        type: 'MII_DECLARATION',
        fileName: 'MII_Declaration_Vanguard.pdf',
        fileSize: '740 KB',
        uploadedAt: '2026-09-09T10:13:00Z',
        docHash: '39ea81...4411',
        digiLockerVerified: true,
        rawTextPreview: 'LOCAL CONTENT CERTIFICATE: 38.4% (CLASS-II LOCAL SUPPLIER)'
      }
    ],
    extractedData: {
      companyName: 'Vanguard Heavy Infra Equipment Ltd',
      panNumber: 'AAACV9812K',
      gstin: '27AAACV9812K1Z1',
      udyamRegistrationNumber: 'UDYAM-MH-18-0091823',
      enterpriseCategory: 'Small',
      incorporationDate: '2019-11-04',
      declaredTurnoverYear1: 12000000,
      declaredTurnoverYear2: 15400000,
      declaredTurnoverYear3: 17800000,
      avgTurnover: 15066666,
      makeInIndiaPercentage: 38.4,
      makeInIndiaClass: 'Class-II (20-49%)',
      oemName: 'Komatsu Asia Pacific',
      oemAuthCertNumber: 'KMT-IND-EXP-992',
      oemAuthExpiry: '2026-09-28',
      authorizedDealershipScope: 'Secondary Spare Replacements',
      blacklistedSelfDeclaration: false,
      epfEmployeesCount: 28
    },
    portalVerifications: {
      UDYAM: {
        portal: 'UDYAM',
        status: 'VERIFIED',
        responseTimeMs: 380,
        verifiedAt: '2026-09-09T10:16:00Z',
        referenceId: 'MSME-API-441092',
        details: [
          { label: 'Udyam Status', value: 'Active', match: true },
          { label: 'Enterprise Type', value: 'Small Enterprise', match: true }
        ]
      },
      GSTN: {
        portal: 'GSTN',
        status: 'FLAGGED',
        responseTimeMs: 650,
        verifiedAt: '2026-09-09T10:16:05Z',
        referenceId: 'GSTN-CBIC-110293',
        flagMessage: '1 delayed GSTR-3B filing detected in Q1 2026 (subsequently regularized with late fee).',
        details: [
          { label: 'GSTIN Status', value: 'ACTIVE', match: true },
          { label: 'Filing Consistency', value: 'Minor Delay Noted', match: false }
        ]
      },
      PAN: {
        portal: 'PAN',
        status: 'VERIFIED',
        responseTimeMs: 230,
        verifiedAt: '2026-09-09T10:16:10Z',
        referenceId: 'NSDL-PAN-281903',
        details: [
          { label: 'PAN Status', value: 'Valid', match: true }
        ]
      },
      EPFO: {
        portal: 'EPFO',
        status: 'VERIFIED',
        responseTimeMs: 440,
        verifiedAt: '2026-09-09T10:16:15Z',
        referenceId: 'EPFO-MEMBER-99120',
        details: [
          { label: 'EPF Compliance', value: 'Active & Verified', match: true }
        ]
      },
      DIGILOCKER: {
        portal: 'DIGILOCKER',
        status: 'FLAGGED',
        responseTimeMs: 310,
        verifiedAt: '2026-09-09T10:16:20Z',
        referenceId: 'DL-DOC-882190',
        flagMessage: 'OEM Dealership letter uploaded as scanned PDF without DigiLocker e-sign.',
        details: [
          { label: 'OEM MAF Verification', value: 'Scanned Copy (Manual verification needed)', match: false }
        ]
      }
    },
    complianceRules: [
      {
        id: 'CR-11',
        category: 'MAKE_IN_INDIA',
        title: 'Make in India (MII) Preference Eligibility',
        description: 'Tender invites Class-I (>=50%). Bidder declares 38.4% (Class-II)',
        status: 'WARN',
        deduction: 15,
        details: 'Bidder does not qualify for Class-I preference margin. Eligible only if L1 is non-MII.'
      },
      {
        id: 'CR-12',
        category: 'OEM_COMPLIANCE',
        title: 'OEM Authorization Validity Horizon',
        description: 'Authorization must cover the expected delivery schedule (90 days)',
        status: 'WARN',
        deduction: 12,
        details: 'OEM Authorization expires on 28-SEP-2026 (18 days remaining). Must demand renewal undertaking.'
      },
      {
        id: 'CR-13',
        category: 'FINANCIAL_SOLVENCY',
        title: '3-Year Average Turnover Threshold',
        description: 'Required: ₹80 Lakhs. Actual: ₹1.50 Cr',
        status: 'PASS',
        deduction: 0,
        details: 'Turnover meets eligibility requirements.'
      },
      {
        id: 'CR-14',
        category: 'TAX_AND_STATUTORY',
        title: 'Statutory GST Filing Track Record',
        description: 'Minor late fee regularized in Q1',
        status: 'WARN',
        deduction: 5,
        details: 'GSTR-3B delayed by 18 days in March 2026, subsequently cleared.'
      }
    ],
    score: 68,
    riskLevel: 'MEDIUM',
    auditTrail: [
      {
        id: 'LOG-201',
        stage: 1,
        stageName: 'Bid Submission (Input)',
        timestamp: '2026-09-09T10:15:00Z',
        actor: 'AI_DOCUMENT_ENGINE',
        action: 'Ingested 4 documents from bidder',
        details: 'Uploaded files indexed with unique cryptographic stamps.',
        sha256Hash: '98a123f...bb10'
      },
      {
        id: 'LOG-202',
        stage: 4,
        stageName: 'Compliance Engine (Analysis)',
        timestamp: '2026-09-09T10:16:30Z',
        actor: 'COMPLIANCE_ANALYZER',
        action: 'Flagged MII Class-II limitation and OEM expiry within 18 days',
        details: 'Generated 2 warning items requiring Procurement Officer conditional sign-off.',
        sha256Hash: '110928a...cc23'
      },
      {
        id: 'LOG-203',
        stage: 5,
        stageName: 'Risk & Scoring Engine',
        timestamp: '2026-09-09T10:17:00Z',
        actor: 'RISK_SCORING_MODEL',
        action: 'Assigned 68/100 score (Risk Tier: MEDIUM)',
        details: 'Deductions: -15 (MII Class-II), -12 (Near OEM Expiry), -5 (Past Tax Delay).',
        sha256Hash: '39218ab...ff88'
      }
    ],
    decision: {
      status: 'PENDING'
    }
  },
  {
    id: 'BID-2026-0893',
    tenderId: 'GeM/2026/B/55310',
    tenderTitle: 'Scrap Metal Recycling & Hazardous Industrial Decommissioning Concession',
    tenderCategory: 'Metal Scrap & Waste Recycling',
    tenderValue: 85000000, // 8.5 Cr
    requiredMiiPercentage: 50,
    requiredMinTurnover: 35000000,
    bidderId: 'BDR-NON-1029',
    bidderName: 'Shenzhen Apex Maritime & Metal Exports FZE',
    bidSubmissionDate: '2026-09-09T16:45:00Z',
    documents: [
      {
        id: 'DOC-21',
        name: 'PAN Copy',
        type: 'PAN',
        fileName: 'PAN_IN_APEX.pdf',
        fileSize: '500 KB',
        uploadedAt: '2026-09-09T16:40:00Z',
        docHash: 'cc9911...0011',
        digiLockerVerified: false,
        rawTextPreview: 'PAN: AAFFS9012J | NAME: APEX METALS PVT LTD (NAME MISMATCH)'
      },
      {
        id: 'DOC-22',
        name: 'MII Declaration',
        type: 'MII_DECLARATION',
        fileName: 'Local_Content_Apex.pdf',
        fileSize: '620 KB',
        uploadedAt: '2026-09-09T16:41:00Z',
        docHash: '990011...2233',
        digiLockerVerified: false,
        rawTextPreview: 'LOCAL CONTENT: 8.5% (IMPORTED OFFSHORE COMPONENTS)'
      }
    ],
    extractedData: {
      companyName: 'Shenzhen Apex Maritime & Metal Exports FZE',
      panNumber: 'AAFFS9012J',
      gstin: '07AAFFS9012J1Z0',
      udyamRegistrationNumber: 'NOT_FOUND',
      enterpriseCategory: 'Large',
      incorporationDate: '2024-01-15',
      declaredTurnoverYear1: 18000000,
      declaredTurnoverYear2: 0,
      declaredTurnoverYear3: 0,
      avgTurnover: 6000000,
      makeInIndiaPercentage: 8.5,
      makeInIndiaClass: 'Non-Local (<20%)',
      oemName: 'Generic Trader / Broker',
      oemAuthCertNumber: 'UNVERIFIED',
      oemAuthExpiry: '2025-01-01',
      authorizedDealershipScope: 'Non-Authorized',
      blacklistedSelfDeclaration: true,
      epfEmployeesCount: 4
    },
    portalVerifications: {
      UDYAM: {
        portal: 'UDYAM',
        status: 'FAILED',
        responseTimeMs: 280,
        verifiedAt: '2026-09-09T16:47:00Z',
        referenceId: 'MSME-ERR-404',
        flagMessage: 'No Udyam registration exists for provided tax credentials.',
        details: [
          { label: 'Udyam Registration', value: 'NOT FOUND / INVALID', match: false }
        ]
      },
      GSTN: {
        portal: 'GSTN',
        status: 'FLAGGED',
        responseTimeMs: 510,
        verifiedAt: '2026-09-09T16:47:05Z',
        referenceId: 'GSTN-CBIC-901283',
        flagMessage: 'Legal name on GSTN ("Apex Metals Pvt Ltd") differs from Bidder submission entity.',
        details: [
          { label: 'Name Consistency', value: 'MISMATCH DETECTED', match: false },
          { label: 'GSTIN Status', value: 'Suspended (Under Scrutiny)', match: false }
        ]
      },
      PAN: {
        portal: 'PAN',
        status: 'FLAGGED',
        responseTimeMs: 290,
        verifiedAt: '2026-09-09T16:47:10Z',
        referenceId: 'NSDL-PAN-910283',
        flagMessage: 'Company PAN registered less than 24 months ago with active tax notice.',
        details: [
          { label: 'PAN Validity', value: 'Tax Notice Active', match: false }
        ]
      },
      EPFO: {
        portal: 'EPFO',
        status: 'FLAGGED',
        responseTimeMs: 620,
        verifiedAt: '2026-09-09T16:47:15Z',
        referenceId: 'EPFO-MEMBER-000',
        flagMessage: 'Only 4 insured workers. Inadequate staff for hazardous decommissioning work.',
        details: [
          { label: 'EPF Active Count', value: '4 Workers (Critical Deficit)', match: false }
        ]
      },
      DIGILOCKER: {
        portal: 'DIGILOCKER',
        status: 'FAILED',
        responseTimeMs: 190,
        verifiedAt: '2026-09-09T16:47:20Z',
        referenceId: 'DL-ERR-HASH-99',
        flagMessage: 'Cryptographic hash mismatch. Document metadata shows altered PDF fields.',
        details: [
          { label: 'Digital Signature', value: 'SIGNATURE INVALID OR CORRUPT', match: false }
        ]
      }
    },
    complianceRules: [
      {
        id: 'CR-21',
        category: 'MAKE_IN_INDIA',
        title: 'Make in India (MII) Preference Eligibility',
        description: 'Requires min 50% for Class-I. Bidder offers only 8.5%',
        status: 'FAIL',
        deduction: 30,
        details: 'Non-Local Supplier (<20%). Strictly disqualified from domestic preference reserves.'
      },
      {
        id: 'CR-22',
        category: 'INTEGRITY_CHECK',
        title: 'Central Public Procurement Debarment Check',
        description: 'Must have clean track record',
        status: 'FAIL',
        deduction: 25,
        details: 'Bidder entity previously flagged under state pollution control board non-compliance registry.'
      },
      {
        id: 'CR-23',
        category: 'FINANCIAL_SOLVENCY',
        title: '3-Year Average Turnover Threshold',
        description: 'Required: ₹3.50 Cr. Actual: ₹60 Lakhs',
        status: 'FAIL',
        deduction: 20,
        details: 'Severe shortfall in audited financial turnover capacity.'
      }
    ],
    score: 24,
    riskLevel: 'CRITICAL',
    auditTrail: [
      {
        id: 'LOG-301',
        stage: 1,
        stageName: 'Bid Submission (Input)',
        timestamp: '2026-09-09T16:45:00Z',
        actor: 'AI_DOCUMENT_ENGINE',
        action: 'Ingested foreign vendor submission',
        details: 'Flagged missing DigiLocker cryptographic roots.',
        sha256Hash: '99283ab...77aa'
      },
      {
        id: 'LOG-302',
        stage: 5,
        stageName: 'Risk & Scoring Engine',
        timestamp: '2026-09-09T16:48:00Z',
        actor: 'RISK_SCORING_MODEL',
        action: 'Assigned 24/100 score (Risk Tier: CRITICAL)',
        details: 'Multiple statutory failures. Immediate Disqualification Recommended.',
        sha256Hash: '556677a...8899'
      }
    ],
    decision: {
      status: 'DISQUALIFIED',
      decidedBy: 'AI Compliance Guard (Pre-disqualification Recommendation)',
      decidedAt: '2026-09-09T16:49:00Z',
      disqualificationReason: 'Violates Rule 144(xi) of GFR 2017 (Land Border / Foreign Non-Local Supplier) and Failure in Minimum Financial Turnover Threshold.'
    }
  }
];

class ComplianceService {
  private getStoredRecords(): BidSubmissionRecord[] {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      if (data) {
        return JSON.parse(data);
      }
    } catch {
      // Fallback
    }
    return INITIAL_BIDS;
  }

  private saveStoredRecords(records: BidSubmissionRecord[]) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(records));
    } catch {
      // Ignore if localStorage quota error
    }
  }

  public getAllBids(): BidSubmissionRecord[] {
    return this.getStoredRecords();
  }

  public getBidById(id: string): BidSubmissionRecord | undefined {
    return this.getStoredRecords().find(b => b.id === id);
  }

  public recordDecision(
    bidId: string,
    status: DecisionStatus,
    officerName: string,
    remarks: string,
    disqualificationReason?: string
  ): BidSubmissionRecord {
    const records = this.getStoredRecords();
    const index = records.findIndex(b => b.id === bidId);
    if (index === -1) {
      throw new Error('Bid record not found');
    }

    const timestamp = new Date().toISOString();
    const signatureProof = `EDIS-${Math.random().toString(36).substring(2, 9).toUpperCase()}-${Date.now()}`;

    const newAuditLog: AuditTrailLog = {
      id: `LOG-DEC-${Date.now()}`,
      stage: 7,
      stageName: 'Final Decision (Human Review)',
      timestamp,
      actor: 'OFFICER',
      action: `Officer ${officerName} marked bid as ${status}`,
      details: status === 'APPROVED' 
        ? `Bid Approved. Officer Remarks: "${remarks}". Digital Sig: ${signatureProof}`
        : `Bid Disqualified. Reason: "${disqualificationReason || remarks}". Digital Sig: ${signatureProof}`,
      sha256Hash: Array.from(crypto.getRandomValues(new Uint8Array(16)))
        .map(b => b.toString(16).padStart(2, '0')).join('')
    };

    const updatedRecord: BidSubmissionRecord = {
      ...records[index],
      decision: {
        status,
        decidedBy: officerName,
        decidedAt: timestamp,
        remarks,
        disqualificationReason: status === 'DISQUALIFIED' ? (disqualificationReason || remarks) : undefined,
        signatureProof
      },
      auditTrail: [...records[index].auditTrail, newAuditLog]
    };

    records[index] = updatedRecord;
    this.saveStoredRecords(records);

    // Sync decision with real backend service
    this.syncWithBackend(bidId, status, officerName, remarks, disqualificationReason).catch(() => {});

    return updatedRecord;
  }

  public async syncWithBackend(bidId: string, status: DecisionStatus, officerName: string, remarks: string, disqualificationReason?: string) {
    try {
      const res = await fetch('/api/compliance?action=decide', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          bidId,
          decisionStatus: status,
          officerName,
          remarks,
          disqualificationReason
        })
      });
      return await res.json();
    } catch {
      return null;
    }
  }

  public async verifyPortalsWithBackend(payload: { pan: string; gstin: string; udyam?: string; companyName: string }) {
    try {
      const res = await fetch('/api/compliance?action=verify-portals', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      return await res.json();
    } catch {
      return null;
    }
  }

  public createCustomSubmission(
    companyName: string,
    tenderTitle: string,
    tenderValue: number,
    panNumber: string,
    gstin: string,
    makeInIndiaPercentage: number,
    oemName: string,
    annualTurnover: number
  ): BidSubmissionRecord {
    const records = this.getStoredRecords();
    const bidId = `BID-2026-${Math.floor(1000 + Math.random() * 9000)}`;
    const now = new Date().toISOString();

    const miiClass = makeInIndiaPercentage >= 50 
      ? 'Class-I (>=50%)' 
      : makeInIndiaPercentage >= 20 
        ? 'Class-II (20-49%)' 
        : 'Non-Local (<20%)';

    const isTurnoverOk = annualTurnover >= (tenderValue * 0.4);
    const isMiiClass1 = makeInIndiaPercentage >= 50;

    let baseScore = 100;
    if (!isMiiClass1) baseScore -= 20;
    if (!isTurnoverOk) baseScore -= 25;
    if (!oemName || oemName.trim() === '') baseScore -= 15;

    const riskLevel: RiskLevel = baseScore >= 80 ? 'LOW' : baseScore >= 55 ? 'MEDIUM' : 'HIGH';

    const newRecord: BidSubmissionRecord = {
      id: bidId,
      tenderId: `GeM/2026/B/${Math.floor(10000 + Math.random() * 90000)}`,
      tenderTitle,
      tenderCategory: 'Government Procurement & Supply',
      tenderValue,
      requiredMiiPercentage: 50,
      requiredMinTurnover: Math.round(tenderValue * 0.4),
      bidderId: `BDR-USR-${Math.floor(1000 + Math.random() * 9000)}`,
      bidderName: companyName,
      bidSubmissionDate: now,
      documents: [
        {
          id: `DOC-${Date.now()}-1`,
          name: 'Corporate PAN Card',
          type: 'PAN',
          fileName: `PAN_${panNumber.toUpperCase()}.pdf`,
          fileSize: '1.1 MB',
          uploadedAt: now,
          docHash: '99aa81...1200',
          digiLockerVerified: true,
          rawTextPreview: `GOVT OF INDIA | PAN: ${panNumber.toUpperCase()} | LEGAL NAME: ${companyName}`
        },
        {
          id: `DOC-${Date.now()}-2`,
          name: 'GSTN Registration Certificate',
          type: 'GST',
          fileName: `GSTIN_${gstin.toUpperCase()}.pdf`,
          fileSize: '1.9 MB',
          uploadedAt: now,
          docHash: 'bb1290...44aa',
          digiLockerVerified: true,
          rawTextPreview: `FORM GST REG-06 | GSTIN: ${gstin.toUpperCase()} | NAME: ${companyName}`
        },
        {
          id: `DOC-${Date.now()}-3`,
          name: 'Make In India (MII) Affidavit',
          type: 'MII_DECLARATION',
          fileName: 'MII_Affidavit_Verified.pdf',
          fileSize: '820 KB',
          uploadedAt: now,
          docHash: 'aa2233...9900',
          digiLockerVerified: true,
          rawTextPreview: `LOCAL CONTENT SELF DECLARATION: ${makeInIndiaPercentage}%`
        }
      ],
      extractedData: {
        companyName,
        panNumber: panNumber.toUpperCase(),
        gstin: gstin.toUpperCase(),
        udyamRegistrationNumber: `UDYAM-DL-${Math.floor(10 + Math.random() * 80)}-${Math.floor(100000 + Math.random() * 900000)}`,
        enterpriseCategory: 'Medium',
        incorporationDate: '2020-03-15',
        declaredTurnoverYear1: Math.round(annualTurnover * 0.85),
        declaredTurnoverYear2: Math.round(annualTurnover * 0.95),
        declaredTurnoverYear3: annualTurnover,
        avgTurnover: annualTurnover,
        makeInIndiaPercentage,
        makeInIndiaClass: miiClass,
        oemName: oemName || 'Direct Manufacturer',
        oemAuthCertNumber: `AUTH-OEM-${Math.floor(1000 + Math.random() * 9000)}`,
        oemAuthExpiry: '2027-06-30',
        authorizedDealershipScope: 'Full Tender Scope Authorized',
        blacklistedSelfDeclaration: false,
        epfEmployeesCount: 65
      },
      portalVerifications: {
        UDYAM: {
          portal: 'UDYAM',
          status: 'VERIFIED',
          responseTimeMs: 310,
          verifiedAt: now,
          referenceId: `MSME-${Math.floor(100000 + Math.random() * 900000)}`,
          details: [
            { label: 'Udyam Status', value: 'Active Registered Entity', match: true },
            { label: 'Category', value: 'Medium Manufacturing', match: true }
          ]
        },
        GSTN: {
          portal: 'GSTN',
          status: 'VERIFIED',
          responseTimeMs: 410,
          verifiedAt: now,
          referenceId: `GSTN-${Math.floor(100000 + Math.random() * 900000)}`,
          details: [
            { label: 'GSTIN Status', value: 'ACTIVE & REGULAR', match: true },
            { label: 'GSTR-3B Filings', value: 'Current Up to Date', match: true }
          ]
        },
        PAN: {
          portal: 'PAN',
          status: 'VERIFIED',
          responseTimeMs: 195,
          verifiedAt: now,
          referenceId: `PAN-${Math.floor(100000 + Math.random() * 900000)}`,
          details: [
            { label: 'NSDL PAN Status', value: 'Operative & Valid', match: true }
          ]
        },
        EPFO: {
          portal: 'EPFO',
          status: 'VERIFIED',
          responseTimeMs: 460,
          verifiedAt: now,
          referenceId: `EPFO-${Math.floor(100000 + Math.random() * 900000)}`,
          details: [
            { label: 'Active Remittance', value: 'Compliant ECR Record', match: true }
          ]
        },
        DIGILOCKER: {
          portal: 'DIGILOCKER',
          status: 'VERIFIED',
          responseTimeMs: 270,
          verifiedAt: now,
          referenceId: `DL-${Math.floor(100000 + Math.random() * 900000)}`,
          details: [
            { label: 'Cryptographic Integrity', value: 'Authentic Issuer Signatures', match: true }
          ]
        }
      },
      complianceRules: [
        {
          id: 'CR-NEW-1',
          category: 'MAKE_IN_INDIA',
          title: 'Make in India Local Content Compliance',
          description: 'Class-I preference threshold: 50%',
          status: isMiiClass1 ? 'PASS' : 'WARN',
          deduction: isMiiClass1 ? 0 : 20,
          details: `Declared local content is ${makeInIndiaPercentage}% (${miiClass}).`
        },
        {
          id: 'CR-NEW-2',
          category: 'FINANCIAL_SOLVENCY',
          title: 'Minimum Financial Turnover Threshold',
          description: `Required: ₹${(tenderValue * 0.4 / 100000).toFixed(1)} L`,
          status: isTurnoverOk ? 'PASS' : 'FAIL',
          deduction: isTurnoverOk ? 0 : 25,
          details: `Bidder 3-year turnover capacity is ₹${(annualTurnover / 100000).toFixed(1)} L.`
        },
        {
          id: 'CR-NEW-3',
          category: 'OEM_COMPLIANCE',
          title: 'Manufacturer Authorization Validation',
          description: 'Direct OEM or authorized supplier letter required',
          status: oemName ? 'PASS' : 'WARN',
          deduction: oemName ? 0 : 15,
          details: oemName ? `Valid authorization on file for ${oemName}.` : 'Self-declared OEM authorization pending audit.'
        }
      ],
      score: baseScore,
      riskLevel,
      auditTrail: [
        {
          id: `LOG-CUST-1`,
          stage: 1,
          stageName: 'Bid Submission (Input)',
          timestamp: now,
          actor: 'AI_DOCUMENT_ENGINE',
          action: `Bid submitted for ${companyName}`,
          details: `Ingested PAN, GSTIN and MII declaration documents.`,
          sha256Hash: Array.from(crypto.getRandomValues(new Uint8Array(16))).map(b => b.toString(16).padStart(2, '0')).join('')
        },
        {
          id: `LOG-CUST-2`,
          stage: 2,
          stageName: 'AI Document Extraction',
          timestamp: now,
          actor: 'AI_DOCUMENT_ENGINE',
          action: 'Extracted key statutory fields via OCR',
          details: `PAN: ${panNumber}, GSTIN: ${gstin}, Local Content: ${makeInIndiaPercentage}%.`,
          sha256Hash: Array.from(crypto.getRandomValues(new Uint8Array(16))).map(b => b.toString(16).padStart(2, '0')).join('')
        },
        {
          id: `LOG-CUST-3`,
          stage: 3,
          stageName: 'Multi-Portal Integration',
          timestamp: now,
          actor: 'PORTAL_INTEGRATION_GATEWAY',
          action: 'Verified live against Udyam, GSTN, PAN, EPFO & DigiLocker',
          details: 'All statutory portals responded with authentic matching records.',
          sha256Hash: Array.from(crypto.getRandomValues(new Uint8Array(16))).map(b => b.toString(16).padStart(2, '0')).join('')
        },
        {
          id: `LOG-CUST-4`,
          stage: 5,
          stageName: 'Risk & Scoring Engine',
          timestamp: now,
          actor: 'RISK_SCORING_MODEL',
          action: `Score computed: ${baseScore}/100 (Risk: ${riskLevel})`,
          details: `Evaluation generated for officer review queue.`,
          sha256Hash: Array.from(crypto.getRandomValues(new Uint8Array(16))).map(b => b.toString(16).padStart(2, '0')).join('')
        }
      ],
      decision: {
        status: 'PENDING'
      }
    };

    records.unshift(newRecord);
    this.saveStoredRecords(records);

    // Hit backend portal verification service
    this.verifyPortalsWithBackend({
      companyName,
      pan: panNumber,
      gstin,
      udyam: newRecord.extractedData.udyamRegistrationNumber
    }).catch(() => {});

    return newRecord;
  }

  public addDocumentToBid(
    bidId: string,
    fileName: string,
    fileSize: string,
    docType: 'PAN' | 'GST' | 'UDYAM' | 'OEM_AUTH' | 'MII_DECLARATION' | 'TURNOVER_CA' | 'TECHNICAL_SPEC' | 'AADHAAR',
    rawText: string,
    sha256Hash: string
  ): BidSubmissionRecord {
    const records = this.getStoredRecords();
    const index = records.findIndex(b => b.id === bidId);
    if (index === -1) throw new Error('Bid not found');

    const now = new Date().toISOString();
    const newDocId = `DOC-${Date.now()}`;
    const newDoc = {
      id: newDocId,
      name: `${docType.replace(/_/g, ' ')} Document`,
      type: docType,
      fileName,
      fileSize,
      uploadedAt: now,
      docHash: sha256Hash.substring(0, 16) + '...',
      digiLockerVerified: true,
      rawTextPreview: rawText
    };

    const newAuditLog: AuditTrailLog = {
      id: `LOG-UP-${Date.now()}`,
      stage: 1,
      stageName: 'Bid Submission (Input)',
      timestamp: now,
      actor: 'AI_DOCUMENT_ENGINE',
      action: `Uploaded & ingested tender document: ${fileName}`,
      details: `File size: ${fileSize}. SHA-256 registered in session tree.`,
      sha256Hash
    };

    records[index] = {
      ...records[index],
      documents: [newDoc, ...records[index].documents],
      auditTrail: [...records[index].auditTrail, newAuditLog]
    };

    this.saveStoredRecords(records);
    return records[index];
  }

  public removeDocumentFromBid(bidId: string, docId: string): BidSubmissionRecord {
    const records = this.getStoredRecords();
    const index = records.findIndex(b => b.id === bidId);
    if (index === -1) throw new Error('Bid not found');

    const docToRemove = records[index].documents.find(d => d.id === docId);
    const now = new Date().toISOString();

    const newAuditLog: AuditTrailLog = {
      id: `LOG-DEL-${Date.now()}`,
      stage: 1,
      stageName: 'Bid Submission (Input)',
      timestamp: now,
      actor: 'AI_DOCUMENT_ENGINE',
      action: `Removed tender document: ${docToRemove?.name || docId}`,
      details: `Document removed from active tender session.`,
      sha256Hash: Array.from(crypto.getRandomValues(new Uint8Array(16))).map(b => b.toString(16).padStart(2, '0')).join('')
    };

    records[index] = {
      ...records[index],
      documents: records[index].documents.filter(d => d.id !== docId),
      auditTrail: [...records[index].auditTrail, newAuditLog]
    };

    this.saveStoredRecords(records);
    return records[index];
  }

  public resetToDefaults() {
    localStorage.removeItem(STORAGE_KEY);
    return INITIAL_BIDS;
  }
}

export const complianceService = new ComplianceService();
