DROP FUNCTION IF EXISTS get_subtree (bigint[]);

CREATE
OR REPLACE FUNCTION get_subtree (root_ids bigint[]) RETURNS TABLE (
  id bigint,
  containedIn_id bigint,
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
      i.id = ANY(root_ids)
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

DROP FUNCTION IF EXISTS get_mci_info_tree (bigint[]);

CREATE
OR REPLACE FUNCTION get_mci_info_tree (root_ids bigint[]) RETURNS TABLE (
  id bigint,
  is_mci boolean,
  containedIn_id bigint,
  depth integer,
  sameRouteAsParent boolean,
  decendantsHaveSameRoute boolean,
  isProduct boolean,
  containesProducts boolean
) AS $$
DECLARE
  max_depth integer;
  start_time TIMESTAMP;
BEGIN
  start_time := clock_timestamp();

  -- get tree
  CREATE TEMP TABLE subtree AS
    SELECT 
      *, 
      TRUE AS decendantsHaveSameRoute,
      true AS containesProducts,
      CAST(NULL AS bigint) AS mci_id
    FROM get_subtree(root_ids) i;
  
  RAISE NOTICE 'Duration of "get tree": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  -- create indexes
  --CREATE INDEX ON subtree (id);
  CREATE INDEX ON subtree (containedIn_id) INCLUDE (depth);
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
      decendantsHaveSameRoute = false
    FROM 
      subtree child
    WHERE
      i.depth = j 
      AND child.containedIn_id = i.id 
      AND (child.decendantsHaveSameRoute = false
        OR child.samerouteasparent = false);
  END LOOP;

  RAISE NOTICE 'Duration of "set decendantsHaveSameRoute": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  -- set containesProducts
  FOR j IN REVERSE max_depth..0 LOOP
    UPDATE subtree i
    SET
      containesProducts = EXISTS ( -- TODO: replace with JOIN if possible
        SELECT
          1
        FROM
          subtree child
        WHERE
          child.containedIn_id = i.id
          AND child.containesProducts = true
      )
    WHERE
      i.depth = j AND
      i.isProduct = false;
  END LOOP;


  RAISE NOTICE 'Duration of "set containesProducts": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  RETURN QUERY
    SELECT
      i.id,
      (p.decendantsHaveSameRoute = false 
        AND i.decendantsHaveSameRoute = true 
        AND i.containesProducts = true) OR (i.containedIn_id is NULL AND i.decendantsHaveSameRoute = true) as is_mci,
      i.containedIn_id,
      i.depth,
      i.sameRouteAsParent,
      i.decendantsHaveSameRoute,
      i.isProduct,
      i.containesProducts
    FROM
      subtree i
    LEFT JOIN subtree p ON i.containedIn_id = p.id;


  RAISE NOTICE 'Duration of "return query": %', clock_timestamp() - start_time;
  start_time := clock_timestamp();

  DROP TABLE subtree;

  RAISE NOTICE 'Duration of "drop table": %', clock_timestamp() - start_time;
  
END;
$$ LANGUAGE plpgsql;