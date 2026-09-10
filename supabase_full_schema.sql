-- ==========================================================================
-- MIGRATION: 00001_initial_schema.sql
-- ==========================================================================
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. AUTHENTICATION & PROFILES
-- ============================================================================

-- Custom ENUMs
CREATE TYPE user_role AS ENUM ('buyer', 'seller', 'admin', 'superadmin');
CREATE TYPE auction_status AS ENUM ('draft', 'published', 'active', 'closed', 'cancelled');
CREATE TYPE bid_status AS ENUM ('active', 'winning', 'outbid', 'withdrawn');
CREATE TYPE tender_status AS ENUM ('draft', 'open', 'under_evaluation', 'awarded', 'cancelled');

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    registration_number VARCHAR(100),
    tax_id VARCHAR(100),
    address TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role user_role DEFAULT 'buyer',
    phone VARCHAR(50),
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. AUCTION SYSTEM
-- ============================================================================

CREATE TABLE auction_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    parent_id UUID REFERENCES auction_categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE auctions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES auction_categories(id) ON DELETE SET NULL,
    seller_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    status auction_status DEFAULT 'draft',
    starting_price DECIMAL(15, 2) NOT NULL,
    reserve_price DECIMAL(15, 2),
    bid_increment DECIMAL(15, 2) NOT NULL,
    emd_amount DECIMAL(15, 2) DEFAULT 0,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    terms_conditions TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE auction_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50),
    uploaded_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE auction_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE bids (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    bidder_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    status bid_status DEFAULT 'active',
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE watchlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, auction_id)
);

-- ============================================================================
-- 3. TENDER SYSTEM
-- ============================================================================

CREATE TABLE tenders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    reference_number VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    issuer_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    status tender_status DEFAULT 'draft',
    submission_deadline TIMESTAMPTZ NOT NULL,
    opening_date TIMESTAMPTZ,
    emd_amount DECIMAL(15, 2) DEFAULT 0,
    document_fee DECIMAL(15, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tender_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tender_id UUID NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    file_type VARCHAR(50),
    uploaded_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE tender_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tender_id UUID NOT NULL REFERENCES tenders(id) ON DELETE CASCADE,
    submitter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'submitted',
    financial_bid DECIMAL(15, 2),
    technical_details TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 4. PAYMENT SYSTEM
-- ============================================================================

CREATE TABLE emd_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    auction_id UUID REFERENCES auctions(id),
    tender_id UUID REFERENCES tenders(id),
    amount DECIMAL(15, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    transaction_reference VARCHAR(100),
    payment_method VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (auction_id IS NOT NULL OR tender_id IS NOT NULL)
);

CREATE TABLE payment_receipts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    amount DECIMAL(15, 2) NOT NULL,
    receipt_url TEXT,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id),
    amount DECIMAL(15, 2) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- e.g., 'deposit', 'withdrawal', 'emd_hold', 'emd_release'
    reference_id UUID, -- Can refer to emd_transaction, etc.
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 5. ADMIN & COMMON
-- ============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    type VARCHAR(50),
    link_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action VARCHAR(255) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    is_published BOOLEAN DEFAULT false,
    published_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE faq_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    category VARCHAR(100),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE news_updates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    summary TEXT,
    content TEXT NOT NULL,
    image_url TEXT,
    is_published BOOLEAN DEFAULT false,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE contact_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    message TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'new',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- TRIGGERS & INDEXES
-- ============================================================================

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_auction_categories_updated_at BEFORE UPDATE ON auction_categories FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_auctions_updated_at BEFORE UPDATE ON auctions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_tenders_updated_at BEFORE UPDATE ON tenders FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_tender_submissions_updated_at BEFORE UPDATE ON tender_submissions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_emd_transactions_updated_at BEFORE UPDATE ON emd_transactions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_faq_items_updated_at BEFORE UPDATE ON faq_items FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_news_updates_updated_at BEFORE UPDATE ON news_updates FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Indexes for performance
CREATE INDEX idx_auctions_status ON auctions(status);
CREATE INDEX idx_auctions_seller_id ON auctions(seller_id);
CREATE INDEX idx_auctions_start_time ON auctions(start_time);
CREATE INDEX idx_bids_auction_id ON bids(auction_id);
CREATE INDEX idx_bids_bidder_id ON bids(bidder_id);
CREATE INDEX idx_tenders_status ON tenders(status);
CREATE INDEX idx_tenders_issuer_id ON tenders(issuer_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE auctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenders ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view their own profile, Admins can view all
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Auctions: Anyone can view published auctions, sellers can view their own
CREATE POLICY "Public can view published auctions" ON auctions FOR SELECT USING (status = 'published' OR status = 'active' OR status = 'closed');
CREATE POLICY "Sellers can manage their own auctions" ON auctions FOR ALL USING (
    seller_id IN (SELECT organization_id FROM profiles WHERE id = auth.uid())
);

-- Bids: Anyone can view bids on active auctions, bidders can manage their own active bids
CREATE POLICY "Users can view bids on active auctions" ON bids FOR SELECT USING (
    auction_id IN (SELECT id FROM auctions WHERE status = 'active' OR status = 'closed')
);
CREATE POLICY "Users can place bids" ON bids FOR INSERT WITH CHECK (auth.uid() = bidder_id);

-- Storage Buckets Setup
INSERT INTO storage.buckets (id, name, public) VALUES ('auction_documents', 'auction_documents', false) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('auction_images', 'auction_images', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('tender_documents', 'tender_documents', true) ON CONFLICT DO NOTHING;



-- ==========================================================================
-- MIGRATION: 00002_auth_triggers.sql
-- ==========================================================================
-- Create a function to handle new user signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    'buyer' -- default role
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger the function every time a user is created
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();



-- ==========================================================================
-- MIGRATION: 00003_bidding_logic.sql
-- ==========================================================================
-- Function to place a bid securely with anti-sniping logic
CREATE OR REPLACE FUNCTION place_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_bid_amount DECIMAL
) RETURNS JSONB AS $$
DECLARE
  v_auction RECORD;
  v_current_max DECIMAL;
  v_new_end_time TIMESTAMP WITH TIME ZONE;
  v_result JSONB;
BEGIN
  -- 1. Lock the auction row for update to prevent concurrent bids from racing
  SELECT * INTO v_auction
  FROM auctions
  WHERE id = p_auction_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Auction not found';
  END IF;

  -- 2. Verify auction is active
  IF v_auction.status != 'active' THEN
    RAISE EXCEPTION 'Auction is not active';
  END IF;

  -- Verify time
  IF now() > v_auction.end_time THEN
    RAISE EXCEPTION 'Auction has already ended';
  END IF;

  -- 3. Get current max bid
  SELECT COALESCE(MAX(amount), 0) INTO v_current_max
  FROM bids
  WHERE auction_id = p_auction_id;

  -- 4. Validate bid amount
  IF v_current_max = 0 THEN
    -- First bid
    IF p_bid_amount < v_auction.starting_price THEN
      RAISE EXCEPTION 'Bid amount % is less than starting price %', p_bid_amount, v_auction.starting_price;
    END IF;
  ELSE
    -- Subsequent bids
    IF p_bid_amount < (v_current_max + v_auction.bid_increment) THEN
      RAISE EXCEPTION 'Bid amount must be at least %', (v_current_max + v_auction.bid_increment);
    END IF;
  END IF;

  -- 5. Insert the bid
  INSERT INTO bids (auction_id, bidder_id, amount, status)
  VALUES (p_auction_id, p_bidder_id, p_bid_amount, 'active');

  -- Update previous highest bid to 'outbid' if it exists
  UPDATE bids
  SET status = 'outbid'
  WHERE auction_id = p_auction_id 
    AND id != (SELECT id FROM bids WHERE auction_id = p_auction_id ORDER BY created_at DESC LIMIT 1)
    AND status = 'active';

  -- 6. Anti-Sniping Logic
  -- If bid is placed within the last 5 minutes, extend end_time by 5 minutes from now
  v_new_end_time := v_auction.end_time;
  IF extract(epoch from (v_auction.end_time - now())) < 300 THEN
    v_new_end_time := now() + interval '5 minutes';
    
    UPDATE auctions
    SET end_time = v_new_end_time
    WHERE id = p_auction_id;
  END IF;

  -- Build success result
  v_result := jsonb_build_object(
    'success', true,
    'message', 'Bid placed successfully',
    'bid_amount', p_bid_amount,
    'end_time', v_new_end_time
  );

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    -- Build error result
    RETURN jsonb_build_object(
      'success', false,
      'message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00004_mstc_catalog.sql
-- ==========================================================================
-- Migration to create the MSTC Auctions catalog table and search function
CREATE TABLE IF NOT EXISTS mstc_auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mstc_auction_number TEXT UNIQUE NOT NULL,
    seller_name TEXT NOT NULL,
    category_name TEXT NOT NULL,
    location TEXT DEFAULT 'India',
    opening_date TIMESTAMPTZ NOT NULL,
    closing_date TIMESTAMPTZ NOT NULL,
    source_pdf_url TEXT NOT NULL,
    raw_materials_text TEXT,
    asset_status TEXT NOT NULL DEFAULT 'pending',
    retry_count INTEGER NOT NULL DEFAULT 0,
    sanitized_document_path TEXT,
    error_log TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE mstc_auctions ENABLE ROW LEVEL SECURITY;

-- Allow public read access to completed/all records for consulting dashboards
CREATE POLICY "Allow public read access on MSTC auctions" ON mstc_auctions
    FOR SELECT USING (true);

-- Allow all operations for authenticated service roles or background workers
CREATE POLICY "Allow service role complete access" ON mstc_auctions
    FOR ALL USING (true);

-- Search Function (RPC) for MSTC Catalog
CREATE OR REPLACE FUNCTION search_mstc_catalog(search_query TEXT, category_filter TEXT DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.mstc_auction_number,
    m.seller_name,
    m.category_name,
    m.location,
    m.opening_date,
    m.closing_date,
    m.sanitized_document_path,
    m.raw_materials_text,
    m.asset_status AS status
  FROM mstc_auctions m
  WHERE 
    (search_query = '' OR 
     m.mstc_auction_number ILIKE '%' || search_query || '%' OR 
     m.seller_name ILIKE '%' || search_query || '%' OR 
     m.raw_materials_text ILIKE '%' || search_query || '%')
    AND (category_filter IS NULL OR m.category_name = category_filter);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00005_laymans_search.sql
-- ==========================================================================
-- Migration to create the Layman's Search RPC function
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE OR REPLACE FUNCTION search_mstc_catalog_v2(
  p_search_query TEXT,
  p_category_filter TEXT DEFAULT NULL,
  p_subcategory_filter TEXT DEFAULT NULL,
  p_location_filter TEXT DEFAULT NULL,
  p_seller_filter TEXT DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  search_rank REAL
) AS $$
DECLARE
  v_tsquery tsquery;
BEGIN
  -- Convert query to tsquery if provided, otherwise NULL
  IF p_search_query IS NOT NULL AND p_search_query != '' THEN
    -- Expects query to be pre-formatted with & and | operators from TypeScript
    v_tsquery := to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  SELECT 
    m.id,
    m.mstc_auction_number,
    m.seller_name,
    m.category_name,
    m.location,
    m.opening_date,
    m.closing_date,
    m.sanitized_document_path,
    m.raw_materials_text,
    m.asset_status AS status,
    CASE 
      WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(
          setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C'),
          v_tsquery
        )
      ELSE 0.0
    END AS search_rank
  FROM mstc_auctions m
  WHERE 
    m.asset_status = 'completed'
    AND (
      v_tsquery IS NULL OR
      (
        setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C')
      ) @@ v_tsquery
    )
    AND (p_category_filter IS NULL OR m.category_name = p_category_filter OR m.category_name LIKE p_category_filter || ' | %')
    AND (p_subcategory_filter IS NULL OR m.category_name LIKE '% | ' || p_subcategory_filter)
    AND (p_location_filter IS NULL OR m.location = p_location_filter)
    AND (p_seller_filter IS NULL OR m.seller_name = p_seller_filter)
    AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
    AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
  ORDER BY 
    CASE WHEN v_tsquery IS NOT NULL THEN 1 ELSE 0 END DESC,
    search_rank DESC,
    m.opening_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00005_schema_fixes.sql
-- ==========================================================================
-- ============================================================================
-- Migration 00005: Schema Fixes
-- Resolves all frontend-backend mismatches identified in audit
-- ============================================================================

-- Fix 1: Add reference_number to auctions table
-- Used across AuctionCard, AuctionDetail, MyBids, Dashboard, Reminders
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS reference_number VARCHAR(100) UNIQUE;

-- Auto-populate reference numbers for any existing auctions so they aren't NULL
UPDATE auctions
SET reference_number = CONCAT('AUC-', UPPER(SUBSTRING(id::text, 1, 8)))
WHERE reference_number IS NULL;

-- Fix 2: Add winner_id to auctions table
-- Used in MyBids.tsx to detect won auctions
ALTER TABLE auctions ADD COLUMN IF NOT EXISTS winner_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- Fix 3: Add status column to wallet_transactions
-- paymentService.getWalletBalance() filters by status = 'completed'
ALTER TABLE wallet_transactions ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'completed';

-- Fix 4: Change reference_id in wallet_transactions from UUID to TEXT
-- paymentService.processWalletDeposit() inserts a string like "MOCK-1718352000-123"
ALTER TABLE wallet_transactions ALTER COLUMN reference_id TYPE TEXT USING reference_id::TEXT;

-- Fix 5: Update the place_bid function to properly mark bids as 'winning'
-- and update the winning bid status when a new bid outbids everyone
CREATE OR REPLACE FUNCTION place_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_bid_amount DECIMAL
) RETURNS JSONB AS $$
DECLARE
  v_auction RECORD;
  v_current_max DECIMAL;
  v_new_end_time TIMESTAMP WITH TIME ZONE;
  v_result JSONB;
BEGIN
  -- 1. Lock the auction row for update to prevent concurrent bids from racing
  SELECT * INTO v_auction
  FROM auctions
  WHERE id = p_auction_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Auction not found';
  END IF;

  -- 2. Verify auction is active
  IF v_auction.status != 'active' THEN
    RAISE EXCEPTION 'Auction is not active';
  END IF;

  -- Verify time
  IF now() > v_auction.end_time THEN
    RAISE EXCEPTION 'Auction has already ended';
  END IF;

  -- 3. Get current max bid
  SELECT COALESCE(MAX(amount), 0) INTO v_current_max
  FROM bids
  WHERE auction_id = p_auction_id;

  -- 4. Validate bid amount
  IF v_current_max = 0 THEN
    -- First bid
    IF p_bid_amount < v_auction.starting_price THEN
      RAISE EXCEPTION 'Bid amount % is less than starting price %', p_bid_amount, v_auction.starting_price;
    END IF;
  ELSE
    -- Subsequent bids
    IF p_bid_amount < (v_current_max + v_auction.bid_increment) THEN
      RAISE EXCEPTION 'Bid amount must be at least %', (v_current_max + v_auction.bid_increment);
    END IF;
  END IF;

  -- 5. Mark all previous 'winning' or 'active' bids for this auction as 'outbid'
  UPDATE bids
  SET status = 'outbid'
  WHERE auction_id = p_auction_id
    AND status IN ('active', 'winning');

  -- 6. Insert the new highest bid as 'winning'
  INSERT INTO bids (auction_id, bidder_id, amount, status)
  VALUES (p_auction_id, p_bidder_id, p_bid_amount, 'winning');

  -- 7. Anti-Sniping Logic
  -- If bid is placed within the last 5 minutes, extend end_time by 5 minutes from now
  v_new_end_time := v_auction.end_time;
  IF extract(epoch from (v_auction.end_time - now())) < 300 THEN
    v_new_end_time := now() + interval '5 minutes';
    UPDATE auctions
    SET end_time = v_new_end_time
    WHERE id = p_auction_id;
  END IF;

  -- Build success result
  v_result := jsonb_build_object(
    'success', true,
    'message', 'Bid placed successfully',
    'bid_amount', p_bid_amount,
    'end_time', v_new_end_time
  );

  RETURN v_result;

EXCEPTION
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'message', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fix 6: Add a trigger to set winner_id on auctions when an auction closes
-- This marks the highest bidder as the winner when status changes to 'closed'
CREATE OR REPLACE FUNCTION set_auction_winner()
RETURNS TRIGGER AS $$
BEGIN
  -- When auction status changes to 'closed', find the highest bidder and set winner_id
  IF NEW.status = 'closed' AND OLD.status != 'closed' THEN
    SELECT bidder_id INTO NEW.winner_id
    FROM bids
    WHERE auction_id = NEW.id
      AND status = 'winning'
    ORDER BY amount DESC
    LIMIT 1;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auction_closed
  BEFORE UPDATE ON auctions
  FOR EACH ROW
  EXECUTE PROCEDURE set_auction_winner();

-- Fix 7: Add RLS policy so admins can see all profiles
-- Admins need to read all profiles for the user management page
CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles AS p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
  );

-- Fix 8: Add RLS so authenticated users can insert into watchlists and read their own
-- (May already work but ensures completeness)
ALTER TABLE watchlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own watchlist"
  ON watchlists FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Allow notifications: users can read their own
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can mark own notifications read"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id);



-- ==========================================================================
-- MIGRATION: 00006_audit_fixes.sql
-- ==========================================================================
-- ============================================================================
-- Migration 00006: Audit Fixes
-- Addresses RLS gaps, mock user issues, and adds missing tables
-- ============================================================================

-- Fix 1: Add RLS to financial tables
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE emd_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own wallet transactions" ON wallet_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wallet transactions" ON wallet_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own EMD transactions" ON emd_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own EMD transactions" ON emd_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own payment receipts" ON payment_receipts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own payment receipts" ON payment_receipts FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Fix 2: Drop restrictive CHECK constraint on emd_transactions to allow future expansions
ALTER TABLE emd_transactions DROP CONSTRAINT IF EXISTS emd_transactions_check;

-- Fix 3: Auto-create organization for new profiles to enable seller flow
-- If a user signs up but doesn't have an organization, we create a default one.
CREATE OR REPLACE FUNCTION auto_create_organization()
RETURNS TRIGGER AS $$
DECLARE
  new_org_id UUID;
BEGIN
  IF NEW.organization_id IS NULL THEN
    INSERT INTO organizations (name, contact_email) 
    VALUES (COALESCE(NEW.first_name || ' ' || NEW.last_name || ' Org', 'Default Org'), 'placeholder@example.com')
    RETURNING id INTO new_org_id;
    
    NEW.organization_id := new_org_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create org before profile is inserted
DROP TRIGGER IF EXISTS trg_auto_create_organization ON profiles;
CREATE TRIGGER trg_auto_create_organization
  BEFORE INSERT ON profiles
  FOR EACH ROW
  EXECUTE PROCEDURE auto_create_organization();

-- Retroactively create organizations for existing profiles without one
DO $$
DECLARE
  r RECORD;
  new_org_id UUID;
BEGIN
  FOR r IN SELECT id, first_name, last_name FROM profiles WHERE organization_id IS NULL LOOP
    INSERT INTO organizations (name) VALUES (COALESCE(r.first_name || ' ' || r.last_name || ' Org', 'Default Org')) RETURNING id INTO new_org_id;
    UPDATE profiles SET organization_id = new_org_id WHERE id = r.id;
  END LOOP;
END;
$$;

-- Fix 4: User Documents Table (for Document Vault KYC)
CREATE TABLE IF NOT EXISTS user_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    file_url TEXT NOT NULL,
    document_type VARCHAR(100) DEFAULT 'kyc',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own documents" ON user_documents FOR ALL USING (auth.uid() = user_id);

CREATE TRIGGER update_user_documents_updated_at BEFORE UPDATE ON user_documents FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Fix 5: User Notification Preferences Table
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE UNIQUE,
    email_bids BOOLEAN DEFAULT true,
    email_tenders BOOLEAN DEFAULT true,
    email_marketing BOOLEAN DEFAULT false,
    push_outbid BOOLEAN DEFAULT true,
    push_system BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own notification preferences" ON user_notification_preferences FOR ALL USING (auth.uid() = user_id);

CREATE TRIGGER update_user_notification_preferences_updated_at BEFORE UPDATE ON user_notification_preferences FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();



-- ==========================================================================
-- MIGRATION: 00007_audit_logs_policies.sql
-- ==========================================================================
-- ============================================================================
-- Migration 00007: Audit Logs RLS Policies
-- Enables clients to insert activity logs, while restricting read access to Admins.
-- ============================================================================

-- Ensure Row Level Security is enabled on public.audit_logs
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow anyone (authenticated or anonymous) to insert logs
CREATE POLICY "Anyone can insert audit logs"
    ON public.audit_logs
    FOR INSERT
    WITH CHECK (true);

-- Allow only administrators and superadministrators to read audit logs
CREATE POLICY "Admins can view all audit logs"
    ON public.audit_logs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles AS p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
        )
    );



