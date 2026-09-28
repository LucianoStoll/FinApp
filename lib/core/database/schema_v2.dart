/// Migration aditiva da v1 para v2: impede novos lançamentos em contas
/// arquivadas ou removidas e transferências entre moedas diferentes.
const schemaV2 = <String>[
  '''
  CREATE TRIGGER transactions_active_account_insert
  BEFORE INSERT ON transactions
  WHEN NOT EXISTS (SELECT 1 FROM accounts WHERE id = NEW.account_id
                   AND is_archived = 0 AND deleted_at IS NULL)
  BEGIN SELECT RAISE(ABORT, 'Conta inativa'); END
  ''',
  '''
  CREATE TRIGGER transactions_active_account_update
  BEFORE UPDATE OF account_id ON transactions
  WHEN NOT EXISTS (SELECT 1 FROM accounts WHERE id = NEW.account_id
                   AND is_archived = 0 AND deleted_at IS NULL)
  BEGIN SELECT RAISE(ABORT, 'Conta inativa'); END
  ''',
  '''
  CREATE TRIGGER transfers_active_accounts_insert
  BEFORE INSERT ON transfers
  WHEN NOT EXISTS (
    SELECT 1 FROM accounts source, accounts destination
    WHERE source.id = NEW.source_account_id
      AND destination.id = NEW.destination_account_id
      AND source.is_archived = 0 AND destination.is_archived = 0
      AND source.deleted_at IS NULL AND destination.deleted_at IS NULL
      AND source.currency_code = destination.currency_code)
  BEGIN SELECT RAISE(ABORT, 'Contas inativas ou moedas diferentes'); END
  ''',
  '''
  CREATE TRIGGER transfers_active_accounts_update
  BEFORE UPDATE OF source_account_id, destination_account_id ON transfers
  WHEN NOT EXISTS (
    SELECT 1 FROM accounts source, accounts destination
    WHERE source.id = NEW.source_account_id
      AND destination.id = NEW.destination_account_id
      AND source.is_archived = 0 AND destination.is_archived = 0
      AND source.deleted_at IS NULL AND destination.deleted_at IS NULL
      AND source.currency_code = destination.currency_code)
  BEGIN SELECT RAISE(ABORT, 'Contas inativas ou moedas diferentes'); END
  ''',
];
