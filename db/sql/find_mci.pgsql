DROP FUNCTION IF EXISTS get_subtree (integer);

CREATE
OR REPLACE FUNCTION get_subtree (root_id integer) RETURNS TABLE (
  id integer,
  containedIn_id integer,
  depth integer,
  fromLocation_id integer,
  toLocation_id integer,
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
  *
FROM
  subtree_cte;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS get_inseparability (integer);

CREATE
OR REPLACE FUNCTION get_inseparability (root_id integer) RETURNS TABLE (
  id integer,
  containedIn_id integer,
  depth integer,
  fromLocation_id integer,
  toLocation_id integer,
  sameRouteAsParent boolean,
  decendantsHaveSameRoute boolean
) AS $$
DECLARE
  max_depth integer;
BEGIN
  -- get tree
  CREATE TEMP TABLE subtree AS
    SELECT 
      *, 
      TRUE AS decendantsHaveSameRoute 
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

  RETURN QUERY
    SELECT
      *
    FROM
      subtree;
  
END;
$$ LANGUAGE plpgsql;

SELECT
  *
FROM
  get_inseparability (0);