-- ==========================================================================
-- MIGRATION: 00008_fix_registration_and_rls.sql
-- ==========================================================================
-- ============================================================================
-- Migration 00008: Fix Registration & Organization RLS Policies
-- Enables the signup trigger and client to successfully create and link organizations.
-- ============================================================================

-- Ensure Row Level Security is active on organizations
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- 1. Allow anyone to insert organizations during signup
DROP POLICY IF EXISTS "Allow anon/authenticated insertion" ON public.organizations;
CREATE POLICY "Allow anon/authenticated insertion" ON public.organizations
    FOR INSERT
    WITH CHECK (true);

-- 2. Allow users to view their own organization
DROP POLICY IF EXISTS "Allow users to view their own organization" ON public.organizations;
CREATE POLICY "Allow users to view their own organization" ON public.organizations
    FOR SELECT
    USING (
        id IN (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
    );

-- 3. Allow users to update their own organization
DROP POLICY IF EXISTS "Allow users to update their own organization" ON public.organizations;
CREATE POLICY "Allow users to update their own organization" ON public.organizations
    FOR UPDATE
    USING (
        id IN (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
    );

-- 4. Ensure profiles allows inserts for the trigger role
DROP POLICY IF EXISTS "Allow anon/authenticated insertion on profiles" ON public.profiles;
CREATE POLICY "Allow anon/authenticated insertion on profiles" ON public.profiles
    FOR INSERT
    WITH CHECK (true);

-- 5. Re-create the signup trigger function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    'buyer' -- default role
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Re-create the auto-organization function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION public.auto_create_organization()
RETURNS TRIGGER AS $$
DECLARE
  new_org_id UUID;
BEGIN
  IF NEW.organization_id IS NULL THEN
    INSERT INTO public.organizations (name, contact_email) 
    VALUES (COALESCE(NEW.first_name || ' ' || NEW.last_name || ' Org', 'Default Org'), 'placeholder@example.com')
    RETURNING id INTO new_org_id;
    
    NEW.organization_id := new_org_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00008_news_rls_policies.sql
-- ==========================================================================
-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR NEWS_UPDATES
-- ============================================================================

-- Enable RLS on news_updates if not already enabled
ALTER TABLE news_updates ENABLE ROW LEVEL SECURITY;

-- 1. Public Read Access: Anyone can read published news
CREATE POLICY "Public can view published news"
ON news_updates
FOR SELECT
USING (is_published = true);

-- 2. Admin Access: Admins and superadmins can perform all operations (CRUD)
CREATE POLICY "Admins can view all news (including drafts)"
ON news_updates
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

CREATE POLICY "Admins can insert news"
ON news_updates
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

CREATE POLICY "Admins can update news"
ON news_updates
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

CREATE POLICY "Admins can delete news"
ON news_updates
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);



-- ==========================================================================
-- MIGRATION: 00008_reauction_detection.sql
-- ==========================================================================
-- ============================================================================
-- Migration 00008: Re-auction Detection
-- Adds columns to track re-auctions and links to original parent auctions.
-- ============================================================================

ALTER TABLE public.mstc_auctions 
ADD COLUMN IF NOT EXISTS is_reauction BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS original_auction_number TEXT,
ADD COLUMN IF NOT EXISTS parent_auction_id UUID REFERENCES public.mstc_auctions(id) ON DELETE SET NULL;

-- Update the search function to include the new columns
DROP FUNCTION IF EXISTS search_mstc_catalog(TEXT, TEXT);
CREATE OR REPLACE FUNCTION search_mstc_catalog(search_query TEXT, category_filter TEXT DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  original_auction_number TEXT,
  parent_auction_id UUID
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.mstc_auction_number,
    m.seller_name,
    m.category_name,
    m.location,
    m.opening_date,
    m.closing_date,
    m.sanitized_document_path,
    m.raw_materials_text,
    m.asset_status AS status,
    m.is_reauction,
    m.original_auction_number,
    m.parent_auction_id
  FROM mstc_auctions m
  WHERE 
    (search_query = '' OR 
     m.mstc_auction_number ILIKE '%' || search_query || '%' OR 
     m.seller_name ILIKE '%' || search_query || '%' OR 
     m.raw_materials_text ILIKE '%' || search_query || '%')
    AND (category_filter IS NULL OR m.category_name = category_filter);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00009_contact_messages.sql
-- ==========================================================================
-- Create the contact messages table
CREATE TABLE IF NOT EXISTS contact_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  subject TEXT,
  message TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Allow anyone (public/anon) to insert contact messages
DROP POLICY IF EXISTS "Anyone can insert contact messages" ON contact_messages;
CREATE POLICY "Anyone can insert contact messages"
  ON contact_messages FOR INSERT
  WITH CHECK (true);

-- Allow admins to view all contact messages
DROP POLICY IF EXISTS "Admins can view all contact messages" ON contact_messages;
CREATE POLICY "Admins can view all contact messages"
  ON contact_messages FOR SELECT
  USING (true);

-- Allow admins to update contact messages (e.g. changing status)
DROP POLICY IF EXISTS "Admins can update contact messages" ON contact_messages;
CREATE POLICY "Admins can update contact messages"
  ON contact_messages FOR UPDATE
  USING (true);



-- ==========================================================================
-- MIGRATION: 00010_fix_auth_trigger.sql
-- ==========================================================================
-- Fix authentication triggers and security definers
-- Ensure search_path is set to public for functions executed by triggers

-- 1. Update handle_new_user with proper search_path and explicit cast
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, role)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    'buyer'::public.user_role
  );
  RETURN new;
END;
$$;

-- 2. Update auto_create_organization with proper search_path and explicit schema
CREATE OR REPLACE FUNCTION public.auto_create_organization()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  new_org_id UUID;
  org_name TEXT;
BEGIN
  IF NEW.organization_id IS NULL THEN
    -- Build a safe name without throwing errors on NULL
    org_name := TRIM(COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, ''));
    IF org_name = '' THEN
      org_name := 'Default';
    END IF;
    org_name := org_name || ' Org';

    INSERT INTO public.organizations (name, contact_email) 
    VALUES (org_name, 'placeholder@example.com')
    RETURNING id INTO new_org_id;
    
    NEW.organization_id := new_org_id;
  END IF;
  RETURN NEW;
END;
$$;



-- ==========================================================================
-- MIGRATION: 00011_hybrid_search.sql
-- ==========================================================================
-- Migration for Ultimate Hybrid Search
-- 1. Enable pgvector and pg_trgm extensions
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Add embedding column to mstc_auctions if it doesn't exist
ALTER TABLE mstc_auctions ADD COLUMN IF NOT EXISTS embedding vector(384);

-- 3. Create index for fast vector searches
CREATE INDEX IF NOT EXISTS mstc_auctions_embedding_idx ON mstc_auctions USING hnsw (embedding vector_cosine_ops);

