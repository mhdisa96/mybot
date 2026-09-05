CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  whatsapp_number VARCHAR(20) NOT NULL UNIQUE,
  username VARCHAR(50) UNIQUE,
  password_hash TEXT,
  balance NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
  role VARCHAR(20) NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('SUPER_ADMIN','ADMIN','AGEN','MEMBER')),
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','BLOCKED')),
  registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_wa ON users(whatsapp_number);
CREATE INDEX IF NOT EXISTS idx_users_role_status ON users(role,status);

CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  category VARCHAR(50) NOT NULL,
  provider VARCHAR(100),
  cost_price NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK(cost_price>=0),
  selling_price NUMERIC(18,2) NOT NULL DEFAULT 0 CHECK(selling_price>=0),
  margin NUMERIC(18,2) GENERATED ALWAYS AS (selling_price-cost_price) STORED,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE','BLOCKED')),
  digiflazz_sku VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_products_category_status ON products(category,status);

CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  product_id UUID NOT NULL REFERENCES products(id),
  destination VARCHAR(100) NOT NULL,
  price NUMERIC(18,2) NOT NULL,
  cost_price NUMERIC(18,2),
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','PROCESS','SUCCESS','FAILED','REFUNDED')),
  provider VARCHAR(50),
  provider_reference VARCHAR(150),
  reference VARCHAR(100) NOT NULL UNIQUE,
  idempotency_key VARCHAR(100) NOT NULL UNIQUE,
  serial_number VARCHAR(100),
  failure_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_transactions_user_created ON transactions(user_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_provider_ref ON transactions(provider_reference);

CREATE TABLE IF NOT EXISTS balance_mutations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  type VARCHAR(30) NOT NULL,
  amount NUMERIC(18,2) NOT NULL,
  balance_before NUMERIC(18,2) NOT NULL,
  balance_after NUMERIC(18,2) NOT NULL CHECK(balance_after>=0),
  reference_type VARCHAR(30),
  reference_id UUID,
  description TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_balance_mutations_user_created ON balance_mutations(user_id,created_at DESC);

CREATE TABLE IF NOT EXISTS transaction_status_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  old_status VARCHAR(20),
  new_status VARCHAR(20) NOT NULL,
  message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  amount NUMERIC(18,2) NOT NULL CHECK(amount>0),
  method VARCHAR(30) NOT NULL DEFAULT 'MANUAL',
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','APPROVED','REJECTED','CANCELLED')),
  proof_url TEXT,
  notes TEXT,
  verified_by UUID REFERENCES users(id),
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_deposits_status_created ON deposits(status,created_at DESC);

CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deposit_id UUID NOT NULL REFERENCES deposits(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL,
  provider_reference VARCHAR(150),
  amount NUMERIC(18,2) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  payment_url TEXT,
  qr_string TEXT,
  expired_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(provider,provider_reference)
);

CREATE TABLE IF NOT EXISTS webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider VARCHAR(50) NOT NULL,
  event_id VARCHAR(150) NOT NULL UNIQUE,
  reference VARCHAR(100),
  payload JSONB NOT NULL,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES users(id),
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(50),
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at=NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_transactions_updated_at ON transactions;
CREATE TRIGGER trg_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION set_updated_at();
DROP TRIGGER IF EXISTS trg_deposits_updated_at ON deposits;
CREATE TRIGGER trg_deposits_updated_at BEFORE UPDATE ON deposits FOR EACH ROW EXECUTE FUNCTION set_updated_at();
