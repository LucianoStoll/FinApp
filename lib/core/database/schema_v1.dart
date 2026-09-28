/// Schema imutável da versão 1. Nunca edite estas instruções após publicar a
/// versão; evoluções devem ser adicionadas como migrations subsequentes.
const schemaV1 = <String>[
  '''
  CREATE TABLE accounts (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    type TEXT NOT NULL,
    currency_code TEXT NOT NULL CHECK (length(currency_code) = 3),
    initial_balance_minor INTEGER NOT NULL
      CHECK (typeof(initial_balance_minor) = 'integer'),
    is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
    include_in_analytics INTEGER NOT NULL DEFAULT 1
      CHECK (include_in_analytics IN (0, 1)),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    device_id TEXT,
    sync_version INTEGER NOT NULL DEFAULT 0 CHECK (sync_version >= 0)
  )
  ''',
  '''
  CREATE TABLE categories (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(trim(name)) > 0),
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    parent_id TEXT REFERENCES categories(id) ON DELETE RESTRICT,
    is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    device_id TEXT,
    sync_version INTEGER NOT NULL DEFAULT 0 CHECK (sync_version >= 0),
    CHECK (parent_id IS NULL OR parent_id <> id)
  )
  ''',
  '''
  CREATE TABLE transactions (
    id TEXT NOT NULL PRIMARY KEY,
    description TEXT NOT NULL CHECK (length(trim(description)) > 0),
    type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
    planned_amount_minor INTEGER NOT NULL
      CHECK (typeof(planned_amount_minor) = 'integer' AND planned_amount_minor > 0),
    actual_amount_minor INTEGER
      CHECK (actual_amount_minor IS NULL OR
        (typeof(actual_amount_minor) = 'integer' AND actual_amount_minor > 0)),
    competence_at INTEGER NOT NULL,
    due_at INTEGER,
    effective_at INTEGER,
    account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    category_id TEXT REFERENCES categories(id) ON DELETE RESTRICT,
    ignore_balance INTEGER NOT NULL DEFAULT 0 CHECK (ignore_balance IN (0, 1)),
    ignore_analytics INTEGER NOT NULL DEFAULT 0 CHECK (ignore_analytics IN (0, 1)),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    device_id TEXT,
    sync_version INTEGER NOT NULL DEFAULT 0 CHECK (sync_version >= 0)
  )
  ''',
  '''
  CREATE TABLE transfers (
    id TEXT NOT NULL PRIMARY KEY,
    source_account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    destination_account_id TEXT NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    amount_minor INTEGER NOT NULL
      CHECK (typeof(amount_minor) = 'integer' AND amount_minor > 0),
    effective_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    deleted_at INTEGER,
    device_id TEXT,
    sync_version INTEGER NOT NULL DEFAULT 0 CHECK (sync_version >= 0),
    CHECK (source_account_id <> destination_account_id)
  )
  ''',
  'CREATE INDEX idx_categories_parent ON categories(parent_id)',
  'CREATE INDEX idx_transactions_account_effective ON transactions(account_id, effective_at)',
  'CREATE INDEX idx_transactions_category ON transactions(category_id)',
  'CREATE INDEX idx_transfers_source ON transfers(source_account_id)',
  'CREATE INDEX idx_transfers_destination ON transfers(destination_account_id)',
];