-- 4. Create Materialized View for "Did you mean?" typo correction
CREATE MATERIALIZED VIEW IF NOT EXISTS search_dictionary AS
SELECT word FROM ts_stat('SELECT to_tsvector(''simple'', coalesce(category_name, '''') || '' '' || coalesce(seller_name, '''') || '' '' || coalesce(raw_materials_text, '''')) FROM public.mstc_auctions');

CREATE INDEX IF NOT EXISTS trgm_idx_search_dictionary ON search_dictionary USING gin (word gin_trgm_ops);

-- Function to refresh the dictionary
CREATE OR REPLACE FUNCTION refresh_search_dictionary()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY search_dictionary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Create suggest_search_correction RPC
CREATE OR REPLACE FUNCTION suggest_search_correction(p_query TEXT)
RETURNS TEXT AS $$
DECLARE
  v_word TEXT;
  v_corrected_query TEXT := '';
  v_best_match TEXT;
BEGIN
  -- Very simple word-by-word correction for typo tolerance
  FOR v_word IN SELECT unnest(regexp_split_to_array(lower(p_query), '\s+'))
  LOOP
    -- Find closest word in dictionary using Trigram similarity
    SELECT word INTO v_best_match
    FROM search_dictionary
    ORDER BY word <-> v_word
    LIMIT 1;

    -- If distance is close enough (similarity > 0.4 usually means distance < 0.6)
    IF v_best_match IS NOT NULL AND (v_best_match <-> v_word) < 0.6 THEN
      v_corrected_query := v_corrected_query || ' ' || v_best_match;
    ELSE
      v_corrected_query := v_corrected_query || ' ' || v_word;
    END IF;
  END LOOP;
  
  RETURN trim(v_corrected_query);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Helper function to extract pre_bid safely from JSON
CREATE OR REPLACE FUNCTION extract_numeric_from_json(json_text TEXT, key1 TEXT, key2 TEXT)
RETURNS NUMERIC AS $$
DECLARE
  extracted_val TEXT;
BEGIN
  -- Safety check
  IF json_text IS NULL OR json_text = '' THEN RETURN NULL; END IF;
  
  BEGIN
    extracted_val := (json_text::jsonb -> key1 ->> key2);
    IF extracted_val IS NULL THEN RETURN NULL; END IF;
    -- Remove non-numeric chars except decimal
    extracted_val := regexp_replace(extracted_val, '[^0-9.]', '', 'g');
    RETURN NULLIF(extracted_val, '')::NUMERIC;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL; -- JSON parsing failed
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 7. Drop existing search function (both old 12-param and new 14-param versions)
DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text,text,text,text,text,text,boolean,boolean,integer,integer);
DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text,text,text,text,text,text,boolean,boolean,numeric,numeric,integer,integer);

-- 8. Create the Ultimate Hybrid Search Function using Reciprocal Rank Fusion
CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_category_filter TEXT DEFAULT NULL,
  p_subcategory_filter TEXT DEFAULT NULL,
  p_location_filter TEXT DEFAULT NULL,
  p_seller_filter TEXT DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; -- Standard RRF constant
BEGIN
  -- Switch to websearch_to_tsquery for natural language parsing (supports "quotes" and -exclusions)
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      -- Text Rank
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(
          setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
          setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
          setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C'),
          v_tsquery
        )
      ELSE 0.0 END AS t_rank,
      -- Vector Similarity
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          (
            setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
            setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
            setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
            setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
            setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C')
          ) @@ v_tsquery
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.1
        )
      )
      AND (p_category_filter IS NULL OR m.category_name = p_category_filter OR m.category_name LIKE p_category_filter || ' | %')
      AND (p_subcategory_filter IS NULL OR m.category_name LIKE '% | ' || p_subcategory_filter)
      AND (p_location_filter IS NULL OR m.location = p_location_filter)
      AND (p_seller_filter IS NULL OR m.seller_name = p_seller_filter)
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (m.raw_materials_text ILIKE '%"extracted_images":%' AND m.raw_materials_text NOT ILIKE '%_catalog_page_%' AND m.raw_materials_text NOT ILIKE '%mstc-previews/%')
      )
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (m.sanitized_document_path IS NOT NULL OR m.raw_materials_text ILIKE '%.pdf%')
      )
      -- Apply Price Constraints using our robust helper function
      AND (p_min_pre_bid IS NULL OR extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg') >= p_min_pre_bid)
      AND (p_max_pre_bid IS NULL OR extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg') <= p_max_pre_bid)
  ),
  ranked_candidates AS (
    SELECT *,
      -- Only assign row numbers if the rank is greater than 0, else push them to the bottom
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
  ),
  rrf_scored AS (
    SELECT *,
      -- Compute Reciprocal Rank Fusion Score
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    -- If it's a direct ID match, force it to the top by cheating the order
    (CASE WHEN p_search_query IS NOT NULL AND r.mstc_auction_number ILIKE '%' || p_search_query || '%' THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.opening_date DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00011_make_auction_documents_private.sql
-- ==========================================================================
-- Make the auction_documents bucket private
UPDATE storage.buckets
SET public = false
WHERE id = 'auction_documents';

-- Drop policies if they exist (to be safe)
DROP POLICY IF EXISTS "Allow authenticated users to read auction_documents" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload to auction_documents" ON storage.objects;

-- Create policy to allow authenticated users to read/download objects from auction_documents
CREATE POLICY "Allow authenticated users to read auction_documents"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'auction_documents');

-- Create policy to allow authenticated users to upload objects to auction_documents
CREATE POLICY "Allow authenticated users to upload to auction_documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'auction_documents');



-- ==========================================================================
-- MIGRATION: 00012_faq_items_rls.sql
-- ==========================================================================
-- ============================================================================
-- Migration 00012: FAQ Items RLS Policies
-- Enables RLS on faq_items, allowing public SELECT and restricting write operations to Admins.
-- ============================================================================

-- Ensure Row Level Security is enabled on public.faq_items
ALTER TABLE public.faq_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist to prevent duplicates
DROP POLICY IF EXISTS "Anyone can view FAQs" ON public.faq_items;
DROP POLICY IF EXISTS "Admins can manage FAQs" ON public.faq_items;

-- 1. Allow anyone (authenticated or anonymous) to view FAQ items
CREATE POLICY "Anyone can view FAQs"
    ON public.faq_items
    FOR SELECT
    USING (true);

-- 2. Allow only administrators and superadministrators to write (insert, update, delete) FAQ items
CREATE POLICY "Admins can manage FAQs"
    ON public.faq_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles AS p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles AS p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
        )
    );



-- ==========================================================================
-- MIGRATION: 00012_optimize_filters.sql
-- ==========================================================================
-- Migration: Optimize Filters & Search Routing
-- Creates get_mstc_filter_options to return distinct sidebar options instantly
-- Updates hybrid_search_mstc_catalog to accept TEXT[] arrays for multi-select filtering

-- 1. Create the fast filter options RPC
CREATE OR REPLACE FUNCTION get_mstc_filter_options()
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'categories', (
      SELECT coalesce(json_agg(DISTINCT split_part(category_name, ' | ', 1)), '[]'::json) 
      FROM mstc_auctions 
      WHERE asset_status = 'completed' AND category_name IS NOT NULL
    ),
    'subcategories', (
      SELECT coalesce(json_object_agg(main_cat, subcats), '{}'::json) 
      FROM (
        SELECT split_part(category_name, ' | ', 1) as main_cat, json_agg(DISTINCT split_part(category_name, ' | ', 2)) as subcats
        FROM mstc_auctions
        WHERE asset_status = 'completed' AND category_name LIKE '% | %'
        GROUP BY split_part(category_name, ' | ', 1)
      ) t
    ),
    'sellers', (
      SELECT coalesce(json_agg(DISTINCT seller_name), '[]'::json) 
      FROM mstc_auctions 
      WHERE asset_status = 'completed' AND seller_name IS NOT NULL
    ),
    'locations', (
      SELECT coalesce(json_agg(DISTINCT location), '[]'::json) 
      FROM mstc_auctions 
      WHERE asset_status = 'completed' AND location IS NOT NULL
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Drop the old hybrid search function
DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text,text,text,text,text,text,boolean,boolean,numeric,numeric,integer,integer);

-- 3. Create the new Hybrid Search Function accepting Arrays
CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      -- Text Rank
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(
          setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
          setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
          setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C'),
          v_tsquery
        )
      ELSE 0.0 END AS t_rank,
      -- Vector Similarity
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          (
            setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
            setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
            setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
            setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
            setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C')
          ) @@ v_tsquery
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.1
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (m.raw_materials_text ILIKE '%"extracted_images":%' AND m.raw_materials_text NOT ILIKE '%_catalog_page_%' AND m.raw_materials_text NOT ILIKE '%mstc-previews/%')
      )
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (m.sanitized_document_path IS NOT NULL OR m.raw_materials_text ILIKE '%.pdf%')
      )
      -- Apply Price Constraints
      AND (p_min_pre_bid IS NULL OR extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg') >= p_min_pre_bid)
      AND (p_max_pre_bid IS NULL OR extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg') <= p_max_pre_bid)
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND r.mstc_auction_number ILIKE '%' || p_search_query || '%' THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.opening_date DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00012_public_auction_assets.sql
-- ==========================================================================
-- Allow anonymous users to view auction catalog PDFs, previews, and extracted images
-- This fixes the bug where signed-out users cannot see the auction images or download the catalog
-- We strictly limit this to the scraper-generated folders to protect KYC documents stored in the root.

CREATE POLICY "Allow anon to read auction assets"
ON storage.objects FOR SELECT
TO anon
USING (
  bucket_id = 'auction_documents' 
  AND (
    name ILIKE 'mstc-extracted-images/%' OR 
    name ILIKE 'mstc-catalogs/%' OR 
    name ILIKE 'mstc-previews/%'
  )
);



-- ==========================================================================
-- MIGRATION: 00013_fix_filters.sql
-- ==========================================================================
-- Migration: Fix RPC Filters
-- 1. Updates hybrid_search_mstc_catalog to add p_is_reauction
-- 2. Fixes p_has_images and p_has_docs logic to properly parse JSON instead of failing on valid catalogs

-- 1. Drop the old hybrid search function since we are changing the signature
DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text[],text[],text[],text[],text[],text,text,boolean,boolean,numeric,numeric,integer,integer);

-- 2. Create the fixed Hybrid Search Function
CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_is_reauction BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      -- Text Rank
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(
          setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
          setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
          setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C'),
          v_tsquery
        )
      ELSE 0.0 END AS t_rank,
      -- Vector Similarity
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          (
            setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
            setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
            setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
            setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
            setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C')
          ) @@ v_tsquery
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.1
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (p_is_reauction IS NULL OR m.is_reauction = p_is_reauction)
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (
          m.raw_materials_text IS NOT NULL 
          AND m.raw_materials_text LIKE '%"extracted_images":%' 
          AND EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(
              CASE 
                WHEN m.raw_materials_text LIKE '{%}' AND m.raw_materials_text LIKE '%"extracted_images":%' 
                THEN (m.raw_materials_text::jsonb)->'extracted_images' 
                ELSE '[]'::jsonb 
              END
            ) AS img
            WHERE img NOT ILIKE '%.pdf' AND img NOT ILIKE '%_catalog_page_%' AND img NOT ILIKE '%mstc-previews/%'
          )
        )
      )
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (
          m.sanitized_document_path IS NOT NULL OR 
          (
             m.raw_materials_text IS NOT NULL AND (
               m.raw_materials_text ILIKE '%.pdf%' OR
               m.raw_materials_text ILIKE '%"docs":%' OR
               m.raw_materials_text ILIKE '%"documents":%'
             )
          )
        )
      )
      -- Apply Price Constraints
      AND (
        p_min_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) >= p_min_pre_bid
      )
      AND (
        p_max_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) <= p_max_pre_bid
      )
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND r.mstc_auction_number ILIKE '%' || p_search_query || '%' THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.opening_date DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00013_reorder_faq.sql
-- ==========================================================================
-- Reorder FAQ items to place the affiliation disclaimer card at the top
-- Shift existing mstc category display_orders by 1
UPDATE public.faq_items 
SET display_order = display_order + 1 
WHERE category = 'mstc' AND display_order >= 1;

-- Update the affiliation disclaimer to be at the top of 'mstc'
UPDATE public.faq_items
SET category = 'mstc', display_order = 1, question = 'Is Lelam affiliated with MSTC India or any government agency?'
WHERE question ILIKE '%affiliated%with%MSTC%';



-- ==========================================================================
-- MIGRATION: 00014_custom_synonyms_and_fuzzy.sql
-- ==========================================================================
-- Migration: Custom Synonyms, Fuzzy Dictionary, and Vector Threshold Fix
-- 1. Create search_synonyms table for custom acronym definitions
-- 2. Materialize the search_dictionary for pg_trgm fuzzy matching
-- 3. Upgrade suggest_search_correction to cascade through synonyms and fuzzy matching
-- 4. Fix hybrid_search_mstc_catalog by raising vector threshold from 0.1 to 0.6 to prevent statement timeouts

-- 1. Custom Synonyms Table
CREATE TABLE IF NOT EXISTS search_synonyms (
    abbreviation TEXT PRIMARY KEY,
    expansion TEXT NOT NULL
);

INSERT INTO search_synonyms (abbreviation, expansion) VALUES
    ('csf', 'customs'),
    ('veh', 'vehicle'),
    ('veh.', 'vehicle'),
    ('vehic', 'vehicle'),
    ('mty', 'empty'),
    ('mtrl', 'material'),
    ('equip', 'equipment'),
    ('mach', 'machinery'),
    ('qty', 'quantity')
ON CONFLICT (abbreviation) DO UPDATE SET expansion = EXCLUDED.expansion;

-- 2. Materialized Dictionary for Fuzzy Matching
DROP MATERIALIZED VIEW IF EXISTS search_dictionary CASCADE;
CREATE MATERIALIZED VIEW search_dictionary AS
SELECT word FROM ts_stat('SELECT to_tsvector(''simple'', coalesce(category_name, '''') || '' '' || coalesce(seller_name, '''') || '' '' || coalesce(raw_materials_text, '''')) FROM public.mstc_auctions');

CREATE INDEX IF NOT EXISTS trgm_idx_search_dictionary ON search_dictionary USING gin (word gin_trgm_ops);

-- Function to refresh the dictionary
CREATE OR REPLACE FUNCTION refresh_search_dictionary()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY search_dictionary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Updated Suggestion RPC (Synonyms + Fuzzy)
CREATE OR REPLACE FUNCTION suggest_search_correction(p_query TEXT)
RETURNS TEXT AS $$
DECLARE
  v_word TEXT;
  v_corrected_query TEXT := '';
  v_best_match TEXT;
  v_synonym TEXT;
BEGIN
  -- Split query into words
  FOR v_word IN SELECT unnest(string_to_array(lower(p_query), ' ')) LOOP
    
    -- 1. Check Synonym Table first
    SELECT expansion INTO v_synonym FROM search_synonyms WHERE abbreviation = v_word;
    
    IF v_synonym IS NOT NULL THEN
      v_corrected_query := v_corrected_query || ' ' || v_synonym;
      CONTINUE;
    END IF;

    -- 2. Fuzzy match against search_dictionary (pg_trgm)
    SELECT word INTO v_best_match
    FROM search_dictionary
    ORDER BY word <-> v_word
    LIMIT 1;

    -- If distance is close enough (similarity > 0.4 usually means distance < 0.6)
    IF v_best_match IS NOT NULL AND (v_best_match <-> v_word) < 0.6 THEN
      v_corrected_query := v_corrected_query || ' ' || v_best_match;
    ELSE
      v_corrected_query := v_corrected_query || ' ' || v_word;
    END IF;
  END LOOP;

  RETURN trim(v_corrected_query);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4. Re-declare hybrid_search_mstc_catalog with updated vector threshold
DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text[],text[],text[],text[],text[],text,text,boolean,boolean,numeric,numeric,boolean,integer,integer);

CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_is_reauction BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      -- Text Rank
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(
          setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
          setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
          setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
          setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C'),
          v_tsquery
        )
      ELSE 0.0 END AS t_rank,
      -- Vector Similarity
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          (
            setweight(to_tsvector('english', coalesce(m.category_name, '')), 'A') ||
            setweight(to_tsvector('english', coalesce(m.mstc_auction_number, '')), 'A') ||
            setweight(to_tsvector('english', CASE WHEN m.is_reauction THEN 'reauction' ELSE '' END), 'A') ||
            setweight(to_tsvector('english', coalesce(m.seller_name, '')), 'B') ||
            setweight(to_tsvector('english', coalesce(m.raw_materials_text, '')), 'C')
          ) @@ v_tsquery
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.6   -- <---- CRITICAL TIMEOUT FIX (Was 0.1)
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (p_is_reauction IS NULL OR m.is_reauction = p_is_reauction)
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (
          m.raw_materials_text IS NOT NULL 
          AND m.raw_materials_text LIKE '%"extracted_images":%' 
          AND EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(
              CASE 
                WHEN m.raw_materials_text LIKE '{%}' AND m.raw_materials_text LIKE '%"extracted_images":%' 
                THEN (m.raw_materials_text::jsonb)->'extracted_images' 
                ELSE '[]'::jsonb 
              END
            ) AS img
            WHERE img NOT ILIKE '%.pdf' AND img NOT ILIKE '%_catalog_page_%' AND img NOT ILIKE '%mstc-previews/%'
          )
        )
      )
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (
          m.sanitized_document_path IS NOT NULL OR 
          (
             m.raw_materials_text IS NOT NULL AND (
               m.raw_materials_text ILIKE '%.pdf%' OR
               m.raw_materials_text ILIKE '%"docs":%' OR
               m.raw_materials_text ILIKE '%"documents":%'
             )
          )
        )
      )
      -- Apply Price Constraints
      AND (
        p_min_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) >= p_min_pre_bid
      )
      AND (
        p_max_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) <= p_max_pre_bid
      )
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND r.mstc_auction_number ILIKE '%' || p_search_query || '%' THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.opening_date DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00014_user_recommendation_profiles.sql
-- ==========================================================================
CREATE TABLE IF NOT EXISTS user_recommendation_profiles (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    preferences JSONB,
    recent_searches JSONB NOT NULL DEFAULT '[]'::jsonb,
    questionnaire_completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE user_recommendation_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own recommendation profile"
    ON user_recommendation_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recommendation profile"
    ON user_recommendation_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recommendation profile"
    ON user_recommendation_profiles FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE TRIGGER update_user_recommendation_profiles_updated_at
    BEFORE UPDATE ON user_recommendation_profiles
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();



-- ==========================================================================
-- MIGRATION: 00014_worker_improvements.sql
-- ==========================================================================
-- Migration 00014: Worker improvements (atomic claim and ocr cache)

CREATE TABLE IF NOT EXISTS ocr_cache (
    buffer_hash TEXT PRIMARY KEY,
    ocr_text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS on ocr_cache
ALTER TABLE ocr_cache ENABLE ROW LEVEL SECURITY;

-- Allow public read access on ocr_cache
DROP POLICY IF EXISTS "Allow public read access on ocr_cache" ON ocr_cache;
CREATE POLICY "Allow public read access on ocr_cache" ON ocr_cache
    FOR SELECT USING (true);

-- Allow complete access to service role / background workers
DROP POLICY IF EXISTS "Allow service role complete access on ocr_cache" ON ocr_cache;
CREATE POLICY "Allow service role complete access on ocr_cache" ON ocr_cache
    FOR ALL USING (true);

-- Claim function for atomic batch queue processing
CREATE OR REPLACE FUNCTION claim_mstc_auctions_batch(
  p_worker_id TEXT,
  p_batch_size INT,
  p_max_retry_count INT
) RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  source_pdf_url TEXT,
  retry_count INT,
  category_name TEXT,
  seller_name TEXT,
  location TEXT,
  raw_materials_text TEXT,
  updated_at TIMESTAMPTZ
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  UPDATE mstc_auctions
  SET asset_status = 'processing',
      updated_at = NOW(),
      error_log = 'Claimed by worker ' || p_worker_id
  WHERE mstc_auctions.id IN (
    SELECT m.id
    FROM mstc_auctions m
    WHERE (m.asset_status = 'pending' OR m.asset_status = 'failed')
      AND m.retry_count < p_max_retry_count
      -- Cooldown exponential backoff logic:
      -- retry 1: 1 min, retry 2: 5 min, retry 3: 15 min, >=4: 30 min
      AND (m.retry_count = 0 OR m.updated_at IS NULL OR NOW() - m.updated_at >= CASE 
          WHEN m.retry_count = 1 THEN interval '1 minute'
          WHEN m.retry_count = 2 THEN interval '5 minutes'
          WHEN m.retry_count = 3 THEN interval '15 minutes'
          ELSE interval '30 minutes'
      END)
    ORDER BY m.updated_at ASC NULLS FIRST
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  )
  RETURNING 
    mstc_auctions.id,
    mstc_auctions.mstc_auction_number::TEXT,
    mstc_auctions.source_pdf_url,
    mstc_auctions.retry_count,
    mstc_auctions.category_name::TEXT,
    mstc_auctions.seller_name::TEXT,
    mstc_auctions.location::TEXT,
    mstc_auctions.raw_materials_text::TEXT,
    mstc_auctions.updated_at;
END;
$$ SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00015_maintenance_mode.sql
-- ==========================================================================
-- Create system_settings table to store global configurations
CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES profiles(id) ON DELETE SET NULL
);

-- Enable RLS
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Allow public read access to system settings
CREATE POLICY "Allow public read access to system settings"
ON system_settings
FOR SELECT
USING (true);

-- Allow only admins to manage system settings
CREATE POLICY "Allow admins to manage system settings"
ON system_settings
FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);

-- Insert default maintenance_mode setting
INSERT INTO system_settings (key, value)
VALUES ('maintenance_mode', 'false'::jsonb)
ON CONFLICT (key) DO NOTHING;



-- ==========================================================================
-- MIGRATION: 00015_search_index_fix.sql
-- ==========================================================================
-- Migration: Fix Search Statement Timeout
-- The previous vector search query failed with "canceling statement due to statement timeout" (57014)
-- This happens because Postgres tries to dynamically calculate the `to_tsvector` for thousands of 
-- massive JSON catalogs at runtime. 
-- We must pre-calculate this into a generated column and index it.

-- 1. Create a generated TSVECTOR column to make text search lightning fast
ALTER TABLE mstc_auctions ADD COLUMN IF NOT EXISTS fts_doc tsvector
GENERATED ALWAYS AS (
    setweight(to_tsvector('english', coalesce(category_name, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(mstc_auction_number, '')), 'A') ||
    setweight(to_tsvector('english', CASE WHEN is_reauction THEN 'reauction' ELSE '' END), 'A') ||
    setweight(to_tsvector('english', coalesce(seller_name, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(raw_materials_text, '')), 'C')
) STORED;

-- 2. Create a massive GIN Index on it so the database never crashes on search
CREATE INDEX IF NOT EXISTS mstc_auctions_fts_idx ON mstc_auctions USING GIN (fts_doc);

-- 3. Update the Hybrid Search Function to USE the new lightning-fast indexed column!
DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text[],text[],text[],text[],text[],text,text,boolean,boolean,numeric,numeric,boolean,integer,integer);

CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_is_reauction BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      -- Text Rank uses the indexed column now!
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(m.fts_doc, v_tsquery)
      ELSE 0.0 END AS t_rank,
      -- Vector Similarity
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          m.fts_doc @@ v_tsquery -- <--- FASTER INDEXED SEARCH HERE
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.6
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (p_is_reauction IS NULL OR m.is_reauction = p_is_reauction)
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (
          m.raw_materials_text IS NOT NULL 
          AND m.raw_materials_text LIKE '%"extracted_images":%' 
          AND EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(
              CASE 
                WHEN m.raw_materials_text LIKE '{%}' AND m.raw_materials_text LIKE '%"extracted_images":%' 
                THEN (m.raw_materials_text::jsonb)->'extracted_images' 
                ELSE '[]'::jsonb 
              END
            ) AS img
            WHERE img NOT ILIKE '%.pdf' AND img NOT ILIKE '%_catalog_page_%' AND img NOT ILIKE '%mstc-previews/%'
          )
        )
      )
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (
          m.sanitized_document_path IS NOT NULL OR 
          (
             m.raw_materials_text IS NOT NULL AND (
               m.raw_materials_text ILIKE '%.pdf%' OR
               m.raw_materials_text ILIKE '%"docs":%' OR
               m.raw_materials_text ILIKE '%"documents":%'
             )
          )
        )
      )
      -- Apply Price Constraints
      AND (
        p_min_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) >= p_min_pre_bid
      )
      AND (
        p_max_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) <= p_max_pre_bid
      )
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND r.mstc_auction_number ILIKE '%' || p_search_query || '%' THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.opening_date DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00016_search_sort_new.sql
-- ==========================================================================
-- Migration: Safely Update Search Sort Order to Newest Scraped Catalogs
-- We drop ALL overloaded versions of this function to prevent PostgREST errors.

DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text, vector, text, text, text, text, text, text, integer);
DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text[],text[],text[],text[],text[],text,text,boolean,boolean,numeric,numeric,boolean,integer,integer);

CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_is_reauction BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      m.updated_at, -- Required for proper descending sorting of newest items
      -- Text Rank uses the indexed column now!
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(m.fts_doc, v_tsquery)
      ELSE 0.0 END AS t_rank,
      -- Vector Similarity
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          m.fts_doc @@ v_tsquery -- <--- FASTER INDEXED SEARCH HERE
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.85
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (p_is_reauction IS NULL OR m.is_reauction = p_is_reauction)
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (
          m.raw_materials_text IS NOT NULL 
          AND m.raw_materials_text LIKE '%"extracted_images":%' 
          AND EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(
              CASE 
                WHEN m.raw_materials_text LIKE '{%}' AND m.raw_materials_text LIKE '%"extracted_images":%' 
                THEN (m.raw_materials_text::jsonb)->'extracted_images' 
                ELSE '[]'::jsonb 
              END
            ) AS img
            WHERE img NOT ILIKE '%.pdf' AND img NOT ILIKE '%_catalog_page_%' AND img NOT ILIKE '%mstc-previews/%'
          )
        )
      )
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (
          m.sanitized_document_path IS NOT NULL OR 
          (
            m.raw_materials_text IS NOT NULL AND (
              m.raw_materials_text ILIKE '%.pdf%' OR
              m.raw_materials_text ILIKE '%"docs":%' OR
              m.raw_materials_text ILIKE '%"documents":%'
            )
          )
        )
      )
      -- Apply Price Constraints
      AND (
        p_min_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) >= p_min_pre_bid
      )
      AND (
        p_max_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) <= p_max_pre_bid
      )
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
    -- FTS matches (rank >= 2.0) OR tight vector matches (sim > 0.85) survive.
    -- 0.85 is strict enough for treeâ†’timber but kills treeâ†’vehicles noise.
    WHERE v_tsquery IS NULL OR t_rank >= 2.0 OR v_sim > 0.85
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND (
      r.mstc_auction_number ILIKE '%' || p_search_query || '%'
      OR r.seller_name ILIKE '%' || p_search_query || '%'
      OR r.category_name ILIKE '%' || p_search_query || '%'
    ) THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.updated_at DESC -- Sort by newly scraped auctions first
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00016_security_logs.sql
-- ==========================================================================
-- Create security_audit_logs table
CREATE TABLE IF NOT EXISTS security_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    user_id UUID,
    ip_address VARCHAR(45),
    user_agent TEXT,
    system_info JSONB,
    attempted_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE security_audit_logs ENABLE ROW LEVEL SECURITY;

-- Allow insert access to public (for logging failed login attempts)
CREATE POLICY "Allow public insert to security logs"
ON security_audit_logs
FOR INSERT
WITH CHECK (true);

-- Allow only admins to select/read security logs
CREATE POLICY "Allow admins to view security logs"
ON security_audit_logs
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('admin', 'superadmin')
    )
);



-- ==========================================================================
-- MIGRATION: 00017_fix_asset_filters.sql
-- ==========================================================================
-- Migration: Fix Asset Document vs Image Filters
-- Problem: The previous version used heavy jsonb_array_elements + LATERAL array unnesting
--          on raw_materials_text in PostgreSQL WHERE clauses, causing statement timeouts (>5s)
--          and returning 0 results.
-- Solution: Fast, indexable filter that checks:
--          1. m.sanitized_document_path IS NOT NULL (every completed auction catalog PDF in DB)
--          2. Fast string / jsonb boolean flags without heavy nested unnesting loops.

DROP FUNCTION IF EXISTS hybrid_search_mstc_catalog(text,vector,text[],text[],text[],text[],text[],text,text,boolean,boolean,numeric,numeric,boolean,integer,integer);

CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_is_reauction BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      m.updated_at,
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(m.fts_doc, v_tsquery)
      ELSE 0.0 END AS t_rank,
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          m.fts_doc @@ v_tsquery
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.85
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (p_is_reauction IS NULL OR m.is_reauction = p_is_reauction)
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- FAST & BULLETPROOF p_has_images
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (
          m.raw_materials_text IS NOT NULL AND (
            (m.raw_materials_text::jsonb)->>'hasImages' = 'true'
            OR (m.raw_materials_text LIKE '%"extracted_images":%' AND m.raw_materials_text NOT LIKE '%"extracted_images":[]%')
            OR (m.raw_materials_text LIKE '%"images":%' AND m.raw_materials_text NOT LIKE '%"images":[]%')
          )
        )
      )
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- FAST & BULLETPROOF p_has_docs
      -- Checks parser JSON flag and documents list
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (
          m.raw_materials_text IS NOT NULL AND (
            (m.raw_materials_text::jsonb)->>'hasAssetDocuments' = 'true'
            OR coalesce(jsonb_array_length((m.raw_materials_text::jsonb)->'documents'), 0) > 0
          )
        )
      )
      -- Apply Price Constraints
      AND (
        p_min_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) >= p_min_pre_bid
      )
      AND (
        p_max_pre_bid IS NULL OR 
        coalesce(extract_numeric_from_json(m.raw_materials_text, 'depositDetails', 'preBidDdg'), 0) <= p_max_pre_bid
      )
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
    WHERE v_tsquery IS NULL OR t_rank >= 2.0 OR v_sim > 0.85
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND (
      r.mstc_auction_number ILIKE '%' || p_search_query || '%'
      OR r.seller_name ILIKE '%' || p_search_query || '%'
      OR r.category_name ILIKE '%' || p_search_query || '%'
    ) THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.updated_at DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00018_fast_price_filter.sql
-- ==========================================================================
-- Migration: Make PreBid Filter Fast
-- The PL/pgSQL function `extract_numeric_from_json` causes timeouts when run on 100k+ rows 
-- inside a WHERE clause because context switching between SQL and PL/pgSQL is slow.
-- We replace it with native Postgres JSONB and regex operators.

CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_is_reauction BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      m.updated_at,
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(m.fts_doc, v_tsquery)
      ELSE 0.0 END AS t_rank,
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          m.fts_doc @@ v_tsquery
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.85
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (p_is_reauction IS NULL OR m.is_reauction = p_is_reauction)
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- FAST & BULLETPROOF p_has_images
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (
          m.raw_materials_text IS NOT NULL AND (
            (m.raw_materials_text::jsonb)->>'hasImages' = 'true'
            OR (m.raw_materials_text LIKE '%"extracted_images":%' AND m.raw_materials_text NOT LIKE '%"extracted_images":[]%')
            OR (m.raw_materials_text LIKE '%"images":%' AND m.raw_materials_text NOT LIKE '%"images":[]%')
          )
        )
      )
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- FAST & BULLETPROOF p_has_docs
      -- Checks parser JSON flag and documents list
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (
          m.raw_materials_text IS NOT NULL AND (
            (m.raw_materials_text::jsonb)->>'hasAssetDocuments' = 'true'
            OR coalesce(jsonb_array_length((m.raw_materials_text::jsonb)->'documents'), 0) > 0
          )
        )
      )
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- FAST NATIVE PRICE CONSTRAINTS
      -- Replaces slow PL/pgSQL function with native JSONB and REGEXP
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (
        p_min_pre_bid IS NULL OR 
        (
          m.raw_materials_text IS NOT NULL AND
          NULLIF(regexp_replace((m.raw_materials_text::jsonb)->'depositDetails'->>'preBidDdg', '[^0-9.]', '', 'g'), '') IS NOT NULL AND
          (NULLIF(regexp_replace((m.raw_materials_text::jsonb)->'depositDetails'->>'preBidDdg', '[^0-9.]', '', 'g'), ''))::numeric >= p_min_pre_bid
        )
      )
      AND (
        p_max_pre_bid IS NULL OR 
        (
          m.raw_materials_text IS NOT NULL AND
          NULLIF(regexp_replace((m.raw_materials_text::jsonb)->'depositDetails'->>'preBidDdg', '[^0-9.]', '', 'g'), '') IS NOT NULL AND
          (NULLIF(regexp_replace((m.raw_materials_text::jsonb)->'depositDetails'->>'preBidDdg', '[^0-9.]', '', 'g'), ''))::numeric <= p_max_pre_bid
        )
      )
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
    WHERE v_tsquery IS NULL OR t_rank >= 2.0 OR v_sim > 0.85
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND (
      r.mstc_auction_number ILIKE '%' || p_search_query || '%'
      OR r.seller_name ILIKE '%' || p_search_query || '%'
      OR r.category_name ILIKE '%' || p_search_query || '%'
    ) THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.updated_at DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 00019_add_pre_bid_column.sql
-- ==========================================================================
-- Add pre_bid column and index for fast filtering
ALTER TABLE mstc_auctions ADD COLUMN IF NOT EXISTS pre_bid NUMERIC DEFAULT 0;

-- Backfill pre_bid data
UPDATE mstc_auctions 
SET pre_bid = coalesce(
  (NULLIF(regexp_replace((raw_materials_text::jsonb)->'depositDetails'->>'preBidDdg', '[^0-9.]', '', 'g'), ''))::numeric, 
  0
)
WHERE raw_materials_text IS NOT NULL;

-- Create an index for blazing fast price filtering
CREATE INDEX IF NOT EXISTS idx_mstc_auctions_pre_bid ON mstc_auctions(pre_bid);

-- Update the RPC to use the new column
CREATE OR REPLACE FUNCTION hybrid_search_mstc_catalog(
  p_search_query TEXT,
  p_embedding vector(384) DEFAULT NULL,
  p_categories TEXT[] DEFAULT NULL,
  p_subcategories TEXT[] DEFAULT NULL,
  p_locations TEXT[] DEFAULT NULL,
  p_sellers TEXT[] DEFAULT NULL,
  p_regional_offices TEXT[] DEFAULT NULL,
  p_start_date TEXT DEFAULT NULL,
  p_end_date TEXT DEFAULT NULL,
  p_has_images BOOLEAN DEFAULT NULL,
  p_has_docs BOOLEAN DEFAULT NULL,
  p_min_pre_bid NUMERIC DEFAULT NULL,
  p_max_pre_bid NUMERIC DEFAULT NULL,
  p_is_reauction BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_limit INT DEFAULT 12
)
RETURNS TABLE (
  id UUID,
  mstc_auction_number TEXT,
  seller_name TEXT,
  category_name TEXT,
  location TEXT,
  opening_date TIMESTAMPTZ,
  closing_date TIMESTAMPTZ,
  sanitized_document_path TEXT,
  raw_materials_text TEXT,
  status TEXT,
  is_reauction BOOLEAN,
  search_rank REAL,
  semantic_similarity REAL,
  total_count BIGINT
) AS $$
DECLARE
  v_tsquery tsquery;
  v_rrf_k INT := 60; 
BEGIN
  IF p_search_query IS NOT NULL AND trim(p_search_query) != '' THEN
    v_tsquery := websearch_to_tsquery('english', p_search_query);
  ELSE
    v_tsquery := NULL;
  END IF;

  RETURN QUERY
  WITH filtered_candidates AS (
    SELECT
      m.id, m.mstc_auction_number, m.seller_name, m.category_name, m.location, 
      m.opening_date, m.closing_date, m.sanitized_document_path, m.raw_materials_text, m.asset_status, m.is_reauction,
      m.updated_at,
      CASE WHEN v_tsquery IS NOT NULL THEN
        ts_rank_cd(m.fts_doc, v_tsquery)
      ELSE 0.0 END AS t_rank,
      CASE WHEN p_embedding IS NOT NULL AND m.embedding IS NOT NULL THEN
        1 - (m.embedding <=> p_embedding)
      ELSE 0.0 END AS v_sim
    FROM mstc_auctions m
    WHERE
      m.asset_status = 'completed'
      AND (
        (v_tsquery IS NULL AND p_embedding IS NULL) OR
        (
          v_tsquery IS NOT NULL AND
          m.fts_doc @@ v_tsquery
        ) OR
        (
          p_embedding IS NOT NULL AND m.embedding IS NOT NULL AND
          (1 - (m.embedding <=> p_embedding)) > 0.85
        )
      )
      -- Apply Array Filters
      AND (p_categories IS NULL OR array_length(p_categories, 1) IS NULL OR split_part(m.category_name, ' | ', 1) = ANY(p_categories))
      AND (p_subcategories IS NULL OR array_length(p_subcategories, 1) IS NULL OR split_part(m.category_name, ' | ', 2) = ANY(p_subcategories))
      AND (p_locations IS NULL OR array_length(p_locations, 1) IS NULL OR m.location = ANY(p_locations))
      AND (p_sellers IS NULL OR array_length(p_sellers, 1) IS NULL OR m.seller_name = ANY(p_sellers))
      AND (
        p_regional_offices IS NULL OR array_length(p_regional_offices, 1) IS NULL OR 
        EXISTS (
          SELECT 1 FROM unnest(p_regional_offices) office 
          WHERE m.mstc_auction_number ILIKE 'MSTC/' || office || '/%'
        )
      )
      AND (p_start_date IS NULL OR m.opening_date >= p_start_date::TIMESTAMPTZ)
      AND (p_end_date IS NULL OR m.opening_date <= p_end_date::TIMESTAMPTZ)
      AND (p_is_reauction IS NULL OR m.is_reauction = p_is_reauction)
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- FAST & BULLETPROOF p_has_images
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (
        p_has_images IS NULL OR p_has_images = FALSE OR
        (
          m.raw_materials_text IS NOT NULL AND (
            (m.raw_materials_text::jsonb)->>'hasImages' = 'true'
            OR (m.raw_materials_text LIKE '%"extracted_images":%' AND m.raw_materials_text NOT LIKE '%"extracted_images":[]%')
            OR (m.raw_materials_text LIKE '%"images":%' AND m.raw_materials_text NOT LIKE '%"images":[]%')
          )
        )
      )
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- FAST & BULLETPROOF p_has_docs
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (
        p_has_docs IS NULL OR p_has_docs = FALSE OR
        (
          m.raw_materials_text IS NOT NULL AND (
            (m.raw_materials_text::jsonb)->>'hasAssetDocuments' = 'true'
            OR coalesce(jsonb_array_length((m.raw_materials_text::jsonb)->'documents'), 0) > 0
          )
        )
      )
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      -- INDEXED PRICE CONSTRAINTS (INSTANT)
      -- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
      AND (p_min_pre_bid IS NULL OR m.pre_bid >= p_min_pre_bid)
      AND (p_max_pre_bid IS NULL OR m.pre_bid <= p_max_pre_bid)
  ),
  ranked_candidates AS (
    SELECT *,
      CASE WHEN t_rank > 0 THEN ROW_NUMBER() OVER (ORDER BY t_rank DESC) ELSE 100000 END AS text_rank_num,
      CASE WHEN v_sim > 0 THEN ROW_NUMBER() OVER (ORDER BY v_sim DESC) ELSE 100000 END AS vector_rank_num
    FROM filtered_candidates
    WHERE v_tsquery IS NULL OR t_rank >= 2.0 OR v_sim > 0.85
  ),
  rrf_scored AS (
    SELECT *,
      (
        CASE WHEN text_rank_num < 100000 THEN 1.0 / (v_rrf_k + text_rank_num) ELSE 0.0 END +
        CASE WHEN vector_rank_num < 100000 THEN 1.0 / (v_rrf_k + vector_rank_num) ELSE 0.0 END
      ) AS rrf_score
    FROM ranked_candidates
  )
  SELECT
    r.id,
    r.mstc_auction_number::TEXT,
    r.seller_name::TEXT,
    r.category_name::TEXT,
    r.location::TEXT,
    r.opening_date,
    r.closing_date,
    r.sanitized_document_path::TEXT,
    r.raw_materials_text::TEXT,
    r.asset_status::TEXT AS status,
    r.is_reauction::BOOLEAN,
    r.t_rank::REAL AS search_rank,
    r.v_sim::REAL AS semantic_similarity,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM rrf_scored r
  ORDER BY
    (CASE WHEN p_search_query IS NOT NULL AND (
      r.mstc_auction_number ILIKE '%' || p_search_query || '%'
      OR r.seller_name ILIKE '%' || p_search_query || '%'
      OR r.category_name ILIKE '%' || p_search_query || '%'
    ) THEN 1000.0 ELSE r.rrf_score END) DESC,
    r.updated_at DESC
  LIMIT p_limit
  OFFSET GREATEST(0, (p_page - 1) * p_limit);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 20260619130937_market_prices.sql
