export const COMPLIANCE_VERSION = '1.0.0';

export type RiskLevel = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type ComplianceStatus = 'COMPLIANT' | 'NEEDS_REVIEW' | 'NON_COMPLIANT';
export type DecisionStatus = 'PENDING' | 'APPROVED' | 'DISQUALIFIED';

export type DocumentQualityStatus = 'QUALITY_PASSED' | 'QUALITY_WARNING' | 'QUALITY_FAILED';
export type ExtractionStatus = 'SUCCESS' | 'LOW_CONFIDENCE' | 'FAILED';
export type AuthoritativeVerificationStatus = 'VERIFIED' | 'FAILED' | 'PENDING' | 'NOT_CONFIGURED' | 'PROVIDER_UNAVAILABLE';
export type ManualReviewStatus = 'NOT_REQUIRED' | 'REQUIRED' | 'COMPLETED';
export type OverallDocumentStatus = 'VERIFIED' | 'NOT_VERIFIED' | 'ACTION_REQUIRED' | 'PENDING';

export interface QualityMetric {
  resolution: string; // e.g., "300 DPI (2480x3508)"
  blurScore: number; // 0 - 100 (>70 is good)
  sharpnessScore: number; // 0 - 100
  brightness: 'OPTIMAL' | 'TOO_DARK' | 'OVEREXPOSED';
  contrast: 'OPTIMAL' | 'LOW_CONTRAST';
  croppingStatus: 'COMPLETE' | 'CROPPED' | 'EDGES_CLIPPED';
  rotationStatus: 'ALIGNED' | 'ROTATED_90' | 'ROTATED_SKEWED';
  obstructionDetected: boolean;
  isDamaged: boolean;
  readabilityOfRequiredFields: 'READABLE' | 'DEGRADED' | 'UNREADABLE';
  ocrConfidenceScore: number;
  documentCompleteness: 'COMPLETE' | 'MISSING_PAGES' | 'INCOMPLETE';
  overallQuality: DocumentQualityStatus;
  reasons: string[];
  recommendedAction?: string;
}

export interface ExtractedField {
  fieldName: string;
  extractedValue: string;
  confidence: number; // percentage e.g. 97
  source: 'OCR' | 'DIGITAL_PDF' | 'MANUAL_ENTRY';
  timestamp: string;
  isVerified: boolean; // Remains false (UNVERIFIED) until authoritative verification passes
}

export interface BidderDocument {
  id: string;
  name: string;
  type: 'PAN' | 'GST' | 'UDYAM' | 'OEM_AUTH' | 'MII_DECLARATION' | 'TURNOVER_CA' | 'TECHNICAL_SPEC' | 'AADHAAR';
  fileName: string;
  fileSize: string;
  uploadedAt: string;
  docHash: string; // Cryptographic SHA-256 for integrity (NOT proof of authenticity)
  digiLockerVerified: boolean;
  rawTextPreview?: string;
  
  // Independent Separated States
  qualityStatus: DocumentQualityStatus;
  qualityMetrics: QualityMetric;
  extractionStatus: ExtractionStatus;
  extractedFields: ExtractedField[];
  authoritativeStatus: AuthoritativeVerificationStatus;
  authoritativeProvider: string; // e.g., "UIDAI Authorized e-KYC Gateway", "GSTN Authorized GSP Portal"
  authoritativeVerifiedAt?: string;
  authoritativeRefId?: string;
  manualReviewStatus: ManualReviewStatus;
  manualReviewReason?: string;
  
  // Derived Overall Status
  overallStatus: OverallDocumentStatus;
}

export interface ExtractedBidderData {
  companyName: string;
  panNumber: string;
  gstin: string;
  udyamRegistrationNumber: string;
  enterpriseCategory: 'Micro' | 'Small' | 'Medium' | 'Large';
  incorporationDate: string;
  declaredTurnoverYear1: number; // in INR
  declaredTurnoverYear2: number;
  declaredTurnoverYear3: number;
  avgTurnover: number;
  makeInIndiaPercentage: number;
  makeInIndiaClass: 'Class-I (>=50%)' | 'Class-II (20-49%)' | 'Non-Local (<20%)';
  oemName: string;
  oemAuthCertNumber: string;
  oemAuthExpiry: string;
  authorizedDealershipScope: string;
  blacklistedSelfDeclaration: boolean;
  epfEmployeesCount: number;
}

export interface PortalVerificationDetail {
  portal: 'UDYAM' | 'GSTN' | 'PAN' | 'EPFO' | 'DIGILOCKER';
  status: 'VERIFIED' | 'FLAGGED' | 'FAILED';
  responseTimeMs: number;
  verifiedAt: string;
  referenceId: string;
  details: {
    label: string;
    value: string;
    match: boolean;
  }[];
  flagMessage?: string;
}

export interface ComplianceRuleCheck {
  id: string;
  category: 'MAKE_IN_INDIA' | 'OEM_COMPLIANCE' | 'FINANCIAL_SOLVENCY' | 'TAX_AND_STATUTORY' | 'INTEGRITY_CHECK';
  title: string;
  description: string;
  status: 'PASS' | 'WARN' | 'FAIL';
  deduction: number;
  details: string;
}

export interface AuditTrailLog {
  id: string;
  stage: 1 | 2 | 3 | 4 | 5 | 6 | 7;
  stageName: string;
  timestamp: string;
  actor: 'AI_DOCUMENT_ENGINE' | 'PORTAL_INTEGRATION_GATEWAY' | 'COMPLIANCE_ANALYZER' | 'RISK_SCORING_MODEL' | 'AUDIT_LOGGER' | 'OFFICER';
  action: string;
  details: string;
  sha256Hash: string;
}

export interface BidSubmissionRecord {
  id: string;
  tenderId: string;
  tenderTitle: string;
  tenderCategory: string;
  tenderValue: number; // INR
  requiredMiiPercentage: number;
  requiredMinTurnover: number;
  bidderId: string;
  bidderName: string;
  bidSubmissionDate: string;
  documents: BidderDocument[];
  extractedData: ExtractedBidderData;
  portalVerifications: Record<'UDYAM' | 'GSTN' | 'PAN' | 'EPFO' | 'DIGILOCKER', PortalVerificationDetail>;
  complianceRules: ComplianceRuleCheck[];
  score: number; // 0 to 100
  riskLevel: RiskLevel;
  auditTrail: AuditTrailLog[];
  decision: {
    status: DecisionStatus;
    decidedBy?: string;
    decidedAt?: string;
    remarks?: string;
    disqualificationReason?: string;
    signatureProof?: string;
  };
}
