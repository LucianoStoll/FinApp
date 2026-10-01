/// Datas de negócio explícitas. `created_at` permanece metadado técnico;
/// `competence_at`/`planned_at` preservam o período dos registros anteriores.
const schemaV5 = <String>[
  'ALTER TABLE transactions ADD COLUMN posted_at INTEGER',
  'UPDATE transactions SET posted_at = competence_at',
  'UPDATE transactions SET due_at = competence_at WHERE due_at IS NULL',
  'ALTER TABLE transfers ADD COLUMN posted_at INTEGER',
  'ALTER TABLE transfers ADD COLUMN due_at INTEGER',
  'UPDATE transfers SET posted_at = planned_at, due_at = planned_at',
  'CREATE INDEX idx_transactions_due_at ON transactions(due_at)',
  'CREATE INDEX idx_transfers_due_at ON transfers(due_at)',
];
