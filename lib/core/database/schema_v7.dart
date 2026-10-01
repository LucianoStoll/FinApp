/// Descrição das transferências; registros existentes mantêm um nome válido.
const schemaV7 = <String>[
  "ALTER TABLE transfers ADD COLUMN description TEXT NOT NULL DEFAULT 'Transferência' CHECK (length(trim(description)) > 0)",
];
