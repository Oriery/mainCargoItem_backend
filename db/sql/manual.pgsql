SELECT
  *
FROM
  get_mci_info_tree (
    Array (
      SELECT
        item_id
      FROM
        oriery_mci_transport2rootitem
      WHERE
        transport_id = 0
    )
  )