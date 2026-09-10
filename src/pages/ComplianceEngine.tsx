import React, { useState, useEffect } from 'react';
import {
  ShieldCheck, AlertTriangle, XCircle, CheckCircle2, FileText,
  Building2, Cpu, Database, Award, Scale, UserCheck, RefreshCw,
  PlusCircle, Search, ExternalLink, ChevronRight, Download, Eye,
  Lock, ArrowRight, Activity, Clock, Check, AlertCircle, FileCheck
} from 'lucide-react';
import { complianceService } from '../services/complianceService';
import { BidSubmissionRecord, DecisionStatus, RiskLevel } from '../types/compliance';
import { toast } from 'react-hot-toast';

export const ComplianceEngine: React.FC = () => {
  const [bids, setBids] = useState<BidSubmissionRecord[]>([]);
  const [selectedBidId, setSelectedBidId] = useState<string>('');
  const [activeTab, setActiveTab] = useState<number>(1);
  const [isSimulating, setIsSimulating] = useState<boolean>(false);
  const [simulationProgress, setSimulationProgress] = useState<number>(100);

  // Decision state
  const [officerName, setOfficerName] = useState<string>('Deputy Director (Procurement)');
  const [officerRemarks, setOfficerRemarks] = useState<string>('');
  const [disqualifyReason, setDisqualifyReason] = useState<string>('Non-compliance with Make in India Class-I local content minimum requirements.');
  const [showDecisionModal, setShowDecisionModal] = useState<boolean>(false);
  const [decisionTypeToConfirm, setDecisionTypeToConfirm] = useState<DecisionStatus>('APPROVED');

  // Custom bid modal state
  const [showNewBidModal, setShowNewBidModal] = useState<boolean>(false);
  const [newCompany, setNewCompany] = useState<string>('');
  const [newTenderTitle, setNewTenderTitle] = useState<string>('Supply of Autonomous Solar Microgrid Systems');
  const [newTenderValue, setNewTenderValue] = useState<number>(25000000);
  const [newPan, setNewPan] = useState<string>('AAACD8899K');
  const [newGst, setNewGst] = useState<string>('07AAACD8899K1Z4');
  const [newMii, setNewMii] = useState<number>(58.5);
  const [newOem, setNewOem] = useState<string>('Tata Power Solar Systems Ltd');
  const [newTurnover, setNewTurnover] = useState<number>(18500000);

  // Load bids
  useEffect(() => {
    loadBids();
  }, []);

  const loadBids = () => {
    const data = complianceService.getAllBids();
    setBids(data);
    if (data.length > 0 && !selectedBidId) {
      setSelectedBidId(data[0].id);
    }
  };

  const currentBid = bids.find(b => b.id === selectedBidId) || bids[0];

  const handleSimulateFullPipeline = () => {
    setIsSimulating(true);
    setSimulationProgress(14);
    setActiveTab(1);

    const steps = [
      { step: 1, progress: 14, delay: 600 },
      { step: 2, progress: 28, delay: 1300 },
      { step: 3, progress: 45, delay: 2100 },
      { step: 4, progress: 65, delay: 2800 },
      { step: 5, progress: 85, delay: 3500 },
      { step: 6, progress: 100, delay: 4200 },
    ];

    steps.forEach(({ step, progress, delay }) => {
      setTimeout(() => {
        setActiveTab(step);
        setSimulationProgress(progress);
        if (step === 6) {
          setIsSimulating(false);
          toast.success('7-Stage Compliance Analysis Completed Successfully!');
        }
      }, delay);
    });
  };

  const handleCreateBid = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newCompany.trim() || !newPan.trim() || !newGst.trim()) {
      toast.error('Please fill in required company and statutory tax details.');
      return;
    }

    const created = complianceService.createCustomSubmission(
      newCompany,
      newTenderTitle,
      newTenderValue,
      newPan,
      newGst,
      newMii,
      newOem,
      newTurnover
    );

    loadBids();
    setSelectedBidId(created.id);
    setShowNewBidModal(false);
    toast.success(`Bid registered for ${newCompany}! Running compliance scan.`);
    handleSimulateFullPipeline();
  };

  const handleExecuteDecision = () => {
    if (!currentBid) return;
    if (decisionTypeToConfirm === 'DISQUALIFIED' && !disqualifyReason.trim()) {
      toast.error('Disqualification requires a valid justification.');
      return;
    }

    const updated = complianceService.recordDecision(
      currentBid.id,
      decisionTypeToConfirm,
      officerName,
      officerRemarks || (decisionTypeToConfirm === 'APPROVED' ? 'Compliant with all statutory guidelines.' : disqualifyReason),
      decisionTypeToConfirm === 'DISQUALIFIED' ? disqualifyReason : undefined
    );

    loadBids();
    setShowDecisionModal(false);
    setActiveTab(7);
    toast.success(`Bid decision recorded: ${decisionTypeToConfirm}`);
  };

  const getRiskBadge = (risk: RiskLevel) => {
    switch (risk) {
      case 'LOW':
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 border border-emerald-500/30">LOW RISK</span>;
      case 'MEDIUM':
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-500/10 text-amber-600 border border-amber-500/30">MEDIUM RISK</span>;
      case 'HIGH':
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-orange-500/10 text-orange-600 border border-orange-500/30">HIGH RISK</span>;
      case 'CRITICAL':
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-rose-500/10 text-rose-600 border border-rose-500/30">CRITICAL RISK</span>;
    }
  };

  const getDecisionBadge = (status: DecisionStatus) => {
    switch (status) {
      case 'APPROVED':
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/15 text-emerald-600 border border-emerald-500/40"><CheckCircle2 className="w-3.5 h-3.5" /> APPROVED</span>;
      case 'DISQUALIFIED':
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-rose-500/15 text-rose-600 border border-rose-500/40"><XCircle className="w-3.5 h-3.5" /> DISQUALIFIED</span>;
      default:
        return <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-500/15 text-amber-600 border border-amber-500/40"><Clock className="w-3.5 h-3.5" /> REVIEW PENDING</span>;
    }
  };

  const stepsList = [
    { num: 1, title: 'Bid Submission', sub: 'Input & Docs', icon: FileText, color: 'text-blue-500', bg: 'bg-blue-500/10', border: 'border-blue-500/30' },
    { num: 2, title: 'AI Extraction', sub: 'OCR & Parser', icon: Cpu, color: 'text-purple-500', bg: 'bg-purple-500/10', border: 'border-purple-500/30' },
    { num: 3, title: 'Multi-Portal APIs', sub: 'GST/PAN/Udyam', icon: Database, color: 'text-emerald-500', bg: 'bg-emerald-500/10', border: 'border-emerald-500/30' },
    { num: 4, title: 'Compliance Engine', sub: 'MII & OEM Rules', icon: ShieldCheck, color: 'text-amber-500', bg: 'bg-amber-500/10', border: 'border-amber-500/30' },
    { num: 5, title: 'Risk & Scoring', sub: 'Score Gauge', icon: Award, color: 'text-teal-500', bg: 'bg-teal-500/10', border: 'border-teal-500/30' },
    { num: 6, title: 'Audit Dashboard', sub: 'Traceable Trail', icon: Scale, color: 'text-sky-500', bg: 'bg-sky-500/10', border: 'border-sky-500/30' },
    { num: 7, title: 'Final Decision', sub: 'Human Review', icon: UserCheck, color: 'text-rose-500', bg: 'bg-rose-500/10', border: 'border-rose-500/30' },
  ];

  if (!currentBid) return null;

  return (
    <div className="min-h-screen bg-slate-50/70 text-slate-900 pb-20 pt-6">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Top Header Banner */}
        <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 rounded-3xl p-6 sm:p-8 text-white shadow-xl mb-8 relative overflow-hidden">
          <div className="absolute right-0 top-0 w-96 h-96 bg-primary/20 rounded-full filter blur-3xl -z-0 pointer-events-none" />
          <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div>
              <div className="flex items-center gap-2.5 mb-2">
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                  <Activity className="w-3.5 h-3.5 animate-pulse" /> Live Statutory Compliance Pipeline
                </span>
                <span className="text-xs text-slate-400 font-mono">GeM & Public Procurement Safe Sandbox</span>
              </div>
              <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
                AI Tender Compliance & Verification Engine
              </h1>
              <p className="text-slate-300 text-sm sm:text-base mt-1.5 max-w-3xl">
                End-to-end 7-stage automated scrutiny: AI document OCR extraction, statutory API multi-portal cross-verification, Make-In-India & OEM rule auditing, and immutable officer review.
              </p>
            </div>

            <div className="flex items-center gap-3 self-start md:self-auto">
              <button
                onClick={() => setShowNewBidModal(true)}
                className="px-4 py-2.5 bg-primary hover:bg-primary-600 text-white font-medium rounded-xl text-sm shadow-md transition-all flex items-center gap-2 cursor-pointer"
              >
                <PlusCircle className="w-4 h-4" /> Submit Sample Bid
              </button>
              <button
                onClick={handleSimulateFullPipeline}
                disabled={isSimulating}
                className="px-4 py-2.5 bg-white/10 hover:bg-white/20 text-white font-medium rounded-xl text-sm border border-white/20 transition-all flex items-center gap-2 cursor-pointer disabled:opacity-50"
              >
                <RefreshCw className={`w-4 h-4 ${isSimulating ? 'animate-spin' : ''}`} /> Re-Run 7-Stage Scan
              </button>
            </div>
          </div>
        </div>

        {/* Bid Selection Bar */}
        <div className="bg-white border border-slate-200 rounded-2xl p-4 shadow-sm mb-6 flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3 w-full md:w-auto">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Select Bid Under Scrutiny:</span>
            <div className="flex flex-wrap gap-2">
              {bids.map(b => (
                <button
                  key={b.id}
                  onClick={() => setSelectedBidId(b.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer flex items-center gap-2 border ${
                    b.id === currentBid.id
                      ? 'bg-slate-900 text-white border-slate-900 shadow-sm'
                      : 'bg-slate-100 hover:bg-slate-200 text-slate-700 border-slate-200'
                  }`}
                >
                  <Building2 className="w-3.5 h-3.5" />
                  <span>{b.bidderName.split(' ')[0]} ({b.score}/100)</span>
                </button>
              ))}
            </div>
          </div>

          <div className="flex items-center gap-4 text-xs text-slate-600">
            <div><span className="font-semibold text-slate-900">Tender ID:</span> <span className="font-mono">{currentBid.tenderId}</span></div>
            <div><span className="font-semibold text-slate-900">Est. Value:</span> ₹{(currentBid.tenderValue / 10000000).toFixed(2)} Cr</div>
            <div>{getRiskBadge(currentBid.riskLevel)}</div>
            <div>{getDecisionBadge(currentBid.decision.status)}</div>
          </div>
        </div>

        {/* 7-Step Interactive Flow Header (Directly reflecting the infographic) */}
        <div className="bg-white border border-slate-200 rounded-3xl p-4 sm:p-6 shadow-sm mb-8">
          <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4 flex items-center justify-between">
            <span>7-Stage Automated Verification Architecture</span>
            <span>Click any phase to inspect details</span>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-3">
            {stepsList.map((st) => {
              const IconComp = st.icon;
              const isSelected = activeTab === st.num;
              return (
                <button
                  key={st.num}
                  onClick={() => setActiveTab(st.num)}
                  className={`p-3 rounded-2xl text-left border transition-all cursor-pointer relative overflow-hidden flex flex-col justify-between ${
                    isSelected
                      ? 'bg-slate-900 text-white border-slate-900 shadow-md ring-2 ring-primary/40'
                      : 'bg-white hover:bg-slate-50 text-slate-700 border-slate-200'
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                      isSelected ? 'bg-white/20 text-white' : `${st.bg} ${st.color}`
                    }`}>
                      {st.num}
                    </span>
                    <IconComp className={`w-4 h-4 ${isSelected ? 'text-primary-300' : st.color}`} />
                  </div>
                  <div>
                    <div className="text-xs font-bold leading-tight">{st.title}</div>
                    <div className={`text-[10px] mt-0.5 ${isSelected ? 'text-slate-300' : 'text-slate-500'}`}>
                      {st.sub}
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Active Stage Content Area */}
        <div className="bg-white border border-slate-200 rounded-3xl p-6 sm:p-8 shadow-sm">
          
          {/* STEP 1: BID SUBMISSION (INPUT) */}
          {activeTab === 1 && (
            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="text-xs font-bold text-blue-600 uppercase tracking-wider">Phase 1: Bid Submission & Document Ingestion</div>
                  <h2 className="text-2xl font-bold text-slate-900 mt-1">Submitted Bid Documents & Metadata</h2>
                  <p className="text-sm text-slate-500">Ingested from GeM / Central Public Procurement Portal with cryptographic hashes.</p>
                </div>
                <div className="flex items-center gap-2 text-xs bg-blue-50 text-blue-700 px-3 py-1.5 rounded-xl border border-blue-200">
                  <Clock className="w-3.5 h-3.5" /> Submitted: {new Date(currentBid.bidSubmissionDate).toLocaleString()}
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {currentBid.documents.map((doc) => (
                  <div key={doc.id} className="p-4 rounded-2xl border border-slate-200 bg-slate-50/50 hover:bg-slate-50 transition-all flex flex-col justify-between">
                    <div>
                      <div className="flex items-center justify-between gap-2 mb-2">
                        <span className="text-xs font-mono font-bold px-2 py-0.5 rounded bg-slate-200 text-slate-700">
                          {doc.type}
                        </span>
                        {doc.digiLockerVerified ? (
                          <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full border border-emerald-200">
                            <CheckCircle2 className="w-3 h-3" /> DigiLocker
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-amber-600 bg-amber-50 px-2 py-0.5 rounded-full border border-amber-200">
                            <AlertTriangle className="w-3 h-3" /> Scanned Copy
                          </span>
                        )}
                      </div>
                      <h4 className="text-sm font-bold text-slate-900">{doc.name}</h4>
                      <p className="text-xs text-slate-500 font-mono mt-1 truncate">{doc.fileName} ({doc.fileSize})</p>
                    </div>

                    {doc.rawTextPreview && (
                      <div className="mt-3 p-2.5 rounded-xl bg-slate-100 border border-slate-200/80 text-[11px] font-mono text-slate-600 line-clamp-2">
                        {doc.rawTextPreview}
                      </div>
                    )}

                    <div className="mt-4 pt-3 border-t border-slate-200/60 flex items-center justify-between text-[11px] text-slate-500">
                      <span className="font-mono">Hash: {doc.docHash}</span>
                      <button 
                        onClick={() => toast(`Raw text preview: ${doc.rawTextPreview || 'No text extracted'}`)}
                        className="text-primary hover:underline font-semibold cursor-pointer"
                      >
                        Inspect
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="p-4 rounded-2xl bg-blue-50/50 border border-blue-100 flex items-center justify-between">
                <div className="text-xs text-blue-900">
                  <span className="font-bold">Next Stage:</span> AI Document Extraction processes uploaded PDF forms through neural OCR and regex pipelines.
                </div>
                <button
                  onClick={() => setActiveTab(2)}
                  className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 cursor-pointer"
                >
                  Inspect AI Extraction <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}

          {/* STEP 2: AI DOCUMENT EXTRACTION */}
          {activeTab === 2 && (
            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="text-xs font-bold text-purple-600 uppercase tracking-wider">Phase 2: AI Document Extraction</div>
                  <h2 className="text-2xl font-bold text-slate-900 mt-1">Extracted Bidder Entity Parameters</h2>
                  <p className="text-sm text-slate-500">Multimodal OCR and NLP document parser structured data without manual data-entry errors.</p>
                </div>
                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold bg-purple-50 text-purple-700 border border-purple-200">
                  <Cpu className="w-3.5 h-3.5" /> Extraction Confidence: 99.4%
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                <div className="p-5 rounded-2xl border border-slate-200 bg-slate-50/30">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Entity Name</div>
                  <div className="text-base font-bold text-slate-900 mt-1">{currentBid.extractedData.companyName}</div>
                  <div className="mt-3 text-xs text-slate-500">Incorporation Date: <span className="font-mono font-semibold text-slate-800">{currentBid.extractedData.incorporationDate}</span></div>
                  <div className="text-xs text-slate-500 mt-0.5">Enterprise Scale: <span className="font-semibold text-slate-800">{currentBid.extractedData.enterpriseCategory}</span></div>
                </div>

                <div className="p-5 rounded-2xl border border-slate-200 bg-slate-50/30">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Statutory IDs</div>
                  <div className="mt-2 space-y-1 font-mono text-xs">
                    <div className="flex justify-between"><span className="text-slate-500">PAN:</span> <span className="font-bold text-slate-900">{currentBid.extractedData.panNumber}</span></div>
                    <div className="flex justify-between"><span className="text-slate-500">GSTIN:</span> <span className="font-bold text-slate-900">{currentBid.extractedData.gstin}</span></div>
                    <div className="flex justify-between"><span className="text-slate-500">Udyam MSME:</span> <span className="font-bold text-slate-900">{currentBid.extractedData.udyamRegistrationNumber}</span></div>
                  </div>
                </div>

                <div className="p-5 rounded-2xl border border-slate-200 bg-slate-50/30">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Make in India Local Content</div>
                  <div className="text-2xl font-black text-indigo-600 mt-1">{currentBid.extractedData.makeInIndiaPercentage}%</div>
                  <div className="mt-1 text-xs font-semibold text-slate-700">{currentBid.extractedData.makeInIndiaClass}</div>
                  <div className="mt-2 text-[11px] text-slate-500">Required: {currentBid.requiredMiiPercentage}% for Class-I preference margin.</div>
                </div>

                <div className="p-5 rounded-2xl border border-slate-200 bg-slate-50/30">
                  <div className="text-xs font-semibold text-slate-400 uppercase">OEM Authorization</div>
                  <div className="text-sm font-bold text-slate-900 mt-1">{currentBid.extractedData.oemName}</div>
                  <div className="mt-2 space-y-0.5 text-xs text-slate-600">
                    <div>Cert No: <span className="font-mono font-medium">{currentBid.extractedData.oemAuthCertNumber}</span></div>
                    <div>Expiry Date: <span className="font-mono font-medium text-amber-700">{currentBid.extractedData.oemAuthExpiry}</span></div>
                  </div>
                </div>

                <div className="p-5 rounded-2xl border border-slate-200 bg-slate-50/30">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Financial Solvency (Turnover)</div>
                  <div className="text-lg font-bold text-slate-900 mt-1">₹{(currentBid.extractedData.avgTurnover / 10000000).toFixed(2)} Cr <span className="text-xs font-normal text-slate-500">(3-Yr Avg)</span></div>
                  <div className="mt-2 text-xs text-slate-500">
                    Threshold Required: ₹{(currentBid.requiredMinTurnover / 10000000).toFixed(2)} Cr
                  </div>
                  <div className="mt-1 text-xs">
                    {currentBid.extractedData.avgTurnover >= currentBid.requiredMinTurnover ? (
                      <span className="text-emerald-600 font-semibold">✓ Meets Eligibility</span>
                    ) : (
                      <span className="text-rose-600 font-semibold">✗ Deficit in Turnover</span>
                    )}
                  </div>
                </div>

                <div className="p-5 rounded-2xl border border-slate-200 bg-slate-50/30">
                  <div className="text-xs font-semibold text-slate-400 uppercase">Statutory Workforce (EPFO)</div>
                  <div className="text-lg font-bold text-slate-900 mt-1">{currentBid.extractedData.epfEmployeesCount} Active Contributors</div>
                  <div className="mt-2 text-xs text-slate-500">
                    Debarment / Blacklist Self-Declaration: 
                    <span className={`font-semibold ml-1 ${currentBid.extractedData.blacklistedSelfDeclaration ? 'text-rose-600' : 'text-emerald-600'}`}>
                      {currentBid.extractedData.blacklistedSelfDeclaration ? 'YES (FLAGGED)' : 'CLEAR (NO DEBARMENT)'}
                    </span>
                  </div>
                </div>
              </div>

              <div className="p-4 rounded-2xl bg-purple-50/50 border border-purple-100 flex items-center justify-between">
                <div className="text-xs text-purple-900">
                  <span className="font-bold">Next Stage:</span> Cross-verifying extracted parameters against real-time government registries.
                </div>
                <button
                  onClick={() => setActiveTab(3)}
                  className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 cursor-pointer"
                >
                  Verify Multi-Portal APIs <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}

          {/* STEP 3: MULTI-PORTAL INTEGRATION (APIs) */}
          {activeTab === 3 && (
            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="text-xs font-bold text-emerald-600 uppercase tracking-wider">Phase 3: Multi-Portal API Cross-Verification</div>
                  <h2 className="text-2xl font-bold text-slate-900 mt-1">Real-Time Statutory Registry Queries</h2>
                  <p className="text-sm text-slate-500">Direct integration endpoints verifying Udyam, GSTN, PAN, EPFO, and DigiLocker.</p>
                </div>
                <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                  <Database className="w-3.5 h-3.5" /> 5 Portals Polled in Parallel
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                {Object.values(currentBid.portalVerifications).map((pv) => {
                  const isVerified = pv.status === 'VERIFIED';
                  const isFlagged = pv.status === 'FLAGGED';

                  return (
                    <div 
                      key={pv.portal}
                      className={`p-5 rounded-2xl border transition-all ${
                        isVerified 
                          ? 'border-emerald-200 bg-emerald-50/20' 
                          : isFlagged 
                            ? 'border-amber-200 bg-amber-50/20' 
                            : 'border-rose-200 bg-rose-50/20'
                      }`}
                    >
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-2">
                          <span className="font-extrabold text-sm tracking-wider text-slate-900">{pv.portal}</span>
                          <span className="text-[10px] font-mono text-slate-400">({pv.responseTimeMs}ms)</span>
                        </div>
                        {isVerified && <span className="text-xs font-bold text-emerald-600 flex items-center gap-1"><CheckCircle2 className="w-3.5 h-3.5" /> VERIFIED</span>}
                        {isFlagged && <span className="text-xs font-bold text-amber-600 flex items-center gap-1"><AlertTriangle className="w-3.5 h-3.5" /> FLAGGED</span>}
                        {!isVerified && !isFlagged && <span className="text-xs font-bold text-rose-600 flex items-center gap-1"><XCircle className="w-3.5 h-3.5" /> FAILED</span>}
                      </div>

                      <div className="text-[11px] text-slate-500 font-mono mb-3">Ref ID: {pv.referenceId}</div>

                      <div className="space-y-2 border-t border-slate-200/60 pt-3">
                        {pv.details.map((d, i) => (
                          <div key={i} className="flex items-center justify-between text-xs">
                            <span className="text-slate-600">{d.label}:</span>
                            <span className={`font-semibold ${d.match ? 'text-slate-900' : 'text-rose-600'}`}>
                              {d.value}
                            </span>
                          </div>
                        ))}
                      </div>

                      {pv.flagMessage && (
                        <div className="mt-3 p-2 rounded-xl bg-amber-100/70 border border-amber-300/60 text-[11px] text-amber-900 font-medium">
                          ⚠️ {pv.flagMessage}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>

              <div className="p-4 rounded-2xl bg-emerald-50/50 border border-emerald-100 flex items-center justify-between">
                <div className="text-xs text-emerald-900">
                  <span className="font-bold">Next Stage:</span> Evaluating Make-In-India (MII) preference, OEM authorization, and statutory rules.
                </div>
                <button
                  onClick={() => setActiveTab(4)}
                  className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 cursor-pointer"
                >
                  Analyze Compliance Rules <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}

          {/* STEP 4: COMPLIANCE ENGINE (ANALYSIS) */}
          {activeTab === 4 && (
            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="text-xs font-bold text-amber-600 uppercase tracking-wider">Phase 4: Compliance Engine Analysis</div>
                  <h2 className="text-2xl font-bold text-slate-900 mt-1">Rule Matrix & Discrepancy Auditing</h2>
                  <p className="text-sm text-slate-500">Validating Make In India (MII), Manufacturer Authorization (MAF), and procurement statutory covenants.</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="px-3 py-1 bg-slate-100 text-slate-700 rounded-xl text-xs font-bold">
                    {currentBid.complianceRules.filter(r => r.status === 'PASS').length}/{currentBid.complianceRules.length} Rules Satisfied
                  </span>
                </div>
              </div>

              <div className="space-y-3">
                {currentBid.complianceRules.map((rule) => {
                  const isPass = rule.status === 'PASS';
                  const isWarn = rule.status === 'WARN';

                  return (
                    <div 
                      key={rule.id}
                      className={`p-5 rounded-2xl border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
                        isPass 
                          ? 'border-slate-200 bg-white hover:border-emerald-300' 
                          : isWarn 
                            ? 'border-amber-200 bg-amber-50/20' 
                            : 'border-rose-200 bg-rose-50/30'
                      }`}
                    >
                      <div className="flex items-start gap-3">
                        <div className="mt-0.5">
                          {isPass && <CheckCircle2 className="w-5 h-5 text-emerald-600" />}
                          {isWarn && <AlertTriangle className="w-5 h-5 text-amber-600" />}
                          {!isPass && !isWarn && <XCircle className="w-5 h-5 text-rose-600" />}
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="text-xs font-mono font-bold text-slate-400">{rule.id}</span>
                            <span className="text-xs font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-600">{rule.category}</span>
                          </div>
                          <h4 className="text-sm font-bold text-slate-900 mt-1">{rule.title}</h4>
                          <p className="text-xs text-slate-500 mt-0.5">{rule.description}</p>
                          <div className="mt-2 text-xs font-medium text-slate-700 bg-slate-50 p-2 rounded-xl border border-slate-200/60">
                            {rule.details}
                          </div>
                        </div>
                      </div>

                      <div className="sm:text-right shrink-0">
                        {isPass ? (
                          <span className="inline-block text-xs font-bold text-emerald-600 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200">
                            PASS (+0 Penalty)
                          </span>
                        ) : isWarn ? (
                          <span className="inline-block text-xs font-bold text-amber-600 px-3 py-1 rounded-full bg-amber-50 border border-amber-200">
                            WARN (-{rule.deduction} Pts)
                          </span>
                        ) : (
                          <span className="inline-block text-xs font-bold text-rose-600 px-3 py-1 rounded-full bg-rose-50 border border-rose-200">
                            FAIL (-{rule.deduction} Pts)
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>

              <div className="p-4 rounded-2xl bg-amber-50/50 border border-amber-100 flex items-center justify-between">
                <div className="text-xs text-amber-900">
                  <span className="font-bold">Next Stage:</span> Synthesize findings into quantitative Risk Score (0-100) and identify risk level.
                </div>
                <button
                  onClick={() => setActiveTab(5)}
                  className="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 cursor-pointer"
                >
                  Calculate Risk & Scoring <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}

          {/* STEP 5: RISK & SCORING (SCORING) */}
          {activeTab === 5 && (
            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="text-xs font-bold text-teal-600 uppercase tracking-wider">Phase 5: Risk & Scoring Engine</div>
                  <h2 className="text-2xl font-bold text-slate-900 mt-1">Algorithmic Risk Assessment & Trust Score</h2>
                  <p className="text-sm text-slate-500">Weighs statutory verifications, turnover ratios, and MII declarations into an objective 0–100 scale.</p>
                </div>
                <div>{getRiskBadge(currentBid.riskLevel)}</div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-center">
                {/* Visual Score Gauge */}
                <div className="p-6 rounded-3xl border border-slate-200 bg-gradient-to-b from-slate-50 to-white flex flex-col items-center justify-center text-center">
                  <div className="relative w-44 h-44 flex items-center justify-center">
                    <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
                      <path
                        className="text-slate-200"
                        strokeWidth="3.2"
                        stroke="currentColor"
                        fill="none"
                        d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      />
                      <path
                        className={
                          currentBid.score >= 80 ? 'text-emerald-500' :
                          currentBid.score >= 60 ? 'text-amber-500' : 'text-rose-500'
                        }
                        strokeDasharray={`${currentBid.score}, 100`}
                        strokeWidth="3.2"
                        strokeLinecap="round"
                        stroke="currentColor"
                        fill="none"
                        d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                      />
                    </svg>
                    <div className="absolute flex flex-col items-center">
                      <span className="text-4xl font-extrabold text-slate-900 tracking-tight">{currentBid.score}</span>
                      <span className="text-xs font-semibold text-slate-400 uppercase">out of 100</span>
                    </div>
                  </div>

                  <div className="mt-4">
                    <div className="text-sm font-bold text-slate-900">Composite Trust Rating</div>
                    <div className="text-xs text-slate-500 mt-0.5">
                      {currentBid.score >= 80 ? 'High Trust / Recommended for Award' :
                       currentBid.score >= 60 ? 'Conditional Eligibility (Officer Scrutiny Required)' :
                       'Severe Deficit / Disqualification Flagged'}
                    </div>
                  </div>
                </div>

                {/* Score Breakdown Cards */}
                <div className="md:col-span-2 space-y-3">
                  <div className="p-4 rounded-2xl border border-slate-200 bg-white flex items-center justify-between">
                    <div>
                      <div className="text-xs font-bold text-slate-900">Make in India Local Content</div>
                      <div className="text-xs text-slate-500">{currentBid.extractedData.makeInIndiaClass} ({currentBid.extractedData.makeInIndiaPercentage}%)</div>
                    </div>
                    <span className="text-xs font-bold text-slate-800">
                      {currentBid.extractedData.makeInIndiaPercentage >= 50 ? '+30/30' : currentBid.extractedData.makeInIndiaPercentage >= 20 ? '+15/30' : '+0/30'}
                    </span>
                  </div>

                  <div className="p-4 rounded-2xl border border-slate-200 bg-white flex items-center justify-between">
                    <div>
                      <div className="text-xs font-bold text-slate-900">Statutory Portal Verification (GSTN, PAN, EPFO, Udyam)</div>
                      <div className="text-xs text-slate-500">Cross-verified without fraudulent mismatch</div>
                    </div>
                    <span className="text-xs font-bold text-slate-800">
                      {currentBid.riskLevel === 'LOW' ? '+35/35' : currentBid.riskLevel === 'MEDIUM' ? '+25/35' : '+10/35'}
                    </span>
                  </div>

                  <div className="p-4 rounded-2xl border border-slate-200 bg-white flex items-center justify-between">
                    <div>
                      <div className="text-xs font-bold text-slate-900">OEM Authorization & Validity Coverage</div>
                      <div className="text-xs text-slate-500">{currentBid.extractedData.oemName}</div>
                    </div>
                    <span className="text-xs font-bold text-slate-800">
                      {currentBid.riskLevel === 'CRITICAL' ? '+0/20' : currentBid.riskLevel === 'MEDIUM' ? '+10/20' : '+20/20'}
                    </span>
                  </div>

                  <div className="p-4 rounded-2xl border border-slate-200 bg-white flex items-center justify-between">
                    <div>
                      <div className="text-xs font-bold text-slate-900">Financial Solvency Ratio</div>
                      <div className="text-xs text-slate-500">Turnover vs Tender Value</div>
                    </div>
                    <span className="text-xs font-bold text-slate-800">
                      {currentBid.extractedData.avgTurnover >= currentBid.requiredMinTurnover ? '+15/15' : '+0/15'}
                    </span>
                  </div>
                </div>
              </div>

              <div className="p-4 rounded-2xl bg-teal-50/50 border border-teal-100 flex items-center justify-between">
                <div className="text-xs text-teal-900">
                  <span className="font-bold">Next Stage:</span> Review centralized AI dossier & inspect 100% traceable cryptographic audit trail.
                </div>
                <button
                  onClick={() => setActiveTab(6)}
                  className="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 cursor-pointer"
                >
                  View Audit Dashboard <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}

          {/* STEP 6: AUDIT DASHBOARD (OUTPUT) */}
          {activeTab === 6 && (
            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="text-xs font-bold text-sky-600 uppercase tracking-wider">Phase 6: Audit Dashboard & Traceability</div>
                  <h2 className="text-2xl font-bold text-slate-900 mt-1">Centralized AI Recommendations & Cryptographic Log</h2>
                  <p className="text-sm text-slate-500">Immutable ledger tracking every pipeline decision, parameter, and hash verification.</p>
                </div>
                <button 
                  onClick={() => toast.success('Compliance Dossier exported as digital audit receipt.')}
                  className="px-3.5 py-2 bg-white hover:bg-slate-50 border border-slate-200 text-slate-700 font-semibold rounded-xl text-xs flex items-center gap-2 cursor-pointer"
                >
                  <Download className="w-3.5 h-3.5" /> Export Dossier
                </button>
              </div>

              {/* Central AI Recommendation Card */}
              <div className={`p-6 rounded-3xl border ${
                currentBid.score >= 80 
                  ? 'border-emerald-200 bg-emerald-50/30' 
                  : currentBid.score >= 60 
                    ? 'border-amber-200 bg-amber-50/30' 
                    : 'border-rose-200 bg-rose-50/30'
              }`}>
                <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-wider mb-2">
                  <Award className="w-4 h-4" /> AI Engine Recommendation
                </div>
                <h3 className="text-lg font-bold text-slate-900">
                  {currentBid.score >= 80 
                    ? 'RECOMMEND APPROVAL: Bidder Satisfies All Statutory & MII Guidelines'
                    : currentBid.score >= 60 
                      ? 'CONDITIONAL CLEARANCE: Requires Undertaking on OEM Expiry & Tax Regularity'
                      : 'RECOMMEND DISQUALIFICATION: Material Non-Compliance with Mandatory Tender Terms'}
                </h3>
                <p className="text-xs text-slate-600 mt-1">
                  Evaluated under General Financial Rules (GFR) 2017 and Public Procurement (Preference to Make in India) Order 2017.
                </p>
              </div>

              {/* Traceable Audit Log Table */}
              <div className="rounded-2xl border border-slate-200 overflow-hidden">
                <div className="bg-slate-50 px-4 py-3 border-b border-slate-200 text-xs font-bold text-slate-700 flex items-center justify-between">
                  <span>100% Traceable Immutable Audit Ledger</span>
                  <span className="font-mono text-slate-400 text-[11px]">SHA-256 Validated</span>
                </div>
                <div className="divide-y divide-slate-100 text-xs">
                  {currentBid.auditTrail.map((log) => (
                    <div key={log.id} className="p-4 hover:bg-slate-50/50 transition-colors">
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-1 mb-1">
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-slate-900">{log.stageName}</span>
                          <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-slate-100 text-slate-600 font-semibold">{log.actor}</span>
                        </div>
                        <span className="text-slate-400 text-[11px] font-mono">{new Date(log.timestamp).toLocaleTimeString()}</span>
                      </div>
                      <div className="font-semibold text-slate-800">{log.action}</div>
                      <div className="text-slate-500 mt-0.5">{log.details}</div>
                      <div className="mt-2 text-[10px] font-mono text-slate-400 truncate">
                        Block Hash: {log.sha256Hash}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="p-4 rounded-2xl bg-sky-50/50 border border-sky-100 flex items-center justify-between">
                <div className="text-xs text-sky-900">
                  <span className="font-bold">Next Stage:</span> Procurement Officer evaluates dossier and applies Final Decision (Approve / Disqualify).
                </div>
                <button
                  onClick={() => setActiveTab(7)}
                  className="px-4 py-2 bg-sky-600 hover:bg-sky-700 text-white text-xs font-semibold rounded-xl flex items-center gap-1.5 cursor-pointer"
                >
                  Proceed to Officer Decision <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          )}

          {/* STEP 7: FINAL DECISION (HUMAN REVIEW) */}
          {activeTab === 7 && (
            <div className="space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="text-xs font-bold text-rose-600 uppercase tracking-wider">Phase 7: Final Decision (Human Review)</div>
                  <h2 className="text-2xl font-bold text-slate-900 mt-1">Procurement Officer Adjudication Console</h2>
                  <p className="text-sm text-slate-500">Human-in-the-loop governance: Officer confirms or overrides AI recommendation with legally binding signature proof.</p>
                </div>
                <div>{getDecisionBadge(currentBid.decision.status)}</div>
              </div>

              {/* Current Decision Summary or Action Form */}
              {currentBid.decision.status !== 'PENDING' ? (
                <div className="p-6 rounded-3xl border border-slate-200 bg-slate-50 space-y-4">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-5 h-5 text-slate-700" />
                    <span className="text-sm font-bold text-slate-900">Official Decision Recorded</span>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
                    <div>
                      <span className="text-slate-400">Adjudicated By:</span>
                      <div className="font-bold text-slate-800 mt-0.5">{currentBid.decision.decidedBy}</div>
                    </div>
                    <div>
                      <span className="text-slate-400">Timestamp:</span>
                      <div className="font-mono text-slate-800 mt-0.5">{new Date(currentBid.decision.decidedAt || '').toLocaleString()}</div>
                    </div>
                    <div>
                      <span className="text-slate-400">Digital Signature Token:</span>
                      <div className="font-mono font-bold text-primary mt-0.5">{currentBid.decision.signatureProof}</div>
                    </div>
                  </div>

                  {currentBid.decision.remarks && (
                    <div className="text-xs bg-white p-3 rounded-xl border border-slate-200">
                      <span className="font-bold text-slate-700">Officer Remarks:</span> {currentBid.decision.remarks}
                    </div>
                  )}

                  {currentBid.decision.disqualificationReason && (
                    <div className="text-xs bg-rose-50 text-rose-800 p-3 rounded-xl border border-rose-200">
                      <span className="font-bold">Disqualification Grounds:</span> {currentBid.decision.disqualificationReason}
                    </div>
                  )}

                  <div className="pt-2">
                    <button
                      onClick={() => {
                        setDecisionTypeToConfirm('APPROVED');
                        setShowDecisionModal(true);
                      }}
                      className="text-xs text-primary hover:underline font-semibold cursor-pointer"
                    >
                      Re-open / Override Decision
                    </button>
                  </div>
                </div>
              ) : (
                <div className="p-6 rounded-3xl border border-slate-200 bg-gradient-to-r from-slate-900 to-indigo-950 text-white space-y-6">
                  <div>
                    <span className="text-xs text-primary-300 font-mono font-bold uppercase tracking-wider">Awaiting Human Sign-off</span>
                    <h3 className="text-xl font-bold mt-1">Review AI Findings and Formulate Binding Decision</h3>
                    <p className="text-xs text-slate-300 mt-1">
                      Both actions append an immutable entry to the cryptographic audit trail without altering any live database.
                    </p>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <button
                      onClick={() => {
                        setDecisionTypeToConfirm('APPROVED');
                        setShowDecisionModal(true);
                      }}
                      className="p-5 rounded-2xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-sm shadow-lg transition-all flex items-center justify-between cursor-pointer group"
                    >
                      <div className="text-left">
                        <div className="text-lg">APPROVE BID</div>
                        <div className="text-xs font-normal text-emerald-100 mt-0.5">Bid meets technical & statutory terms</div>
                      </div>
                      <CheckCircle2 className="w-6 h-6 group-hover:scale-110 transition-transform" />
                    </button>

                    <button
                      onClick={() => {
                        setDecisionTypeToConfirm('DISQUALIFIED');
                        setShowDecisionModal(true);
                      }}
                      className="p-5 rounded-2xl bg-rose-600 hover:bg-rose-500 text-white font-bold text-sm shadow-lg transition-all flex items-center justify-between cursor-pointer group"
                    >
                      <div className="text-left">
                        <div className="text-lg">DISQUALIFY BID</div>
                        <div className="text-xs font-normal text-rose-100 mt-0.5">Disqualify on non-compliance grounds</div>
                      </div>
                      <XCircle className="w-6 h-6 group-hover:scale-110 transition-transform" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

        </div>
      </div>

      {/* Decision Confirmation Modal */}
      {showDecisionModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-200">
            <h3 className="text-lg font-bold text-slate-900">
              Confirm {decisionTypeToConfirm === 'APPROVED' ? 'Bid Approval' : 'Bid Disqualification'}
            </h3>
            <p className="text-xs text-slate-500 mt-1">
              For bidder: <span className="font-semibold text-slate-800">{currentBid.bidderName}</span>
            </p>

            <div className="mt-4 space-y-4">
              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Adjudicating Officer Name / Title</label>
                <input
                  type="text"
                  value={officerName}
                  onChange={(e) => setOfficerName(e.target.value)}
                  className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>

              {decisionTypeToConfirm === 'DISQUALIFIED' && (
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Disqualification Grounds</label>
                  <select
                    value={disqualifyReason}
                    onChange={(e) => setDisqualifyReason(e.target.value)}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  >
                    <option value="Non-compliance with Make in India Class-I local content minimum requirements.">
                      Non-compliance with Make in India Class-I local content minimum requirements.
                    </option>
                    <option value="Failure in 3-Year Audited Average Turnover Solvency Threshold.">
                      Failure in 3-Year Audited Average Turnover Solvency Threshold.
                    </option>
                    <option value="Missing / Expired Manufacturer Authorization Form (MAF) from OEM.">
                      Missing / Expired Manufacturer Authorization Form (MAF) from OEM.
                    </option>
                    <option value="Cryptographic Hash Mismatch / Inconsistent Statutory Tax Data on GSTN.">
                      Cryptographic Hash Mismatch / Inconsistent Statutory Tax Data on GSTN.
                    </option>
                    <option value="Listed under Central Public Procurement Debarment / Blacklist.">
                      Listed under Central Public Procurement Debarment / Blacklist.
                    </option>
                  </select>
                </div>
              )}

              <div>
                <label className="text-xs font-bold text-slate-700 block mb-1">Officer Justification & Signature Remarks</label>
                <textarea
                  rows={3}
                  value={officerRemarks}
                  onChange={(e) => setOfficerRemarks(e.target.value)}
                  placeholder="Enter detailed technical or administrative remarks..."
                  className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-3">
              <button
                onClick={() => setShowDecisionModal(false)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100 cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={handleExecuteDecision}
                className={`px-5 py-2 rounded-xl text-xs font-bold text-white cursor-pointer ${
                  decisionTypeToConfirm === 'APPROVED' ? 'bg-emerald-600 hover:bg-emerald-700' : 'bg-rose-600 hover:bg-rose-700'
                }`}
              >
                Sign & Finalize {decisionTypeToConfirm}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* New Sample Bid Modal */}
      {showNewBidModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-xl w-full p-6 shadow-2xl border border-slate-200">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div>
                <h3 className="text-lg font-bold text-slate-900">Submit New Tender Bid (Sandbox)</h3>
                <p className="text-xs text-slate-500">Simulates real-time upload without touching production database.</p>
              </div>
              <button onClick={() => setShowNewBidModal(false)} className="text-slate-400 hover:text-slate-600 cursor-pointer">
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateBid} className="mt-4 space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Bidder Company Name</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Acme Tech Solutions Ltd"
                    value={newCompany}
                    onChange={(e) => setNewCompany(e.target.value)}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Tender Estimate (INR)</label>
                  <input
                    type="number"
                    required
                    value={newTenderValue}
                    onChange={(e) => setNewTenderValue(Number(e.target.value))}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Company PAN</label>
                  <input
                    type="text"
                    required
                    value={newPan}
                    onChange={(e) => setNewPan(e.target.value)}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 uppercase focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Company GSTIN</label>
                  <input
                    type="text"
                    required
                    value={newGst}
                    onChange={(e) => setNewGst(e.target.value)}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 uppercase focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Make in India %</label>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={newMii}
                    onChange={(e) => setNewMii(Number(e.target.value))}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">Annual Turnover (INR)</label>
                  <input
                    type="number"
                    value={newTurnover}
                    onChange={(e) => setNewTurnover(Number(e.target.value))}
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-slate-700 block mb-1">OEM Partner</label>
                  <input
                    type="text"
                    value={newOem}
                    onChange={(e) => setNewOem(e.target.value)}
                    placeholder="e.g. Dell / HP / Tata"
                    className="w-full text-xs p-2.5 rounded-xl border border-slate-300 focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>

              <div className="mt-6 flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setShowNewBidModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100 cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-xs font-bold bg-primary hover:bg-primary-600 text-white cursor-pointer shadow-md"
                >
                  Run Compliance Pipeline
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default ComplianceEngine;
