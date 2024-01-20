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
      id = 0
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