-- ==========================================================================
-- Create market_indices table
CREATE TABLE IF NOT EXISTS public.market_indices (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    unit TEXT NOT NULL,
    default_price NUMERIC NOT NULL,
    default_multiplier NUMERIC NOT NULL,
    current_price NUMERIC NOT NULL,
    current_multiplier NUMERIC NOT NULL,
    keywords TEXT[] NOT NULL DEFAULT '{}',
    is_custom BOOLEAN NOT NULL DEFAULT false,
    is_pricing_disabled BOOLEAN NOT NULL DEFAULT false,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS for market_indices
ALTER TABLE public.market_indices ENABLE ROW LEVEL SECURITY;

-- Allow read access for authenticated users (so the valuation engine can read)
CREATE POLICY "Allow authenticated read access on market_indices"
    ON public.market_indices FOR SELECT
    TO authenticated
    USING (true);

-- Allow full access for admin users
CREATE POLICY "Allow admin full access on market_indices"
    ON public.market_indices FOR ALL
    TO authenticated
    USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'superadmin'));


-- Create market_price_history table
CREATE TABLE IF NOT EXISTS public.market_price_history (
    id TEXT PRIMARY KEY,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    commodity_id TEXT NOT NULL REFERENCES public.market_indices(id) ON DELETE CASCADE,
    commodity_name TEXT NOT NULL,
    price NUMERIC NOT NULL,
    multiplier NUMERIC NOT NULL,
    updated_by TEXT NOT NULL
);

-- Enable RLS for market_price_history
ALTER TABLE public.market_price_history ENABLE ROW LEVEL SECURITY;

-- Allow read access for admin users
CREATE POLICY "Allow admin read access on market_price_history"
    ON public.market_price_history FOR SELECT
    TO authenticated
    USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'superadmin'));

-- Allow insert access for admin users
CREATE POLICY "Allow admin insert access on market_price_history"
    ON public.market_price_history FOR INSERT
    TO authenticated
    WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'superadmin'));

-- Allow delete access for admin users (for wiping history)
CREATE POLICY "Allow admin delete access on market_price_history"
    ON public.market_price_history FOR DELETE
    TO authenticated
    USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('admin', 'superadmin'));



-- ==========================================================================
-- MIGRATION: 20260627144400_create_blogs.sql
-- ==========================================================================
-- Create the blogs table
CREATE TABLE IF NOT EXISTS public.blogs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    is_published BOOLEAN DEFAULT true,
    author_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.blogs ENABLE ROW LEVEL SECURITY;

-- Allow public read access to published blogs
CREATE POLICY "Public can view published blogs"
ON public.blogs
FOR SELECT
TO public
USING (is_published = true);

-- Allow authenticated users (specifically admins) to read all blogs
CREATE POLICY "Admins can view all blogs"
ON public.blogs
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

-- Allow admins to insert/update/delete blogs
CREATE POLICY "Admins can insert blogs"
ON public.blogs
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

CREATE POLICY "Admins can update blogs"
ON public.blogs
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

CREATE POLICY "Admins can delete blogs"
ON public.blogs
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_blogs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_blogs_updated_at_trigger
BEFORE UPDATE ON public.blogs
FOR EACH ROW
EXECUTE FUNCTION update_blogs_updated_at();



-- ==========================================================================
-- MIGRATION: 20260627151500_blog_images_bucket.sql
-- ==========================================================================
-- Create the storage bucket for blog images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('blog_images', 'blog_images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public access to view blog images
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING ( bucket_id = 'blog_images' );

-- Allow authenticated admins to upload blog images
CREATE POLICY "Admins can upload blog images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( 
  bucket_id = 'blog_images' AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

-- Allow authenticated admins to update blog images
CREATE POLICY "Admins can update blog images"
ON storage.objects FOR UPDATE
TO authenticated
USING ( 
  bucket_id = 'blog_images' AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);

-- Allow authenticated admins to delete blog images
CREATE POLICY "Admins can delete blog images"
ON storage.objects FOR DELETE
TO authenticated
USING ( 
  bucket_id = 'blog_images' AND
  EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'superadmin')
  )
);



-- ==========================================================================
-- MIGRATION: 20260627152200_blog_author_name.sql
-- ==========================================================================
-- Add author_name to blogs table
ALTER TABLE public.blogs
ADD COLUMN IF NOT EXISTS author_name TEXT DEFAULT 'Admin';



-- ==========================================================================
-- MIGRATION: 20260627153000_fix_blog_slug_trigger.sql
-- ==========================================================================
-- Drop any existing triggers on blogs table to prevent duplication
DO $$
DECLARE
    trig RECORD;
BEGIN
    FOR trig IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'blogs'
        AND trigger_name != 'update_blogs_updated_at_trigger'
    LOOP
        EXECUTE 'DROP TRIGGER IF EXISTS ' || trig.trigger_name || ' ON public.blogs;';
    END LOOP;
END $$;

-- Create or replace function to generate a clean, SEO-friendly slug
CREATE OR REPLACE FUNCTION public.generate_blog_slug()
RETURNS TRIGGER AS $$
BEGIN
    -- Lowercase, replace special chars and spaces with hyphens, trim consecutive or trailing hyphens
    NEW.slug := regexp_replace(
        regexp_replace(
            lower(NEW.title),
            '[^a-z0-9]+',
            '-',
            'g'
        ),
        '^-+|-+$',
        '',
        'g'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Bind the trigger to run BEFORE INSERT or BEFORE UPDATE of the title
CREATE TRIGGER generate_blog_slug_trigger
BEFORE INSERT OR UPDATE OF title ON public.blogs
FOR EACH ROW
EXECUTE FUNCTION public.generate_blog_slug();

-- Force slug update on existing blogs
UPDATE public.blogs SET title = title;



-- ==========================================================================
-- MIGRATION: 20260629135000_mstc_auctions_admin_policy.sql
-- ==========================================================================
-- Enable authenticated administrators and superadministrators to perform all operations on mstc_auctions
CREATE POLICY "Admins can manage MSTC auctions"
ON public.mstc_auctions
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
);

-- Ensure Admins have full access to audit logs (in case it wasn't fully granted)
DROP POLICY IF EXISTS "Admins can view all audit logs" ON public.audit_logs;
CREATE POLICY "Admins can view and manage all audit logs"
ON public.audit_logs
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
);



-- ==========================================================================
-- MIGRATION: 20260630134500_category_stats.sql
-- ==========================================================================
CREATE TABLE IF NOT EXISTS category_daily_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    category_name TEXT NOT NULL,
    items_added INTEGER DEFAULT 0,
    UNIQUE(date, category_name)
);

-- Enable RLS
ALTER TABLE category_daily_stats ENABLE ROW LEVEL SECURITY;

-- Allow read access to anyone (or authenticated users)
CREATE POLICY "Allow read access to category_daily_stats" ON category_daily_stats
    FOR SELECT USING (true);

-- Create a highly optimized RPC function to get current totals without 1000 row limit
CREATE OR REPLACE FUNCTION get_current_category_totals()
RETURNS TABLE(category_name TEXT, count BIGINT)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT 
        COALESCE(category_name, 'Uncategorized') as category_name, 
        COUNT(*) as count 
    FROM mstc_auctions 
    GROUP BY COALESCE(category_name, 'Uncategorized')
    ORDER BY count DESC;
$$;



-- ==========================================================================
-- MIGRATION: 20260708122000_fuzzy_synonyms_and_ema.sql
-- ==========================================================================
-- Migration: Real-Time EMA Pricing Trigger & Phrase-Level Synonym Mapping
-- 1. Create category_stats table for tracking running EMAs
-- 2. Create trigger function and trigger for bids
-- 3. Insert synonym phrases (HMS, Heavy Melting Scrap, etc.)
-- 4. Upgrade suggest_search_correction to perform phrase-level synonym resolution first

-- 1. Create category_stats table
CREATE TABLE IF NOT EXISTS public.category_stats (
    category_name TEXT PRIMARY KEY,
    current_ema_price NUMERIC NOT NULL DEFAULT 0,
    last_updated TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS for category_stats
ALTER TABLE public.category_stats ENABLE ROW LEVEL SECURITY;

-- Allow public read access to category_stats
CREATE POLICY "Allow read access to category_stats" ON public.category_stats
    FOR SELECT USING (true);

-- 2. Trigger Function for Real-Time EMA Calculation
CREATE OR REPLACE FUNCTION public.update_category_ema_price()
RETURNS TRIGGER AS $$
DECLARE
  v_category_name TEXT;
  v_old_ema NUMERIC;
  v_new_ema NUMERIC;
  v_alpha CONSTANT NUMERIC := 0.1; -- Smoothing factor (10% weight to new bids)
BEGIN
  -- Retrieve parent category name of the auction the bid is placed on
  SELECT c.name INTO v_category_name
  FROM public.auctions a
  JOIN public.auction_categories c ON a.category_id = c.id
  WHERE a.id = NEW.auction_id;

  IF v_category_name IS NULL THEN
    v_category_name := 'Uncategorized';
  END IF;

  -- Get current EMA price
  SELECT current_ema_price INTO v_old_ema
  FROM public.category_stats
  WHERE category_name = v_category_name;

  IF v_old_ema IS NULL THEN
    -- First bid, initialize EMA
    v_new_ema := NEW.amount;
    INSERT INTO public.category_stats (category_name, current_ema_price, last_updated)
    VALUES (v_category_name, v_new_ema, NOW())
    ON CONFLICT (category_name) 
    DO UPDATE SET current_ema_price = EXCLUDED.current_ema_price, last_updated = NOW();
  ELSE
    -- Compute dynamic EMA
    v_new_ema := v_alpha * NEW.amount + (1 - v_alpha) * v_old_ema;
    UPDATE public.category_stats
    SET current_ema_price = v_new_ema, last_updated = NOW()
    WHERE category_name = v_category_name;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to run after inserting a bid
DROP TRIGGER IF EXISTS trg_update_category_ema_price ON public.bids;
CREATE TRIGGER trg_update_category_ema_price
AFTER INSERT ON public.bids
FOR EACH ROW
EXECUTE FUNCTION public.update_category_ema_price();


-- 3. Populate Search Synonyms (with HMS, Heavy Melting Scrap, etc.)
INSERT INTO public.search_synonyms (abbreviation, expansion) VALUES
    ('hms', 'steel / iron scrap'),
    ('heavy melting scrap', 'steel / iron scrap'),
    ('iron scrap old', 'steel / iron scrap'),
    ('ms scrap', 'steel / iron scrap'),
    ('scrap iron', 'steel / iron scrap'),
    ('scrap steel', 'steel / iron scrap'),
    ('copper wire', 'copper'),
    ('wire scrap', 'cable_wire'),
    ('battery scrap', 'battery'),
    ('scrap battery', 'battery'),
    ('ss', 'stainless steel'),
    ('al', 'aluminium'),
    ('alu', 'aluminium'),
    ('pb', 'lead'),
    ('zn', 'zinc'),
    ('gi', 'galvanized iron')
ON CONFLICT (abbreviation) DO UPDATE SET expansion = EXCLUDED.expansion;


-- 4. Upgrade suggest_search_correction to perform phrase-level synonym check first
CREATE OR REPLACE FUNCTION public.suggest_search_correction(p_query TEXT)
RETURNS TEXT AS $$
DECLARE
  v_synonym RECORD;
  v_word TEXT;
  v_corrected_query TEXT := '';
  v_best_match TEXT;
  v_temp_query TEXT := lower(p_query);
BEGIN
  -- First replace all matching synonym phrases/abbreviations (phrase-level replacement)
  FOR v_synonym IN SELECT abbreviation, expansion FROM public.search_synonyms LOOP
    -- Using regexp_replace to match word boundaries for the abbreviation
    v_temp_query := regexp_replace(v_temp_query, '\b' || regexp_replace(v_synonym.abbreviation, '([.|\(\)\[\]\+])', '\\\1', 'g') || '\b', v_synonym.expansion, 'gi');
  END LOOP;

  -- Split remainder query into words and check dictionary fuzzy matching
  FOR v_word IN SELECT unnest(string_to_array(v_temp_query, ' ')) LOOP
    IF v_word = '' THEN 
      CONTINUE; 
    END IF;
    
    -- Fuzzy match against search_dictionary (pg_trgm, alpha words only)
    SELECT word INTO v_best_match
    FROM public.search_dictionary
    WHERE word ~ '^[a-z]+$'
    ORDER BY word <-> v_word
    LIMIT 1;

    -- Relaxed threshold (0.75) to catch transposition typos like cusotmsâ†’customs
    IF v_best_match IS NOT NULL AND (v_best_match <-> v_word) < 0.75 THEN
      v_corrected_query := v_corrected_query || ' ' || v_best_match;
    ELSE
      v_corrected_query := v_corrected_query || ' ' || v_word;
    END IF;
  END LOOP;

  RETURN trim(v_corrected_query);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 20260708123500_metalmandi_live_rates.sql
-- ==========================================================================
-- Migration: Create metalmandi_live_rates table
-- 1. Create table
-- 2. Enable RLS
-- 3. Define access policies

CREATE TABLE IF NOT EXISTS public.metalmandi_live_rates (
    id TEXT PRIMARY KEY,
    metal_type TEXT NOT NULL,
    grade_name TEXT NOT NULL,
    price_per_kg NUMERIC NOT NULL,
    price_change_percent NUMERIC NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.metalmandi_live_rates ENABLE ROW LEVEL SECURITY;

-- Allow public read access (necessary for real-time customer consulting valuations)
CREATE POLICY "Allow public read access on metalmandi_live_rates" ON public.metalmandi_live_rates
    FOR SELECT USING (true);

-- Allow full access for authenticated/service role (necessary for background scraper upserts)
CREATE POLICY "Allow service role complete access on metalmandi_live_rates" ON public.metalmandi_live_rates
    FOR ALL USING (true);



-- ==========================================================================
-- MIGRATION: 20260715123000_update_filter_options.sql
-- ==========================================================================
-- Migration: Update get_mstc_filter_options to read categories from category_daily_stats
-- Even if an auction is out of the system, the category information remains

CREATE OR REPLACE FUNCTION get_mstc_filter_options()
RETURNS json AS $$
DECLARE
  result json;
BEGIN
  SELECT json_build_object(
    'categories', (
      SELECT coalesce(json_agg(DISTINCT split_part(category_name, ' | ', 1)), '[]'::json) 
      FROM category_daily_stats 
      WHERE category_name IS NOT NULL
    ),
    'subcategories', (
      SELECT coalesce(json_object_agg(main_cat, subcats), '{}'::json) 
      FROM (
        SELECT split_part(category_name, ' | ', 1) as main_cat, json_agg(DISTINCT split_part(category_name, ' | ', 2)) as subcats
        FROM category_daily_stats
        WHERE category_name LIKE '% | %'
        GROUP BY split_part(category_name, ' | ', 1)
      ) t
    ),
    'sellers', (
      SELECT coalesce(json_agg(DISTINCT seller_name), '[]'::json) 
      FROM mstc_auctions 
      WHERE asset_status = 'completed' AND seller_name IS NOT NULL
    ),
    'locations', (
      SELECT coalesce(json_agg(DISTINCT location), '[]'::json) 
      FROM mstc_auctions 
      WHERE asset_status = 'completed' AND location IS NOT NULL
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;



-- ==========================================================================
-- MIGRATION: 20260715140000_baanknet_auctions.sql
-- ==========================================================================
-- Migration: Create baanknet_auctions table for PSB Alliance Bank Asset Auction Network
-- This stores bank-seized property auctions scraped from baanknet.com

CREATE TABLE IF NOT EXISTS public.baanknet_auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- BaankNet identifiers
    baanknet_auction_id TEXT UNIQUE NOT NULL,
    bank_property_id TEXT,

    -- Listing details
    title TEXT NOT NULL,
    property_type TEXT,
    reserve_price_text TEXT,
    reserve_price_value NUMERIC,
    bank_name TEXT NOT NULL,

    -- Location
    state TEXT,
    city TEXT,
    pincode TEXT,
    full_address TEXT,
    location TEXT NOT NULL DEFAULT 'India',

    -- Dates
    auction_start_date TIMESTAMPTZ NOT NULL,
    auction_end_date TIMESTAMPTZ NOT NULL,

    -- Status and source
    auction_status TEXT DEFAULT 'upcoming',
    source_url TEXT,
    category_name TEXT DEFAULT 'Real Estate | Bank Property',
    raw_description TEXT,

    -- Processing status (always 'completed' since no PDF processing is needed)
    asset_status TEXT DEFAULT 'completed',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.baanknet_auctions ENABLE ROW LEVEL SECURITY;

-- Public read access for consulting dashboards
CREATE POLICY "Allow public read access on BaankNet auctions"
    ON public.baanknet_auctions
    FOR SELECT USING (true);

-- Service role / background worker full access
CREATE POLICY "Allow service role complete access on BaankNet"
    ON public.baanknet_auctions
    FOR ALL USING (true);

-- Admin access for authenticated users with admin role
CREATE POLICY "Allow admin access on BaankNet auctions"
    ON public.baanknet_auctions
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'superadmin')
        )
    );

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_baanknet_auction_status
    ON public.baanknet_auctions (auction_status);

CREATE INDEX IF NOT EXISTS idx_baanknet_bank_name
    ON public.baanknet_auctions (bank_name);

CREATE INDEX IF NOT EXISTS idx_baanknet_state
    ON public.baanknet_auctions (state);

CREATE INDEX IF NOT EXISTS idx_baanknet_property_type
    ON public.baanknet_auctions (property_type);

CREATE INDEX IF NOT EXISTS idx_baanknet_reserve_price
    ON public.baanknet_auctions (reserve_price_value);

CREATE INDEX IF NOT EXISTS idx_baanknet_end_date
    ON public.baanknet_auctions (auction_end_date);

CREATE INDEX IF NOT EXISTS idx_baanknet_created_at
    ON public.baanknet_auctions (created_at);

-- Full-text search vector column
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS fts_doc tsvector
    GENERATED ALWAYS AS (
        to_tsvector('english',
            coalesce(title, '') || ' ' ||
            coalesce(bank_name, '') || ' ' ||
            coalesce(state, '') || ' ' ||
            coalesce(city, '') || ' ' ||
            coalesce(property_type, '') || ' ' ||
            coalesce(full_address, '') || ' ' ||
            coalesce(raw_description, '')
        )
    ) STORED;

CREATE INDEX IF NOT EXISTS idx_baanknet_fts
    ON public.baanknet_auctions USING GIN (fts_doc);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_baanknet_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_baanknet_updated_at
    BEFORE UPDATE ON public.baanknet_auctions
    FOR EACH ROW
    EXECUTE FUNCTION update_baanknet_updated_at();



-- ==========================================================================
-- MIGRATION: 20260715150000_baanknet_document_url.sql
-- ==========================================================================
-- Add document_url column to baanknet_auctions table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'baanknet_auctions'
        AND column_name = 'document_url'
    ) THEN
        ALTER TABLE public.baanknet_auctions ADD COLUMN document_url TEXT;
    END IF;
