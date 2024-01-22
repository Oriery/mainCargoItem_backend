CREATE INDEX
    ON public.oriery_mci_item USING btree
    (containedin_id ASC NULLS LAST)
    WITH (deduplicate_items=True)
;

