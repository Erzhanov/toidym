PRAGMA journal_mode = WAL;
CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY, phone TEXT NOT NULL, expires INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS session_expiry ON sessions(expires);
CREATE TABLE IF NOT EXISTS auth_limits (
  scope TEXT NOT NULL, occurred INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS auth_scope ON auth_limits(scope, occurred);
CREATE TABLE IF NOT EXISTS challenges (
  phone TEXT PRIMARY KEY, expires INTEGER NOT NULL, attempts INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS venues (
  id TEXT PRIMARY KEY, owner TEXT NOT NULL UNIQUE, name TEXT NOT NULL, company TEXT NOT NULL,
  address TEXT NOT NULL, district INTEGER NOT NULL, lat REAL NOT NULL, lng REAL NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('review','approved','rejected')),
  review_note TEXT NOT NULL DEFAULT ''
);
CREATE TABLE IF NOT EXISTS staff (
  phone TEXT PRIMARY KEY, venue_id TEXT NOT NULL REFERENCES venues(id)
);
CREATE TABLE IF NOT EXISTS boxes (
  id TEXT PRIMARY KEY, venue_id TEXT NOT NULL REFERENCES venues(id), details TEXT NOT NULL,
  stock INTEGER NOT NULL CHECK(stock >= 0), published INTEGER NOT NULL DEFAULT 1,
  paused INTEGER NOT NULL DEFAULT 0, starts INTEGER NOT NULL, ends INTEGER NOT NULL,
  CHECK(ends > starts)
);
CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY, buyer TEXT NOT NULL, request_id TEXT NOT NULL,
  box_id TEXT NOT NULL REFERENCES boxes(id), venue_id TEXT NOT NULL REFERENCES venues(id),
  snapshot TEXT NOT NULL, quantity INTEGER NOT NULL CHECK(quantity > 0),
  code TEXT NOT NULL, qr TEXT NOT NULL UNIQUE, created INTEGER NOT NULL, ends INTEGER NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('reserved','collected','cancelled','expired')),
  collected INTEGER, rating INTEGER NOT NULL DEFAULT 0, feedback TEXT NOT NULL DEFAULT '[]',
  issue TEXT NOT NULL DEFAULT '', resolution TEXT NOT NULL DEFAULT '',
  UNIQUE(buyer, request_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS active_codes ON orders(venue_id,code) WHERE status='reserved';
CREATE INDEX IF NOT EXISTS buyer_orders ON orders(buyer, created);
CREATE INDEX IF NOT EXISTS venue_orders ON orders(venue_id, created);
CREATE TABLE IF NOT EXISTS audit (
  id INTEGER PRIMARY KEY, occurred INTEGER NOT NULL, actor TEXT NOT NULL,
  action TEXT NOT NULL, target TEXT NOT NULL, note TEXT NOT NULL
);