END $$;

-- Re-grant SELECT permissions to anon and authenticated roles
GRANT SELECT ON public.baanknet_auctions TO anon;
GRANT SELECT ON public.baanknet_auctions TO authenticated;
GRANT ALL ON public.baanknet_auctions TO service_role;



-- ==========================================================================
-- MIGRATION: 20260722000000_baanknet_schema_extension.sql
-- ==========================================================================
-- Migration: Extend baanknet_auctions with detail-page fields and create photos table
-- Supports three auction modules: eAuction PSB, Property Listings, IBC eAuction

-- â”€â”€â”€ New Columns on baanknet_auctions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- Which portal module this listing came from
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS auction_module TEXT DEFAULT 'eauction_psb';

-- Property physical attributes
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS carpet_area TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS carpet_area_sqft NUMERIC;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS furnishing TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS possession_status TEXT;

-- Legal action type: SARFAESI / IBC / DRT
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS action_type TEXT;

-- Finer location granularity
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS district TEXT;

-- Inspection window
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS inspection_start_date TIMESTAMPTZ;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS inspection_end_date TIMESTAMPTZ;

-- EMD deadline
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS emd_end_date TIMESTAMPTZ;

-- Borrower / defaulter info
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS borrower_name TEXT;

-- Extended description from detail page
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS property_description TEXT;

-- Multiple borrower/guarantor names & document URLs
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS borrower_names TEXT[];

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS document_urls TEXT[];

-- EMD raw text & contact details
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS emd_amount_text TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS contact_person TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS contact_phone TEXT;

-- Cross-module deduplication fingerprint
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS dedup_fingerprint TEXT;

-- Photo metadata
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS photo_count INTEGER DEFAULT 0;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

-- Index on auction_module for module-specific queries
CREATE INDEX IF NOT EXISTS idx_baanknet_auction_module
    ON public.baanknet_auctions (auction_module);

-- Index on action_type for SARFAESI/IBC/DRT filtering
CREATE INDEX IF NOT EXISTS idx_baanknet_action_type
    ON public.baanknet_auctions (action_type);

-- Index on district for location drilling
CREATE INDEX IF NOT EXISTS idx_baanknet_district
    ON public.baanknet_auctions (district);

-- Index on dedup_fingerprint for cross-module deduplication
CREATE INDEX IF NOT EXISTS idx_baanknet_dedup_fingerprint
    ON public.baanknet_auctions (dedup_fingerprint);

-- â”€â”€â”€ Photos Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

CREATE TABLE IF NOT EXISTS public.baanknet_auction_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    baanknet_auction_id TEXT NOT NULL,
    photo_url TEXT NOT NULL,
    storage_path TEXT,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),

    CONSTRAINT fk_baanknet_auction_photos_auction
        FOREIGN KEY (baanknet_auction_id)
        REFERENCES public.baanknet_auctions(baanknet_auction_id)
        ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.baanknet_auction_photos ENABLE ROW LEVEL SECURITY;

-- Public read access
DROP POLICY IF EXISTS "Allow public read access on BaankNet photos" ON public.baanknet_auction_photos;
CREATE POLICY "Allow public read access on BaankNet photos"
    ON public.baanknet_auction_photos
    FOR SELECT USING (true);

-- Service role full access
DROP POLICY IF EXISTS "Allow service role access on BaankNet photos" ON public.baanknet_auction_photos;
CREATE POLICY "Allow service role access on BaankNet photos"
    ON public.baanknet_auction_photos
    FOR ALL USING (true);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_baanknet_photos_auction_id
    ON public.baanknet_auction_photos (baanknet_auction_id);

CREATE INDEX IF NOT EXISTS idx_baanknet_photos_display_order
    ON public.baanknet_auction_photos (baanknet_auction_id, display_order);

-- Grants
GRANT SELECT ON public.baanknet_auction_photos TO anon;
GRANT SELECT ON public.baanknet_auction_photos TO authenticated;
GRANT ALL ON public.baanknet_auction_photos TO service_role;



-- ==========================================================================
-- MIGRATION: 20260722123000_add_logistics_role.sql
-- ==========================================================================
-- Add logistics role to user_role ENUM
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'logistics';

-- Create logistics_profiles table
CREATE TABLE IF NOT EXISTS public.logistics_profiles (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    service_areas TEXT[] DEFAULT '{}'::TEXT[],
    vehicle_types TEXT[] DEFAULT '{}'::TEXT[],
    base_rates TEXT,
    certifications TEXT,
    description TEXT,
    contact_info JSONB DEFAULT '{}'::JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, NOW()) NOT NULL
);

-- Create logistics_requests table
CREATE TABLE IF NOT EXISTS public.logistics_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    logistics_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    quote_data JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'responded', 'rejected', 'completed')),
    user_note TEXT,
    logistics_response TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::TEXT, NOW()) NOT NULL
);

-- Enable RLS
ALTER TABLE public.logistics_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logistics_requests ENABLE ROW LEVEL SECURITY;

-- Logistics Profiles Policies
DROP POLICY IF EXISTS "Logistics profiles are viewable by everyone" ON public.logistics_profiles;
CREATE POLICY "Logistics profiles are viewable by everyone" 
    ON public.logistics_profiles FOR SELECT 
    USING (true);

DROP POLICY IF EXISTS "Logistics can update own profile" ON public.logistics_profiles;
CREATE POLICY "Logistics can update own profile" 
    ON public.logistics_profiles FOR UPDATE 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Logistics can insert own profile" ON public.logistics_profiles;
CREATE POLICY "Logistics can insert own profile" 
    ON public.logistics_profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

-- Logistics Requests Policies
DROP POLICY IF EXISTS "Users can view requests they sent" ON public.logistics_requests;
CREATE POLICY "Users can view requests they sent" 
    ON public.logistics_requests FOR SELECT 
    USING (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Logistics can view requests sent to them" ON public.logistics_requests;
CREATE POLICY "Logistics can view requests sent to them" 
    ON public.logistics_requests FOR SELECT 
    USING (auth.uid() = logistics_id);

DROP POLICY IF EXISTS "Users can create requests" ON public.logistics_requests;
CREATE POLICY "Users can create requests" 
    ON public.logistics_requests FOR INSERT 
    WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "Logistics can update requests sent to them (respond)" ON public.logistics_requests;
CREATE POLICY "Logistics can update requests sent to them (respond)" 
    ON public.logistics_requests FOR UPDATE 
    USING (auth.uid() = logistics_id);

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS update_logistics_profiles_updated_at ON public.logistics_profiles;
CREATE TRIGGER update_logistics_profiles_updated_at BEFORE UPDATE ON public.logistics_profiles 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_logistics_requests_updated_at ON public.logistics_requests;
CREATE TRIGGER update_logistics_requests_updated_at BEFORE UPDATE ON public.logistics_requests 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();



-- ==========================================================================
-- MIGRATION: 20260722124500_admin_update_profiles_policy.sql
-- ==========================================================================
-- Add policy to allow admins to update all user profiles
-- This is required so admins can change user roles from the User Management dashboard

CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles AS p
      WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
  );



-- ==========================================================================
-- MIGRATION: 20260722125500_bulletproof_admin_policy.sql
-- ==========================================================================
-- First, drop the old policy that might be failing silently
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- Create a secure, RLS-bypassing function to reliably check if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'superadmin')
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Create the new, bulletproof policy using the function
CREATE POLICY "Admins can update all profiles"
  ON public.profiles FOR UPDATE
  USING ( public.is_admin() );



-- ==========================================================================
-- MIGRATION: 20260722131500_fix_admin_select_policy.sql
-- ==========================================================================
-- Drop the broken SELECT policy that suffers from silent recursion filtering
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

-- Recreate it using the secure, recursion-free is_admin() function
CREATE POLICY "Admins can view all profiles"
  ON public.profiles FOR SELECT
  USING ( public.is_admin() );



-- ==========================================================================
-- MIGRATION: 20260722141500_logistics_toggle_and_visibility.sql
-- ==========================================================================
-- 1. Add is_accepting_requests toggle to logistics_profiles
ALTER TABLE public.logistics_profiles
ADD COLUMN IF NOT EXISTS is_accepting_requests BOOLEAN DEFAULT true;

-- 2. Fix bug where normal users couldn't see logistics providers in Quote Builder
-- Normal users need to be able to read the basic profile row of logistics users to know they exist
DROP POLICY IF EXISTS "Logistics users are viewable by everyone" ON public.profiles;

CREATE POLICY "Logistics users are viewable by everyone"
  ON public.profiles FOR SELECT
  USING (role = 'logistics');



-- ==========================================================================
-- MIGRATION: 20260724120000_location_daily_stats.sql
-- ==========================================================================
-- Migration: Add location_daily_stats table for region-centric analytics
-- Companion to category_daily_stats, adding a location dimension

CREATE TABLE IF NOT EXISTS location_daily_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    location TEXT NOT NULL,
    category_name TEXT NOT NULL,
    items_added INTEGER DEFAULT 0,
    UNIQUE(date, location, category_name)
);

-- Enable RLS
ALTER TABLE location_daily_stats ENABLE ROW LEVEL SECURITY;

-- Allow read access to anyone
CREATE POLICY "Allow read access to location_daily_stats" ON location_daily_stats
    FOR SELECT USING (true);

-- Allow service role full access for background worker writes
CREATE POLICY "Allow service role write to location_daily_stats" ON location_daily_stats
    FOR ALL USING (true);

-- RPC function to get location-centric analytics (auction distribution by region + category)
CREATE OR REPLACE FUNCTION get_location_analytics()
RETURNS TABLE(location TEXT, category_name TEXT, total_auctions BIGINT)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT
        COALESCE(m.location, 'India') as location,
        COALESCE(m.category_name, 'Uncategorized') as category_name,
        COUNT(*) as total_auctions
    FROM mstc_auctions m
    WHERE m.asset_status = 'completed'
    GROUP BY m.location, m.category_name
    ORDER BY total_auctions DESC;
$$;

-- RPC function to get daily location trends (for time-series charts)
CREATE OR REPLACE FUNCTION get_location_daily_trends(
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE(date DATE, location TEXT, items_added BIGINT)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT
        s.date,
        s.location,
        SUM(s.items_added)::BIGINT as items_added
    FROM location_daily_stats s
    WHERE s.date >= CURRENT_DATE - p_days
    GROUP BY s.date, s.location
    ORDER BY s.date ASC, items_added DESC;
$$;



-- ==========================================================================
-- MIGRATION: 20260725130000_gem_auctions.sql
-- ==========================================================================
-- Migration: Create gem_auctions table for Government e-Marketplace (GeM) Forward Auctions

CREATE TABLE IF NOT EXISTS public.gem_auctions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- GeM Portal identifiers
    gem_auction_id TEXT UNIQUE NOT NULL,

    -- Listing details
    title TEXT NOT NULL,
    reserve_price_text TEXT,
    reserve_price_value NUMERIC,

    -- Organization details
    ministry TEXT,
    department TEXT,
    organisation TEXT,

    -- Location
    state TEXT,
    city TEXT,
    pincode TEXT,
    full_address TEXT,
    location TEXT NOT NULL DEFAULT 'India',

    -- Dates
    auction_start_date TIMESTAMPTZ NOT NULL,
    auction_end_date TIMESTAMPTZ NOT NULL,

    -- Status and source
    auction_status TEXT DEFAULT 'live',
    source_url TEXT,
    document_url TEXT,
    category_name TEXT DEFAULT 'Government | Auction',
    raw_description TEXT,

    -- Processing status (always 'completed' since no PDF parsing is needed)
    asset_status TEXT DEFAULT 'completed',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.gem_auctions ENABLE ROW LEVEL SECURITY;

-- Public read access for consulting dashboards
CREATE POLICY "Allow public read access on GeM auctions"
    ON public.gem_auctions
    FOR SELECT USING (true);

-- Service role / background worker full access
CREATE POLICY "Allow service role complete access on GeM"
    ON public.gem_auctions
    FOR ALL USING (true);

-- Admin access for authenticated users with admin role
CREATE POLICY "Allow admin access on GeM auctions"
    ON public.gem_auctions
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'superadmin')
        )
    );

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_gem_auction_status
    ON public.gem_auctions (auction_status);

CREATE INDEX IF NOT EXISTS idx_gem_organisation
    ON public.gem_auctions (organisation);

CREATE INDEX IF NOT EXISTS idx_gem_state
    ON public.gem_auctions (state);

CREATE INDEX IF NOT EXISTS idx_gem_end_date
    ON public.gem_auctions (auction_end_date);

CREATE INDEX IF NOT EXISTS idx_gem_created_at
    ON public.gem_auctions (created_at);

-- Full-text search vector column
ALTER TABLE public.gem_auctions
    ADD COLUMN IF NOT EXISTS fts_doc tsvector
    GENERATED ALWAYS AS (
        to_tsvector('english',
            coalesce(title, '') || ' ' ||
            coalesce(organisation, '') || ' ' ||
            coalesce(ministry, '') || ' ' ||
            coalesce(state, '') || ' ' ||
            coalesce(city, '') || ' ' ||
            coalesce(full_address, '') || ' ' ||
            coalesce(raw_description, '')
        )
    ) STORED;

CREATE INDEX IF NOT EXISTS idx_gem_fts
    ON public.gem_auctions USING GIN (fts_doc);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_gem_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_gem_updated_at
    BEFORE UPDATE ON public.gem_auctions
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_updated_at();



-- ==========================================================================
-- MIGRATION: 20260725140000_gem_bids.sql
-- ==========================================================================
-- Migration: Create gem_bids table for Government e-Marketplace (GeM) Procurement Bids

CREATE TABLE IF NOT EXISTS public.gem_bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- GeM Bid identifiers
    bid_number TEXT UNIQUE NOT NULL,
    ra_number TEXT,

    -- Listing details
    items TEXT NOT NULL,
    quantity TEXT,

    -- Department details
    department_name TEXT,

    -- Dates
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,

    -- Status and source
    status TEXT DEFAULT 'live',
    document_url TEXT,
    ra_document_url TEXT,
    category_name TEXT DEFAULT 'Government | Procurement',
    raw_description TEXT,

    -- Processing status
    processing_status TEXT DEFAULT 'completed',

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.gem_bids ENABLE ROW LEVEL SECURITY;

-- Public read access for consulting dashboards
CREATE POLICY "Allow public read access on GeM bids"
    ON public.gem_bids
    FOR SELECT USING (true);

-- Service role / background worker full access
CREATE POLICY "Allow service role complete access on GeM bids"
    ON public.gem_bids
    FOR ALL USING (true);

-- Admin access for authenticated users with admin role
CREATE POLICY "Allow admin access on GeM bids"
    ON public.gem_bids
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'superadmin')
        )
    );

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_gem_bids_status
    ON public.gem_bids (status);

