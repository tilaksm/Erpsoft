BEGIN
---     Call imt updating Procedure for All clients
        for     get_client  in
                (   select  client_id
                    from    cmn_client_master
                )
        loop
----            update imt for dr and cr accounts based on inv_transaction_type_id
                BEGIN
                      update  inv_material_transactions imt
                      set     (dr_account_id, cr_account_ID) =
                              ( select  dr_account_id,
                                        cr_account_id   
                                from    inv_transaction_types itt
                                where   1                   = 1
                                and     itt.inv_transaction_type_id = imt.inv_transaction_type_id
                                and     itt.client_id       = imt.client_id
                              )
                      where   1                             = 1
                      and     ( dr_account_id              is null
                      or        cr_account_id              is null
                              )
                      and     exists
                              ( select 'c'
                                from    inv_transaction_types itt
                                where   1                   = 1
                                and     itt.inv_transaction_type_id = imt.inv_transaction_type_id
                                and     itt.client_id       = imt.client_id
                              )
                      and     client_id                     = get_client.client_id;
                      commit;
                END;

----            update imt for accounting_period_id based on transaction_date
                BEGIN
                      update  inv_material_transactions imt
                      set     accounting_period_id = 
                              ( select  period_id
                                from    cmn_operating_periods     cop
                                where   1                   =     1
                                and     trunc(imt.transaction_date) 
                                between cop.period_start_date 
                                and     cop.period_end_date
                                and     cop.client_id=imt.client_id 
                              )
                      where   1         =   1
                      and     exists
                              ( select  'c'
                                from    cmn_operating_periods     cop
                                where   1                   =     1
                                and     trunc(imt.transaction_date) 
                                between cop.period_start_date 
                                and     cop.period_end_date
                                and     cop.client_id=imt.client_id 
                              )
                      and     imt.accounting_period_id is null
                      and     imt.client_id     = get_client.client_id;
                      commit;
                END;

                commit;
        end loop;      
        commit;    
END;