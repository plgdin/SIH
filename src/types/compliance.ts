export const COMPLIANCE_VERSION = '1.0.0';

export type RiskLevel = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type ComplianceStatus = 'COMPLIANT' | 'NEEDS_REVIEW' | 'NON_COMPLIANT';
export type DecisionStatus = 'PENDING' | 'APPROVED' | 'DISQUALIFIED';

export interface BidderDocument {
  id: string;
  name: string;
  type: 'PAN' | 'GST' | 'UDYAM' | 'OEM_AUTH' | 'MII_DECLARATION' | 'TURNOVER_CA' | 'TECHNICAL_SPEC' | 'AADHAAR';
  fileName: string;
  fileSize: string;
  uploadedAt: string;
  docHash: string;
  digiLockerVerified: boolean;
  rawTextPreview?: string;
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