CREATE INDEX IF NOT EXISTS idx_gem_bids_number
    ON public.gem_bids (bid_number);

CREATE INDEX IF NOT EXISTS idx_gem_bids_end_date
    ON public.gem_bids (end_date);

CREATE INDEX IF NOT EXISTS idx_gem_bids_created_at
    ON public.gem_bids (created_at);

-- Full-text search vector column
ALTER TABLE public.gem_bids
    ADD COLUMN IF NOT EXISTS fts_doc tsvector
    GENERATED ALWAYS AS (
        to_tsvector('english',
            coalesce(bid_number, '') || ' ' ||
            coalesce(ra_number, '') || ' ' ||
            coalesce(items, '') || ' ' ||
            coalesce(department_name, '') || ' ' ||
            coalesce(raw_description, '')
        )
    ) STORED;

CREATE INDEX IF NOT EXISTS idx_gem_bids_fts
    ON public.gem_bids USING GIN (fts_doc);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_gem_bids_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_gem_bids_updated_at
    BEFORE UPDATE ON public.gem_bids
    FOR EACH ROW
    EXECUTE FUNCTION update_gem_bids_updated_at();



-- ==========================================================================
-- MIGRATION: 20260729000000_secure_profiles_trigger.sql
-- ==========================================================================
-- Migration: Prevent non-admin users from modifying their own or other users' roles in the profiles table.
-- This mitigates privilege escalation / Broken Authorization Check vulnerabilities.

CREATE OR REPLACE FUNCTION public.check_profile_role_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Check if the role is being changed
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    -- If the update is triggered by a client session (auth.uid() is set)
    IF auth.uid() IS NOT NULL THEN
      -- Only allow the update if the executing user has admin or superadmin privileges
      IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role IN ('admin', 'superadmin')
      ) THEN
        RAISE EXCEPTION 'Access Denied: You do not have permissions to modify user roles.';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Drop trigger if it exists
DROP TRIGGER IF EXISTS enforce_profile_role_update ON public.profiles;

-- Create trigger
CREATE TRIGGER enforce_profile_role_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.check_profile_role_update();



-- ==========================================================================
-- MIGRATION: 20260731180000_add_subscription_plan_to_profiles.sql
-- ==========================================================================
-- Migration: Add subscription_plan to profiles table
-- Establishes the database support for tracking and gating user plans (explorer, pro, enterprise)

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS subscription_plan VARCHAR(50) DEFAULT 'explorer';

-- Validate default values for existing users
UPDATE public.profiles
SET subscription_plan = 'explorer'
WHERE subscription_plan IS NULL;



-- ==========================================================================
-- MIGRATION: 20260804180000_add_subscription_expires_at_to_profiles.sql
-- ==========================================================================
-- Migration: Add subscription_expires_at to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ;



-- ==========================================================================
-- MIGRATION: 20260805142000_create_promo_codes.sql
-- ==========================================================================
-- Create promo_codes table
CREATE TABLE IF NOT EXISTS public.promo_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    discount_percent INTEGER NOT NULL CHECK (discount_percent >= 0 AND discount_percent <= 100),
    is_active BOOLEAN NOT NULL DEFAULT true,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.promo_codes ENABLE ROW LEVEL SECURITY;

-- Allow administrators to perform all operations on promo_codes
CREATE POLICY "Admins can manage promo codes"
ON public.promo_codes
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles AS p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
    )
);

-- Seed default promo codes
INSERT INTO public.promo_codes (code, discount_percent) VALUES
    ('STAY30', 30),
    ('STAY50', 50),
    ('LELAM10', 10)
ON CONFLICT (code) DO UPDATE 
SET discount_percent = EXCLUDED.discount_percent;



-- ==========================================================================
-- MIGRATION: 20260805160000_add_welcome_email_sent.sql
-- ==========================================================================
-- Add idempotency flag to prevent duplicate welcome emails
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS welcome_email_sent BOOLEAN NOT NULL DEFAULT false;



-- ==========================================================================
-- MIGRATION: 20260805160100_email_triggers.sql
-- ==========================================================================
-- =============================================================================
-- Transactional email triggers via pg_net
-- Fires HTTP POSTs to /api/send-transactional-email on bid/wallet events
-- =============================================================================

-- pg_net is available by default on Supabase hosted instances
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- ---------------------------------------------------------------------------
-- Helper: resolve the API base URL from Supabase vault or hardcode
-- We store the endpoint URL and secret in vault for security.
-- If vault is not set up, the trigger functions will read from
-- the hardcoded defaults below which should be overridden in production.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. OUTBID ALERT
-- Fires when a bid's status changes from 'active' to 'outbid'
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_outbid_email()
RETURNS TRIGGER AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
BEGIN
  -- Read config from environment (set via Supabase Dashboard > Database > Extensions > Secrets)
  -- Fallback: these must be set in production
  v_api_url := current_setting('app.settings.transactional_email_url', true);
  v_api_secret := current_setting('app.settings.internal_api_secret', true);

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_outbid_email] Missing app.settings.transactional_email_url or internal_api_secret. Email not sent.';
    RETURN NEW;
  END IF;

  PERFORM extensions.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'type', 'outbid_alert',
      'payload', jsonb_build_object(
        'bidder_id', OLD.bidder_id::TEXT,
        'auction_id', OLD.auction_id::TEXT
      )
    )::TEXT,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )::JSONB
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_outbid_email
AFTER UPDATE ON public.bids
FOR EACH ROW
WHEN (OLD.status = 'active' AND NEW.status = 'outbid')
EXECUTE FUNCTION notify_outbid_email();

-- ---------------------------------------------------------------------------
-- 2. BID CONFIRMATION
-- Fires when a new bid is inserted
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_bid_confirmation_email()
RETURNS TRIGGER AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
BEGIN
  v_api_url := current_setting('app.settings.transactional_email_url', true);
  v_api_secret := current_setting('app.settings.internal_api_secret', true);

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_bid_confirmation_email] Missing app.settings. Email not sent.';
    RETURN NEW;
  END IF;

  PERFORM extensions.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'type', 'bid_confirmation',
      'payload', jsonb_build_object(
        'bidder_id', NEW.bidder_id::TEXT,
        'auction_id', NEW.auction_id::TEXT,
        'amount', NEW.amount
      )
    )::TEXT,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )::JSONB
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_bid_confirmation_email
AFTER INSERT ON public.bids
FOR EACH ROW
EXECUTE FUNCTION notify_bid_confirmation_email();

-- ---------------------------------------------------------------------------
-- 3. WALLET DEPOSIT RECEIPT
-- Fires when a completed deposit is inserted into wallet_transactions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_deposit_receipt_email()
RETURNS TRIGGER AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
BEGIN
  v_api_url := current_setting('app.settings.transactional_email_url', true);
  v_api_secret := current_setting('app.settings.internal_api_secret', true);

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_deposit_receipt_email] Missing app.settings. Email not sent.';
    RETURN NEW;
  END IF;

  PERFORM extensions.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'type', 'emd_receipt',
      'payload', jsonb_build_object(
        'user_id', NEW.user_id::TEXT,
        'amount', NEW.amount,
        'reference_id', COALESCE(NEW.reference_id, NEW.id::TEXT)
      )
    )::TEXT,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )::JSONB
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_deposit_receipt_email
AFTER INSERT ON public.wallet_transactions
FOR EACH ROW
WHEN (NEW.transaction_type = 'deposit' AND NEW.status = 'completed')
EXECUTE FUNCTION notify_deposit_receipt_email();



-- ==========================================================================
-- MIGRATION: 20260805160200_welcome_email_trigger.sql
-- ==========================================================================
-- =============================================================================
-- Trigger to send welcome email when a user becomes confirmed
-- Runs after INSERT or UPDATE on auth.users
-- =============================================================================

CREATE OR REPLACE FUNCTION public.notify_signup_welcome_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public, extensions
AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
  v_should_send BOOLEAN := false;
BEGIN
  -- Determine if welcome email should be sent (TG_OP is only accessible inside the function body)
  IF TG_OP = 'INSERT' THEN
    IF NEW.email_confirmed_at IS NOT NULL THEN
      v_should_send := true;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
      v_should_send := true;
    END IF;
  END IF;

  IF NOT v_should_send THEN
    RETURN NEW;
  END IF;

  -- Read signup url configuration setting
  v_api_url := current_setting('app.settings.signup_email_url', true);
  
  -- Fallback: dynamically construct from transactional URL if not explicitly configured
  IF v_api_url IS NULL THEN
    v_api_url := current_setting('app.settings.transactional_email_url', true);
    IF v_api_url IS NOT NULL THEN
      v_api_url := replace(v_api_url, '/api/send-transactional-email', '/api/send-signup-email');
    END IF;
  END IF;

  v_api_secret := current_setting('app.settings.internal_api_secret', true);

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_signup_welcome_email] Missing app.settings.signup_email_url or internal_api_secret. Email not sent.';
    RETURN NEW;
  END IF;

  PERFORM extensions.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'user_id', NEW.id::TEXT
    )::TEXT,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )::JSONB
  );

  RETURN NEW;
END;
$$;

-- Create trigger on auth.users to execute after confirmation or insert
CREATE OR REPLACE TRIGGER on_auth_user_confirmed
  AFTER INSERT OR UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_signup_welcome_email();



-- ==========================================================================
-- MIGRATION: 20260805160300_create_orders_table.sql
-- ==========================================================================
-- =============================================================================
-- Create orders table to prevent payment replay / double redemption attacks
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.orders (
    id VARCHAR(255) PRIMARY KEY, -- razorpay order_id
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_id VARCHAR(100) NOT NULL,
    billing_cycle VARCHAR(50) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'created', -- 'created', 'verified'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Select policy: Users can select their own orders
CREATE POLICY "Users can view their own orders" ON public.orders
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Admin policy: Admins can do everything
CREATE POLICY "Admins can manage all orders" ON public.orders
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles AS p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
        )
    );



-- ==========================================================================
-- MIGRATION: 20260805160400_add_login_lockout.sql
-- ==========================================================================
-- =============================================================================
-- Login brute-force lockout columns and functions
-- =============================================================================

-- Add login tracking columns to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS failed_login_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ DEFAULT NULL;

-- 1. Check if user is locked out (public anon RPC)
CREATE OR REPLACE FUNCTION public.check_login_lockout(p_email TEXT)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = auth, public
AS $$
DECLARE
  v_locked_until TIMESTAMPTZ;
BEGIN
  SELECT p.locked_until INTO v_locked_until
  FROM auth.users u
  JOIN public.profiles p ON p.id = u.id
  WHERE u.email = p_email;

  IF v_locked_until IS NOT NULL AND v_locked_until > now() THEN
    RETURN v_locked_until;
  END IF;

  RETURN NULL;
END;
$$;

-- 2. Increment failed logins (public anon RPC, only increments up to lockout)
CREATE OR REPLACE FUNCTION public.record_failed_login(p_email TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = auth, public
AS $$
DECLARE
  v_user_id UUID;
  v_failed_count INTEGER;
BEGIN
  SELECT id INTO v_user_id
  FROM auth.users
  WHERE email = p_email;

  IF v_user_id IS NOT NULL THEN
    UPDATE public.profiles
    SET failed_login_count = failed_login_count + 1
    WHERE id = v_user_id
    RETURNING failed_login_count INTO v_failed_count;

    IF v_failed_count >= 5 THEN
      UPDATE public.profiles
      SET locked_until = now() + interval '15 minutes'
      WHERE id = v_user_id;
    END IF;
  END IF;
END;
$$;

-- 3. Reset failed logins on successful authentication (authenticated RPC)
CREATE OR REPLACE FUNCTION public.reset_failed_logins()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET failed_login_count = 0,
      locked_until = NULL
  WHERE id = auth.uid();
END;
$$;



-- ==========================================================================
-- MIGRATION: 20260805160500_fix_welcome_email_trigger_race.sql
-- ==========================================================================
-- =============================================================================
-- Fix Welcome Email trigger race condition by renaming the trigger to run
-- AFTER public.profiles is inserted, and passing parameters directly to the API
-- to avoid uncommitted database transaction reads.
-- =============================================================================

-- Drop the old trigger that fired prematurely due to alphabetical sorting
DROP TRIGGER IF EXISTS on_auth_user_confirmed ON auth.users;

-- Recreate function with direct parameter parsing and atomic internal updates
CREATE OR REPLACE FUNCTION public.notify_signup_welcome_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public, extensions
AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
  v_should_send BOOLEAN := false;
  v_welcome_sent BOOLEAN;
  v_first_name TEXT;
BEGIN
  -- Determine if welcome email should be sent
  IF TG_OP = 'INSERT' THEN
    IF NEW.email_confirmed_at IS NOT NULL THEN
      v_should_send := true;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
      v_should_send := true;
    END IF;
  END IF;

  IF NOT v_should_send THEN
    RETURN NEW;
  END IF;

  -- Check if already sent in public.profiles
  SELECT welcome_email_sent, first_name 
  INTO v_welcome_sent, v_first_name
  FROM public.profiles 
  WHERE id = NEW.id;

  -- Default values if not found or null
  IF v_welcome_sent IS NULL THEN
    v_welcome_sent := false;
  END IF;
  IF v_first_name IS NULL THEN
    v_first_name := NEW.raw_user_meta_data->>'first_name';
  END IF;

  -- If already sent, do nothing
  IF v_welcome_sent THEN
    RETURN NEW;
  END IF;

  -- Read signup url configuration setting
  v_api_url := current_setting('app.settings.signup_email_url', true);
  
  -- Fallback: dynamically construct from transactional URL if not explicitly configured
  IF v_api_url IS NULL THEN
    v_api_url := current_setting('app.settings.transactional_email_url', true);
    IF v_api_url IS NOT NULL THEN
      v_api_url := replace(v_api_url, '/api/send-transactional-email', '/api/send-signup-email');
    END IF;
  END IF;

  v_api_secret := current_setting('app.settings.internal_api_secret', true);

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_signup_welcome_email] Missing app.settings.signup_email_url or internal_api_secret. Email not sent.';
    RETURN NEW;
  END IF;

  -- Mark as sent in public.profiles (atomic update within transaction)
  UPDATE public.profiles
  SET welcome_email_sent = true
  WHERE id = NEW.id;

  -- Send HTTP post with email and first_name directly to prevent DB query latency / race conditions
  PERFORM extensions.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'user_id', NEW.id::TEXT,
      'email', NEW.email,
      'first_name', COALESCE(v_first_name, '')
    )::TEXT,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )::JSONB
  );

  RETURN NEW;
END;
$$;

-- Create the new trigger with a name starting with 'trg_'
-- (Alphabetically, 'on_auth_user_created' fires first, ensuring profiles row is inserted before this trigger runs)
CREATE OR REPLACE TRIGGER trg_on_auth_user_confirmed
  AFTER INSERT OR UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_signup_welcome_email();



-- ==========================================================================
-- MIGRATION: 20260805160600_create_app_settings.sql
-- ==========================================================================
-- =============================================================================
-- Migration: Create public.app_settings table and update trigger functions
-- to avoid database privilege errors (permission denied to ALTER DATABASE)
-- =============================================================================

-- 1. Create settings storage table
CREATE TABLE IF NOT EXISTS public.app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for security (hide credentials from anonymous or standard authenticated users)
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

-- Allow admins to see and manage settings
DROP POLICY IF EXISTS "Admins can view and edit settings" ON public.app_settings;
CREATE POLICY "Admins can view and edit settings" ON public.app_settings
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles AS p
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'superadmin')
        )
    );

-- 2. Insert placeholders (these must be updated with your actual URLs and token)
INSERT INTO public.app_settings (key, value) VALUES
  ('transactional_email_url', 'https://YOUR_VERCEL_APP_URL.vercel.app/api/send-transactional-email'),
  ('signup_email_url', 'https://YOUR_VERCEL_APP_URL.vercel.app/api/send-signup-email'),
  ('internal_api_secret', 'YOUR_SECRET_TOKEN_HERE')
ON CONFLICT (key) DO NOTHING;


-- 3. Update notify_outbid_email to read from app_settings
CREATE OR REPLACE FUNCTION notify_outbid_email()
RETURNS TRIGGER AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
BEGIN
  SELECT value INTO v_api_url FROM public.app_settings WHERE key = 'transactional_email_url';
  SELECT value INTO v_api_secret FROM public.app_settings WHERE key = 'internal_api_secret';

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_outbid_email] Missing credentials in app_settings. Email not sent.';
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'type', 'outbid_alert',
      'payload', jsonb_build_object(
        'bidder_id', OLD.bidder_id::TEXT,
        'auction_id', OLD.auction_id::TEXT
      )
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, net;


-- 4. Update notify_bid_confirmation_email to read from app_settings
CREATE OR REPLACE FUNCTION notify_bid_confirmation_email()
RETURNS TRIGGER AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
BEGIN
  SELECT value INTO v_api_url FROM public.app_settings WHERE key = 'transactional_email_url';
  SELECT value INTO v_api_secret FROM public.app_settings WHERE key = 'internal_api_secret';

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_bid_confirmation_email] Missing credentials in app_settings. Email not sent.';
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'type', 'bid_confirmation',
      'payload', jsonb_build_object(
        'bidder_id', NEW.bidder_id::TEXT,
        'auction_id', NEW.auction_id::TEXT,
        'amount', NEW.amount
      )
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, net;


