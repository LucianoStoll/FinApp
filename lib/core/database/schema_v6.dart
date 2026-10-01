/// Separa o saldo consolidado dos saldos individuais, sem alterar movimentos.
const schemaV6 = <String>[
  'ALTER TABLE accounts ADD COLUMN include_in_balance INTEGER NOT NULL DEFAULT 1 CHECK (include_in_balance IN (0, 1))',
];
