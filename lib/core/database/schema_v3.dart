/// v3 é aditiva: cores/ícones e regras de hierarquia e histórico de categorias.
const schemaV3 = <String>[
  'ALTER TABLE categories ADD COLUMN icon_key TEXT',
  'ALTER TABLE categories ADD COLUMN color_argb INTEGER',
  '''
  CREATE TRIGGER categories_parent_insert
  BEFORE INSERT ON categories
  WHEN NEW.parent_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM categories p WHERE p.id = NEW.parent_id
      AND p.parent_id IS NULL AND p.type = NEW.type
      AND p.is_archived = 0 AND p.deleted_at IS NULL)
  BEGIN SELECT RAISE(ABORT, 'Categoria principal inválida'); END
  ''',
  '''
  CREATE TRIGGER categories_parent_update
  BEFORE UPDATE OF parent_id, type ON categories
  WHEN (NEW.parent_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM categories p WHERE p.id = NEW.parent_id
      AND p.parent_id IS NULL AND p.type = NEW.type
      AND p.is_archived = 0 AND p.deleted_at IS NULL))
    OR (NEW.parent_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM categories child WHERE child.parent_id = NEW.id))
    OR EXISTS (
      SELECT 1 FROM categories child WHERE child.parent_id = NEW.id
        AND child.type <> NEW.type)
    OR EXISTS (
      SELECT 1 FROM transactions t WHERE t.category_id = NEW.id
        AND t.type <> NEW.type)
  BEGIN SELECT RAISE(ABORT, 'Hierarquia ou tipo de categoria inválido'); END
  ''',
  '''
  CREATE TRIGGER transactions_active_category_insert
  BEFORE INSERT ON transactions
  WHEN NEW.category_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM categories c LEFT JOIN categories p ON p.id = c.parent_id
    WHERE c.id = NEW.category_id AND c.type = NEW.type
      AND c.is_archived = 0 AND c.deleted_at IS NULL
      AND (c.parent_id IS NULL OR (p.is_archived = 0 AND p.deleted_at IS NULL)))
  BEGIN SELECT RAISE(ABORT, 'Categoria inativa ou de outro tipo'); END
  ''',
  '''
  CREATE TRIGGER transactions_active_category_update
  BEFORE UPDATE OF category_id, type ON transactions
  WHEN NEW.category_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM categories c LEFT JOIN categories p ON p.id = c.parent_id
    WHERE c.id = NEW.category_id AND c.type = NEW.type
      AND c.is_archived = 0 AND c.deleted_at IS NULL
      AND (c.parent_id IS NULL OR (p.is_archived = 0 AND p.deleted_at IS NULL)))
  BEGIN SELECT RAISE(ABORT, 'Categoria inativa ou de outro tipo'); END
  ''',
];
