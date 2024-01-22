DROP FUNCTION IF EXISTS get_subtree (integer);

CREATE
OR REPLACE FUNCTION get_subtree (root_id integer) RETURNS TABLE (
  id integer,
  containedIn_id integer,
  depth integer,
  sameRouteAsParent boolean,
  isProduct boolean
) AS $$
  WITH RECURSIVE
  subtree_cte AS (
    SELECT
      i.id,
      containedIn_id,
      0 as depth,
      fromLocation_id,
      toLocation_id,
      false as sameRouteAsParent,
      ic.type_id = 0 as isProduct
    FROM
      oriery_mci_item i
      JOIN oriery_mci_itemclass ic ON i.class_id = ic.id
    WHERE
      i.id = root_id
    UNION ALL
    SELECT
      i.id,
      i.containedIn_id,
      p.depth + 1 as depth,
      i.fromLocation_id,
      i.toLocation_id,
      i.fromLocation_id = p.fromLocation_id
      AND i.toLocation_id = p.toLocation_id AS sameRouteAsParent,
      ic.type_id = 0 as isProduct
    FROM
      oriery_mci_item i
      JOIN subtree_cte p ON i.containedIn_id = p.id
      JOIN oriery_mci_itemclass ic ON i.class_id = ic.id
  )
SELECT
  id,
  containedIn_id,
  depth,
  sameRouteAsParent,
  isProduct
FROM
  subtree_cte;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS get_mci_info_tree (integer);

CREATE
OR REPLACE FUNCTION get_mci_info_tree (root_id integer) RETURNS TABLE (id integer, is_mci boolean, mci_id integer) AS $$
DECLARE
  max_depth integer;
  start_time TIMESTAMP;
BEGIN
  -- if no such item, throw error
  IF NOT EXISTS (SELECT * FROM oriery_mci_item i WHERE i.id = root_id) THEN
    RAISE EXCEPTION 'No item with id %', root_id;
  END IF;

  start_time := clock_timestamp();

  -- get tree
  CREATE TEMP TABLE subtree AS
    SELECT 
      *, 
      TRUE AS decendantsHaveSameRoute,
      FALSE AS containesProducts,
      FALSE AS is_mci,
      CAST(NULL AS INTEGER) AS mci_id
    FROM get_subtree(root_id);
  
  RAISE NOTICE 'Duration of "get tree": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  -- create indexes
  --CREATE INDEX ON subtree (id);
  CREATE INDEX ON subtree (containedIn_id);
  --CREATE INDEX ON subtree (depth);

  RAISE NOTICE 'Duration of "create indexes": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  -- get max depth
  SELECT max(st.depth) INTO max_depth FROM subtree st;

  RAISE NOTICE 'Duration of "get max depth": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  -- set decendantsHaveSameRoute
  FOR j IN REVERSE max_depth..0 LOOP
    UPDATE subtree i
    SET
      decendantsHaveSameRoute = NOT EXISTS ( -- TODO: replace with JOIN if possible
        SELECT
          *
        FROM
          subtree child
        WHERE
          child.containedIn_id = i.id
          AND (child.decendantsHaveSameRoute = false
          OR child.samerouteasparent = false)
      ),
      containesProducts = i.isProduct OR EXISTS ( -- TODO: replace with JOIN if possible
        SELECT
          *
        FROM
          subtree child
        WHERE
          child.containedIn_id = i.id
          AND child.containesProducts = true
      )
    WHERE
      i.depth = j;
  END LOOP;

  RAISE NOTICE 'Duration of "set decendantsHaveSameRoute": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  -- set is_mci
  UPDATE subtree i
  SET is_mci = 
    i.decendantsHaveSameRoute = true AND 
    (i.containedIn_id IS NULL OR p.decendantsHaveSameRoute = false) AND 
    i.containesProducts = true
  FROM subtree p
  WHERE i.containedIn_id = p.id;

  RAISE NOTICE 'Duration of "set is_mci": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  -- set mci_id
  FOR j IN 0..max_depth LOOP
    UPDATE subtree i
    SET mci_id = CASE WHEN i.is_mci THEN i.id ELSE p.mci_id END
    FROM 
      subtree p
    WHERE i.depth = j AND i.containedIn_id = p.id;
  END LOOP;

  RAISE NOTICE 'Duration of "set mci_id": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  RETURN QUERY
    SELECT
      s.id,
      s.is_mci,
      s.mci_id
    FROM
      subtree s;

  RAISE NOTICE 'Duration of "return query": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  DROP TABLE subtree;

  RAISE NOTICE 'Duration of "drop table": %', clock_timestamp() - start_time;
  
END;
$$ LANGUAGE plpgsql;

SELECT
  *
FROM
  get_mci_info_tree (1000001);