/// Data planejada da transferência, inclusive quando ainda está pendente.
const schemaV4 = <String>[
  'ALTER TABLE transfers ADD COLUMN planned_at INTEGER',
  'UPDATE transfers SET planned_at = COALESCE(effective_at, created_at)',
];