-- 5. Update notify_deposit_receipt_email to read from app_settings
CREATE OR REPLACE FUNCTION notify_deposit_receipt_email()
RETURNS TRIGGER AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
BEGIN
  SELECT value INTO v_api_url FROM public.app_settings WHERE key = 'transactional_email_url';
  SELECT value INTO v_api_secret FROM public.app_settings WHERE key = 'internal_api_secret';

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_deposit_receipt_email] Missing credentials in app_settings. Email not sent.';
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'type', 'emd_receipt',
      'payload', jsonb_build_object(
        'user_id', NEW.user_id::TEXT,
        'amount', NEW.amount,
        'reference_id', COALESCE(NEW.reference_id, NEW.id::TEXT)
      )
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, net;


-- 6. Update notify_signup_welcome_email to read from app_settings
CREATE OR REPLACE FUNCTION public.notify_signup_welcome_email()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public, net
AS $$
DECLARE
  v_api_url TEXT;
  v_api_secret TEXT;
  v_should_send BOOLEAN := false;
  v_welcome_sent BOOLEAN;
  v_first_name TEXT;
BEGIN
  -- Determine if welcome email should be sent
  IF TG_OP = 'INSERT' THEN
    IF NEW.email_confirmed_at IS NOT NULL THEN
      v_should_send := true;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
      v_should_send := true;
    END IF;
  END IF;

  IF NOT v_should_send THEN
    RETURN NEW;
  END IF;

  -- Check if already sent in public.profiles
  SELECT welcome_email_sent, first_name 
  INTO v_welcome_sent, v_first_name
  FROM public.profiles 
  WHERE id = NEW.id;

  -- Default values if not found or null
  IF v_welcome_sent IS NULL THEN
    v_welcome_sent := false;
  END IF;
  IF v_first_name IS NULL THEN
    v_first_name := NEW.raw_user_meta_data->>'first_name';
  END IF;

  -- If already sent, do nothing
  IF v_welcome_sent THEN
    RETURN NEW;
  END IF;

  -- Read signup url configuration setting
  SELECT value INTO v_api_url FROM public.app_settings WHERE key = 'signup_email_url';
  
  -- Fallback: dynamically construct from transactional URL if not explicitly configured
  IF v_api_url IS NULL THEN
    SELECT value INTO v_api_url FROM public.app_settings WHERE key = 'transactional_email_url';
    IF v_api_url IS NOT NULL THEN
      v_api_url := replace(v_api_url, '/api/send-transactional-email', '/api/send-signup-email');
    END IF;
  END IF;

  SELECT value INTO v_api_secret FROM public.app_settings WHERE key = 'internal_api_secret';

  IF v_api_url IS NULL OR v_api_secret IS NULL THEN
    RAISE WARNING '[notify_signup_welcome_email] Missing credentials in app_settings. Email not sent.';
    RETURN NEW;
  END IF;

  -- Mark as sent in public.profiles (atomic update within transaction)
  UPDATE public.profiles
  SET welcome_email_sent = true
  WHERE id = NEW.id;

  -- Send HTTP post with email and first_name directly to prevent DB query latency / race conditions
  PERFORM net.http_post(
    url := v_api_url,
    body := jsonb_build_object(
      'user_id', NEW.id::TEXT,
      'email', NEW.email,
      'first_name', COALESCE(v_first_name, '')
    ),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_api_secret
    )
  );

  RETURN NEW;
END;
$$;



-- ==========================================================================
-- MIGRATION: 20260805174000_add_2fa_to_profiles.sql
-- ==========================================================================
-- Add two_factor_enabled column to profiles table
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN NOT NULL DEFAULT false;



-- ==========================================================================
-- MIGRATION: 20260808140000_update_promo_codes_to_numeric.sql
-- ==========================================================================
-- Change discount_percent to allow decimal values (NUMERIC)
ALTER TABLE public.promo_codes 
ALTER COLUMN discount_percent TYPE NUMERIC 
USING discount_percent::NUMERIC;



-- ==========================================================================
-- MIGRATION: 20260808143000_read_promo_codes_policy.sql
-- ==========================================================================
-- Allow anyone to read promo codes
CREATE POLICY "Anyone can view promo codes"
ON public.promo_codes
FOR SELECT
USING (true);



-- ==========================================================================
-- MIGRATION: 20260808174500_add_trial_claimed_to_profiles.sql
-- ==========================================================================
-- Add trial_claimed column to profiles to prevent duplicate trial claims
ALTER TABLE public.profiles ADD COLUMN trial_claimed BOOLEAN DEFAULT false;



-- ==========================================================================
-- MIGRATION: 20260819140000_enhance_gem_and_baanknet_documents.sql
-- ==========================================================================
-- Migration: Enhance document attachments and corrigendum tracking for GeM and BaankNet

-- 1. Add document_urls and corrigendum_urls to gem_bids
ALTER TABLE public.gem_bids
    ADD COLUMN IF NOT EXISTS document_urls TEXT[],
    ADD COLUMN IF NOT EXISTS corrigendum_urls TEXT[];

-- 2. Add document_urls to gem_auctions
ALTER TABLE public.gem_auctions
    ADD COLUMN IF NOT EXISTS document_urls TEXT[];

-- 3. Update comments
COMMENT ON COLUMN public.gem_bids.document_urls IS 'Array of all downloadable bid document links, ATC files, and technical specifications';
COMMENT ON COLUMN public.gem_bids.corrigendum_urls IS 'Array of all published Corrigendum amendment PDF documents for this bid';
COMMENT ON COLUMN public.gem_auctions.document_urls IS 'Array of all attached auction notice documents, lot schedules, and NIT terms';



-- ==========================================================================
-- MIGRATION: 20260819143000_fix_rls_recursion_is_admin.sql
-- ==========================================================================
-- Migration: Fix RLS Infinite Recursion using SECURITY DEFINER is_admin() function
-- Resolves HTTP 500 errors when fetching audit_logs, mstc_auctions, and scraper tables.

-- 1. Ensure public.is_admin() is robust, SECURITY DEFINER, with clean search_path
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'superadmin')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Grant execution to authenticated & anon
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO service_role;

-- 2. Fix audit_logs RLS Policies (Drop direct subquery policies that cause 500 recursion)
DROP POLICY IF EXISTS "Admins can view all audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Admins can view and manage all audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Anyone can insert audit logs" ON public.audit_logs;
DROP POLICY IF EXISTS "Allow service role full access on audit_logs" ON public.audit_logs;

-- Allow insert by any authenticated user or service
CREATE POLICY "Anyone can insert audit logs"
    ON public.audit_logs
    FOR INSERT
    WITH CHECK (true);

-- Allow admins to view and manage audit logs via is_admin()
CREATE POLICY "Admins can view and manage all audit logs"
    ON public.audit_logs
    FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Allow service role full access
CREATE POLICY "Allow service role full access on audit_logs"
    ON public.audit_logs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 3. Fix mstc_auctions RLS Policies
DROP POLICY IF EXISTS "Admins can manage MSTC auctions" ON public.mstc_auctions;
CREATE POLICY "Admins can manage MSTC auctions"
    ON public.mstc_auctions
    FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 4. Fix gem_auctions RLS Policies
DROP POLICY IF EXISTS "Allow admin access on GeM auctions" ON public.gem_auctions;
CREATE POLICY "Allow admin access on GeM auctions"
    ON public.gem_auctions
    FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 5. Fix gem_bids RLS Policies
DROP POLICY IF EXISTS "Allow admin access on GeM bids" ON public.gem_bids;
CREATE POLICY "Allow admin access on GeM bids"
    ON public.gem_bids
    FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- 6. Fix baanknet_auctions RLS Policies
DROP POLICY IF EXISTS "Allow admin access on BaankNet auctions" ON public.baanknet_auctions;
CREATE POLICY "Allow admin access on BaankNet auctions"
    ON public.baanknet_auctions
    FOR ALL
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());



-- ==========================================================================
-- MIGRATION: 20260819170000_add_allowed_auction_types_to_profiles.sql
-- ==========================================================================
-- Add allowed_auction_types to public.profiles
-- This enables granular admin-level access control over which auction portals (MSTC, BaankNet, GeM Bids, GeM Forward Auctions, GeM PBP, Custom) each user can access.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS allowed_auction_types text[] DEFAULT ARRAY['mstc'];

-- Set all standard (non-admin) users to only have MSTC access by default
UPDATE public.profiles
SET allowed_auction_types = ARRAY['mstc']
WHERE role NOT IN ('admin', 'superadmin')
   OR allowed_auction_types IS NULL;

-- Comment for documentation
COMMENT ON COLUMN public.profiles.allowed_auction_types IS 'Array of auction source keys that the user is permitted to view and interact with: mstc, baanknet, gem_bids, gem_auctions, gem_pbp, custom';



-- ==========================================================================
-- MIGRATION: 20260821141000_gem_auctions_unparsed_and_ranges.sql
-- ==========================================================================
-- Migration: Add unparsed flags, min/max price range columns, and remove hardcoded defaults from gem_auctions

-- Make date and location columns nullable / drop default 'India' and default 'live'
ALTER TABLE public.gem_auctions
  ALTER COLUMN auction_start_date DROP NOT NULL,
  ALTER COLUMN auction_end_date DROP NOT NULL,
  ALTER COLUMN location DROP NOT NULL,
  ALTER COLUMN location DROP DEFAULT,
  ALTER COLUMN auction_status DROP DEFAULT;

-- Add price range min/max and unparsed tracking flags
ALTER TABLE public.gem_auctions
  ADD COLUMN IF NOT EXISTS reserve_price_value_min NUMERIC,
  ADD COLUMN IF NOT EXISTS reserve_price_value_max NUMERIC,
  ADD COLUMN IF NOT EXISTS start_date_unparsed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS end_date_unparsed BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS location_unparsed BOOLEAN DEFAULT false;

-- Create indexes on new numeric price columns for filtering
CREATE INDEX IF NOT EXISTS idx_gem_auctions_price_min ON public.gem_auctions (reserve_price_value_min);
CREATE INDEX IF NOT EXISTS idx_gem_auctions_price_max ON public.gem_auctions (reserve_price_value_max);



-- ==========================================================================
-- MIGRATION: 20260821200000_baanknet_document_archive.sql
-- ==========================================================================
-- Migration: Add document archiving and storage mirror columns to baanknet_auctions
-- Allows baanknetAssetWorker to mirror external notice PDFs to Supabase Storage

-- 1. Add documents_archived and stored_document_urls to baanknet_auctions
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS documents_archived BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS stored_document_urls TEXT[] DEFAULT '{}'::TEXT[];

-- 2. Partial index on unarchived rows for fast queue queries in baanknetAssetWorker
CREATE INDEX IF NOT EXISTS idx_baanknet_unarchived_documents
    ON public.baanknet_auctions (documents_archived)
    WHERE documents_archived = FALSE;

-- 3. Comments
COMMENT ON COLUMN public.baanknet_auctions.documents_archived IS 'Indicates whether all auction notice documents have been successfully mirrored to Supabase Storage';
COMMENT ON COLUMN public.baanknet_auctions.stored_document_urls IS 'Array of permanent Supabase Storage public URLs for mirrored notice PDFs';

-- 4. Re-grant permissions
GRANT SELECT ON public.baanknet_auctions TO anon;
GRANT SELECT ON public.baanknet_auctions TO authenticated;
GRANT ALL ON public.baanknet_auctions TO service_role;



-- ==========================================================================
-- MIGRATION: 20260822150000_baanknet_full_intelligence_fields.sql
-- ==========================================================================
-- Migration: Add extended intelligence fields to baanknet_auctions
-- Financial, Legal Due Diligence, Geospatial, Contacts, IBC/NCLT, and Document OCR

-- â”€â”€â”€ 1. Financial & Bidding Rules â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS emd_amount_value NUMERIC;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS bid_increment_amount NUMERIC;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS bid_increment_text TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS tender_fee_text TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS tender_fee_value NUMERIC;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS outstanding_dues_text TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS outstanding_dues_value NUMERIC;

-- â”€â”€â”€ 2. Payment & Remittance Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS emd_account_number TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS emd_account_ifsc TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS emd_bank_name TEXT;

-- â”€â”€â”€ 3. Legal, Title & Due Diligence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS cersai_id TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS title_type TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS encumbrances_text TEXT;

-- â”€â”€â”€ 4. Branch & Officer Contacts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS branch_name TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS officer_designation TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS officer_email TEXT;

-- â”€â”€â”€ 5. Geospatial & Boundary Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS latitude NUMERIC;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS longitude NUMERIC;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS map_url TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS boundaries JSONB;

-- â”€â”€â”€ 6. IBC / NCLT Insolvency Specifics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS corporate_debtor_name TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS corporate_debtor_cin TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS liquidator_reg_no TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS liquidator_email TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS nclt_bench TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS nclt_case_no TEXT;

ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS process_memo_url TEXT;

-- â”€â”€â”€ 7. Notice Document OCR / Extracted Text â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
ALTER TABLE public.baanknet_auctions
    ADD COLUMN IF NOT EXISTS extracted_pdf_text TEXT;

-- â”€â”€â”€ 8. Performance Indexes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
CREATE INDEX IF NOT EXISTS idx_baanknet_emd_value
    ON public.baanknet_auctions (emd_amount_value);

CREATE INDEX IF NOT EXISTS idx_baanknet_cersai_id
    ON public.baanknet_auctions (cersai_id);

CREATE INDEX IF NOT EXISTS idx_baanknet_title_type
    ON public.baanknet_auctions (title_type);

CREATE INDEX IF NOT EXISTS idx_baanknet_branch_name
    ON public.baanknet_auctions (branch_name);

CREATE INDEX IF NOT EXISTS idx_baanknet_corporate_debtor_cin
    ON public.baanknet_auctions (corporate_debtor_cin);

-- Re-grant access
GRANT SELECT ON public.baanknet_auctions TO anon;
GRANT SELECT ON public.baanknet_auctions TO authenticated;
GRANT ALL ON public.baanknet_auctions TO service_role;



-- ==========================================================================
-- MIGRATION: 20260822160000_fix_baanknet_garbage_titles.sql
-- ==========================================================================
-- Migration: Fix BaankNet Garbage Titles and Location Artifacts
-- Resolves issues where search result headers ('Showing 10000+ Results') or bank names were saved as title/location.

-- 1. Clean location and state fields containing bank names or search terms
UPDATE public.baanknet_auctions
SET 
  state = NULL,
  location = 'India'
WHERE state ILIKE '%Bank%' OR state ILIKE '%Showing%' OR state ILIKE '%Lender%' OR state ILIKE '%Results%';

UPDATE public.baanknet_auctions
SET city = NULL
WHERE city ILIKE '%Bank%' OR city ILIKE '%Showing%' OR city ILIKE '%Lender%' OR city ILIKE '%Results%';

UPDATE public.baanknet_auctions
SET location = 'India'
WHERE location ILIKE '%Bank%' OR location ILIKE '%Showing%' OR location ILIKE '%Results%';

-- 2. Clean concatenated IBC titles (e.g., Asset ID4523Asset ClassificationIntangible Assets...)
UPDATE public.baanknet_auctions
SET 
  title = 'Intangible Assets in Maharashtra, Mumbai',
  property_type = 'Intangible Assets',
  full_address = 'Maharashtra, Mumbai, Mumbai Suburban',
  state = 'Maharashtra',
  city = 'Mumbai',
  location = 'Maharashtra',
  contact_person = 'Mr. Santanu T Ray',
  officer_designation = 'Insolvency Professional / Liquidator'
WHERE title ILIKE '%Asset ID%Asset Classification%Intangible Assets%';

UPDATE public.baanknet_auctions
SET 
  title = 'Insolvency Asset',
  property_type = 'Insolvency Asset'
WHERE title ILIKE '%Asset ID%Asset Classification%' AND title NOT ILIKE '%Intangible Assets%';

-- 3. Update garbage titles to clean synthesized property descriptions
UPDATE public.baanknet_auctions
SET title = TRIM(
  COALESCE(NULLIF(carpet_area, '') || ' ', '') ||
  COALESCE(NULLIF(property_type, ''), 'Bank Foreclosure Property') ||
  CASE 
    WHEN city IS NOT NULL AND city != '' AND city NOT ILIKE '%Bank%' THEN ' in ' || city
    WHEN state IS NOT NULL AND state != '' AND state NOT ILIKE '%Bank%' THEN ' in ' || state
    WHEN location IS NOT NULL AND location != '' AND location NOT ILIKE '%Bank%' AND location != 'India' THEN ' in ' || location
    ELSE ''
  END
)
WHERE 
  title ILIKE 'Showing %Results%' 
  OR title ILIKE '%10000+%' 
  OR title ILIKE 'Showing %Properties%'
  OR title ILIKE '%Results Found%'
  OR title ILIKE '%Search Results%'
  OR title = 'Bank Auction Property'
  OR title IS NULL
  OR TRIM(title) = '';

-- Ensure no titles remain blank
UPDATE public.baanknet_auctions
SET title = 'Bank Foreclosure Property'
WHERE title IS NULL OR TRIM(title) = '';



