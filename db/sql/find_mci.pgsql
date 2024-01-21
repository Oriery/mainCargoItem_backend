DROP FUNCTION IF EXISTS get_subtree (integer);

CREATE
OR REPLACE FUNCTION get_subtree (root_id integer) RETURNS TABLE (
  id integer,
  containedIn_id integer,
  depth integer,
  sameRouteAsParent boolean
) AS $$
  WITH RECURSIVE
  subtree_cte AS (
    SELECT
      id,
      containedIn_id,
      0 as depth,
	  fromLocation_id,
	  toLocation_id,
      false as sameRouteAsParent
    FROM
      oriery_mci_item
    WHERE
      id = root_id
    UNION ALL
    SELECT
      c.id,
      c.containedIn_id,
      p.depth + 1 as depth,
	  c.fromLocation_id,
	  c.toLocation_id,
      c.fromLocation_id = p.fromLocation_id
      AND c.toLocation_id = p.toLocation_id AS sameRouteAsParent
    FROM
      oriery_mci_item c
      JOIN subtree_cte p ON c.containedIn_id = p.id
  )
SELECT
  id,
  containedIn_id,
  depth,
  sameRouteAsParent
FROM
  subtree_cte;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS get_mci_info_tree (integer);

CREATE
OR REPLACE FUNCTION get_mci_info_tree (root_id integer) RETURNS TABLE (
  id integer,
  is_mci boolean,
  mci_id integer
) AS $$
DECLARE
  max_depth integer;
BEGIN
  -- if no such item, throw error
  IF NOT EXISTS (SELECT * FROM oriery_mci_item i WHERE i.id = root_id) THEN
    RAISE EXCEPTION 'No item with id %', root_id;
  END IF;

  -- get tree
  CREATE TEMP TABLE subtree AS
    SELECT 
      *, 
      TRUE AS decendantsHaveSameRoute,
      FALSE AS is_mci,
      CAST(NULL AS INTEGER) AS mci_id
    FROM get_subtree(root_id);

  -- get max depth
  SELECT max(st.depth) INTO max_depth FROM subtree st;

  -- set decendantsHaveSameRoute
  FOR i IN REVERSE max_depth..0 LOOP
    UPDATE subtree i1
    SET
      decendantsHaveSameRoute = NOT EXISTS (
        SELECT
          *
        FROM
          subtree i2
        WHERE
          i2.containedIn_id = i1.id
          AND (i2.decendantsHaveSameRoute = false
          OR i2.samerouteasparent = false)
      )
    WHERE
      i1.depth = i;
  END LOOP;

  -- set is_mci
  UPDATE subtree i
  SET is_mci = i.decendantsHaveSameRoute = true AND (i.containedIn_id IS NULL OR p.decendantsHaveSameRoute = false)
  FROM subtree p
  WHERE i.containedIn_id = p.id OR i.containedIn_id IS NULL;

  -- set mci_id
  FOR i IN 0..max_depth LOOP
    UPDATE subtree i1
    SET mci_id = CASE WHEN i1.is_mci THEN i1.id ELSE p.mci_id END
    FROM subtree p
    WHERE i1.depth = i AND (i1.containedIn_id = p.id OR i1.containedIn_id IS NULL);
  END LOOP;


  RETURN QUERY
    SELECT
      s.id,
      s.is_mci,
      s.mci_id
    FROM
      subtree s;

  DROP TABLE subtree;
  
END;
$$ LANGUAGE plpgsql;

SELECT
  *
FROM
  get_mci_info_tree (40);