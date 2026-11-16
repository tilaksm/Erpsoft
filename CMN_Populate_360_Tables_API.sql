--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Populate Data into cmn_account_360 and cmn_contact_360 tables.
--- -     Written by    : Shriniwas Tilak
-----     Date Written  : 14th November 2026
-----     Modified V1   : 
-----     V1 Modified on: 
---------------------------------------------------------------------------------------------------------------------------------
----      This API Populates the Data of Plans, Calls, Leads, Offers, Orders, Invoices, D/N, C/N, Money Receipts,
----      Debtors, PR, PO, GRR, Supplier Bills, Payments and Creditors. 
----      Since Online data display through Query takes a very long time as the data is collected
----      from multiple tables, this API vill populate data into two tables namely cmn_Account_360 and cmn_contact_360.
----      This API will be autoscheduled everry 4 hours to populate the data.
----      Dashboard reports will be generate based on the Views of these two tables.
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE    CMN_POPULATE_360_TABLES_API 
        (   p_return_code                   OUT  VARCHAR2,
            p_return_message                OUT  VARCHAR2,
            P_client_id                      IN  NUMBER,
            p_user_id                        IN  NUMBER
        )
        AS

----    Declare Variables and Cursors required for generation
        err_message                               varchar2(200) := null;
        exists_flag                               varchar2(01)  := null;
        dummy_flag                                varchar2(01)  := null;
        recs_added                                number        := 0;
        v_total_parties                           number        := null;
        v_parties_Created                         number        := null;
        v_parties_visited                         number        := null;
        v_plan_value                              number        := null;
        v_calls_planned                           number        := null;
        v_calls_made                              number        := null;
        v_open_leads                              number        := null;
        v_closed_leads                            number        := null;
        v_cancelled_leads                         number        := null;
        v_qualified_leads                         number        := null;
        v_customer_budget                         number        := null;
        v_open_offers                             number        := null;
        v_open_offers_value                       number        := null;
        v_won_offers                              number        := null;
        v_won_offers_value                        number        := null;
        v_cancel_close_offers                     number        := null;
        v_cancel_close_offers_value               number        := null;
        v_lost_offers                             number        := null;
        v_lost_offers_value                       number        := null;
        v_leads_to_offers                         number        := null;
        v_orders                                  number        := null;
        v_orders_value                            number        := null;
        v_offers_to_orders                        number        := null;
        v_invoices                                number        := null;
        v_invoices_value                          number        := null;
        v_receipts                                number        := null;
        v_receipts_value                          number        := null;
        v_debtors                                 number        := null;
        v_debtors_value                           number        := null;
        v_credit_notes                            number        := null;
        v_credit_notes_value                      number        := null;
        v_debit_notes                             number        := null;
        v_debit_notes_value                       number        := null;
        v_prs                                     number        := null;
        v_prs_value                               number        := null;
        v_pos                                     number        := null;
        v_pos_value                               number        := null;
        v_grrs                                    number        := null;
        v_grrs_value                              number        := null;
        v_bills                                   number        := null;
        v_bills_value                             number        := null;
        v_payments                                number        := null;
        v_payments_value                          number        := null;
        v_creditors                               number        := null;
        v_creditors_value                         number        := null;

----    Declare Cursor for Updating
        CURSOR  get_account_360
        IS
                SELECT  distinct
                        client_id,
                        party_id,
                        party_combination_id,
                        organization_id,
                        lob_id,
                        profit_centre_id,
                        fiscal_year,
                        period_id
                FROM    cmn_account_360
                WHERE   1               = 1
                AND     client_id       = p_client_id;
          
----    Declare and Define a Mandatory Parameters to define Virtual Record for a Call
        v_client_id                               varchar2(10)  := p_client_id;
        v_user_id                                 number        := nvl(p_user_id,1);

BEGIN
----    Populate table with initial values 
----    Populate only missing account_360 rows in a single set-based insert.
        INSERT INTO cmn_account_360
            (   creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                status_id,
                status_date,
                transaction_related_details,
                transaction_related_document,
                directory_name,
                file_name,
                mime_type,
                char_set,
                file_comments,
                place_lattitude,
                place_longitude,
                place_ip_address,
                transaction_application_id,
                transaction_type_id,
                transaction_process_id,
                transaction_level_id,
                client_id,
                party_id,
                party_combination_id,
                organization_id,
                lob_id,
                profit_centre_id,
                fiscal_year,
                period_id,
                total_parties,
                plan_value,
                calls_made,
                open_leads,
                closed_leads,
                cancelled_leads,
                qualified_leads,
                customer_budget,
                open_offers,
                open_offers_value,
                won_offers,
                won_offers_value,
                cancel_close_offers,
                cancel_close_offers_value,
                lost_offers,
                lost_offers_value,
                orders,
                orders_value,
                invoices,
                invoices_value,
                receipts,
                receipts_value,
                debtors,
                debtors_value,
                credit_notes,
                credit_notes_value,
                debit_notes,
                debit_notes_value,
                prs,
                prs_value,
                pos,
                pos_value,
                grrs,
                grrs_value,
                bills,
                bills_value,
                payments,
                payments_value,
                creditors,
                creditors_value
            )
        SELECT  sysdate,
                0,
                sysdate,
                0,
                10012,
                sysdate,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                '18.49926036387643',
                '73.80946714514282',
                '58.84.61.64',
                201,
                20114,
                10031,
                1,
                pcv.client_id,
                pcv.party_id,
                pcv.party_combination_id,
                pcmv.organization_id,
                pcmv.lob_id,
                pcmv.profit_centre_id,
                op.fiscal_year,
                op.period_id,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                null
        FROM    cmn_party_combinations_v        pcv
        JOIN    cmn_profit_centre_master_v      pcmv
        ON      pcmv.client_id                = pcv.client_id
        JOIN    cmn_operating_periods           op
        ON      op.client_id                  = pcmv.client_id
        WHERE   pcv.client_id                 = p_client_id
        AND     pcv.end_date                 IS NULL
        AND     UPPER(pcv.party_type_code)   IN ('PROSPECT','CUSTOMER')
        AND     pcmv.end_date                IS NULL
        AND     op.end_date                  IS NULL
        AND     op.period_start_date          > SYSDATE - 720
        AND     op.period_end_date           <= SYSDATE + 1095
        AND     NOT EXISTS
                (   SELECT  1
                    FROM    cmn_account_360           a
                    WHERE   a.client_id             = pcv.client_id
                    AND     a.party_id              = pcv.party_id
                    AND     a.party_combination_id  = pcv.party_combination_id
                    AND     a.organization_id       = pcmv.organization_id
                    AND     a.lob_id                = pcmv.lob_id
                    AND     a.profit_centre_id      = pcmv.profit_centre_id
                    AND     a.fiscal_year           = op.fiscal_year
                    AND     a.period_id             = op.period_id 
                );
        commit;
        recs_added := SQL%ROWCOUNT;

----    Now Populate All Individual Fields
        BEGIN
----    Calculate and update all account metrics in a single pass.
              MERGE   INTO      cmn_account_360 ca3
              USING   ( WITH    account_dimensions 
                                AS  ( SELECT  DISTINCT
                                              pcv.client_id                     client_id,
                                              pcv.party_id                      party_id,
                                              pcv.party_combination_id          party_combination_id,
                                              pcmv.organization_id              organization_id,
                                              pcmv.lob_id                       lob_id,
                                              pcmv.profit_centre_id             profit_centre_id,
                                              op.fiscal_year                    fiscal_year,
                                              op.period_id                      period_id
                                      FROM    cmn_party_combinations_v          pcv
                                      JOIN    cmn_profit_centre_master          pcmv
                                      ON      pcmv.client_id                  = pcv.client_id
                                      JOIN    cmn_operating_periods             op
                                      ON      op.client_id                    = pcmv.client_id
                                      WHERE   pcv.client_id                   = p_client_id
                                      AND     pcv.end_date                   IS NULL
                                      AND     UPPER(pcv.party_type_code)     IN ('PROSPECT','CUSTOMER')
                                      AND     pcmv.end_date                  IS NULL
                                      AND     op.end_date                    IS NULL
                                      AND     op.period_start_date            > SYSDATE - 720
                                      AND     op.period_end_date             <= SYSDATE + 1095
                                    ),

                                party_counts 
                                AS  ( SELECT  client_id                         client_id,
                                              party_id                          party_id,
                                              party_combination_id              party_combination_id,
                                              COUNT(*)                          total_parties
                                      FROM    cmn_party_combinations
                                      WHERE   client_id                       = p_client_id
                                      GROUP   BY client_id, 
                                                  party_id, 
                                                  party_combination_id
                                    ),

                                party_created 
                                AS  ( SELECT  client_id                         client_id,
                                              party_id                          party_id,
                                              party_combination_id              party_combination_id,
                                              TO_CHAR(creation_date, 'YYYYMM')  period_id,
                                              COUNT(*)                          parties_created
                                      FROM    cmn_party_combinations
                                      WHERE   client_id                       = p_client_id
                                      GROUP   BY client_id, 
                                              party_id, 
                                              party_combination_id, 
                                              TO_CHAR(creation_date, 'YYYYMM')
                                    ),

                                calls_stats 
                                AS  ( SELECT  c.client_id                       client_id,
                                              c.plan_party_id                   party_id,
                                              nvl     ( d.customer_combination_id,
                                                        d.prospect_combination_id
                                                      )                         party_combination_id, 
                                              TO_CHAR (c.plan_date, 'YYYYMM')   period_id,
                                              COUNT   (*)                       calls_planned,
                                              SUM     ( CASE 
                                                        WHEN TO_CHAR(c.visit_date,'YYYYMM') = TO_CHAR(c.plan_date, 'YYYYMM') 
                                                        THEN 1 
                                                        ELSE 0 
                                                        END
                                                      )                         calls_made,
                                              COUNT   ( DISTINCT 
                                                        CASE 
                                                        WHEN c.met_party_id = c.plan_party_id 
                                                        THEN c.met_party_id 
                                                        END
                                                      )                         parties_visited
                                      FROM    crm_calls           c,
                                              cmn_party_master    d
                                      WHERE   1                 = 1
                                      AND     c.plan_party_id   = d.party_id
                                      AND     c.client_id       = d.client_id
                                      AND     c.client_id       = p_client_id
                                      GROUP   BY  c.client_id, 
                                                  c.plan_party_id, 
                                                  nvl ( d.customer_combination_id,
                                                        d.prospect_combination_id
                                                      ),
                                                  TO_CHAR(c.plan_date, 'YYYYMM')
                                    ),

                                plan_stats 
                                AS  ( SELECT  pd.client_id                            client_id,
                                              pd.customer_party_id                    party_id,
                                              nvl     ( cp.customer_combination_id,
                                                        cp.prospect_combination_id
                                                      )                               party_combination_id, 
                                              TO_CHAR(op.period_start_date, 'YYYYMM') period_id,
                                              SUM(NVL(pd.plan_value, 0))              plan_value
                                      FROM    epb_plan_details                        pd
                                      JOIN    cmn_operating_periods                   op
                                      ON      op.client_id                          = pd.client_id
                                      JOIN    cmn_party_master                        cp
                                      ON      cp.party_id                           = pd.party_id
                                      AND     cp.client_id                          = pd.client_id
                                      AND     op.end_date                          IS NULL
                                      AND     op.period_start_date                 <= pd.planned_end_date
                                      AND     op.period_end_date                   >= pd.planned_start_date
                                      WHERE   pd.client_id                          = p_client_id
                                      GROUP   BY  pd.client_id, 
                                                  pd.customer_party_id, 
                                                  nvl ( cp.customer_combination_id,
                                                        cp.prospect_combination_id
                                                      ),             
                                                  TO_CHAR(op.period_start_date, 'YYYYMM')
                                    ),
                              lead_stats 
                              AS    ( SELECT  cl.client_id                            client_id,
                                              cl.lead_by_party_id                     party_id,
                                              cl.lead_by_party_combination_id         party_combination_id,
                                              TO_CHAR(cl.received_date, 'YYYYMM')     period_id,
                                              SUM ( CASE 
                                                    WHEN  cl.status_id             IN (10002,10012) 
                                                    THEN  1 
                                                    ELSE  0 
                                                    END
                                                  )                                   open_leads,
                                              SUM ( CASE 
                                                    WHEN  cl.status_id             IN (10016,100003) 
                                                    THEN  1 
                                                    ELSE  0 
                                                    END
                                                  )                                   qualified_leads,
                                              SUM ( CASE 
                                                    WHEN  cl.status_id              = 10007 
                                                    THEN  1 
                                                    ELSE  0 
                                                    END
                                                  )                                   closed_leads,
                                              SUM ( CASE 
                                                    WHEN  cl.status_id              = 10006 
                                                    THEN  1 
                                                    ELSE  0 
                                                    END
                                                  )                                   cancelled_leads,
                                              SUM ( NVL(cl.customer_budget_amount, 0)) customer_budget
                                      FROM    crm_customer_leads                      cl
                                      WHERE   cl.client_id                          = p_client_id
                                      GROUP   BY  cl.client_id, 
                                                  cl.lead_by_party_id, 
                                                  cl.lead_by_party_combination_id, 
                                                  TO_CHAR(cl.received_date, 'YYYYMM')
                                    ),
                              offer_stats 
                              AS    ( SELECT  co.client_id                            client_id,
                                              co.customer_party_id                    party_id,
                                              co.customer_party_combination_id        party_combination_id,
                                              TO_CHAR(co.received_date, 'YYYYMM')     period_id,
                                              SUM ( CASE 
                                                    WHEN  co.status_id             IN (0,10002,10012,10021) 
                                                    THEN  1 
                                                    ELSE  0 
                                                    END
                                                  )                                   open_offers,
                                              SUM ( CASE 
                                                    WHEN  co.status_id             IN (0,10002,10012,10021) 
                                                    THEN  NVL(co.line_taxable_amount, 0) 
                                                    ELSE  0 
                                                    END
                                                  )                                   open_offers_value,
                                              SUM ( CASE 
                                                    WHEN  co.status_id             IN (10026,10017,10030) 
                                                    THEN  1 
                                                    ELSE  0 
                                                    END
                                                  )                                   won_offers,
                                              SUM ( CASE 
                                                    WHEN  co.status_id             IN (10026,10017,10030) 
                                                    THEN  NVL(co.line_taxable_amount, 0) 
                                                    ELSE  0 
                                                    END
                                                  )                                   won_offers_value,
                                              SUM ( CASE 
                                                    WHEN  co.status_id             IN (10007,10006) 
                                                    THEN  1 
                                                    ELSE  0 
                                                    END
                                                  )                                   cancel_close_offers,
                                              SUM ( CASE 
                                                    WHEN  co.status_id             IN (10007,10006) 
                                                    THEN  NVL(co.line_taxable_amount, 0) 
                                                    ELSE  0 
                                                    END
                                                  )                                   cancel_close_offers_value,
                                                  SUM ( CASE 
                                                        WHEN  co.status_id          = 10027 
                                                        THEN  1 
                                                        ELSE  0 
                                                        END
                                                      )                               lost_offers,
                                                  SUM ( CASE 
                                                        WHEN  co.status_id          = 10027 
                                                        THEN  NVL(co.line_taxable_amount, 0) 
                                                        ELSE  0 
                                                        END
                                                      )                               lost_offers_value
                                      FROM    crm_customer_offers                     co
                                      WHERE   co.client_id                          = p_client_id
                                      GROUP   BY  co.client_id, 
                                                  co.customer_party_id, 
                                                  co.customer_party_combination_id, 
                                                  TO_CHAR(co.received_date, 'YYYYMM')
                                    ),
                              order_stats 
                              AS    ( SELECT  oh.client_id                            client_id,
                                              oh.customer_party_id                    party_id,
                                              nvl ( cp.customer_combination_id,
                                                    cp.prospect_combination_id
                                                  )                                   party_combination_id,
                                              TO_CHAR (oh.received_date, 'YYYYMM')    period_id,
                                              COUNT   (*)                             orders,
                                              SUM     (NVL(oh.line_taxable_amount, 0)) orders_value
                                      FROM    om_order_headers                        oh,
                                              cmn_party_master                        cp
                                      WHERE   1                                     = 1
                                      AND     oh.customer_party_id                  = cp.party_id
                                      AND     oh.client_id                          = cp.client_id
                                      AND     cp.client_id                          = p_client_id
                                      GROUP   BY  oh.client_id, 
                                                  oh.customer_party_id, 
                                                  TO_CHAR(oh.received_date, 'YYYYMM')
                                    ),
                              invoice_stats 
                              AS    ( SELECT  ar.client_id                            client_id,
                                              ar.party_id                             party_id,
                                              ar.party_combination_id                 party_combination_id,
                                              ar.period_id                            period_id,
                                              COUNT (*)                               invoices,
                                              SUM   (NVL(ar.ar_trx_net_amount, 0))    invoices_value
                                      FROM    fins_ar_transactions ar
                                      WHERE   ar.client_id                          = p_client_id
                                      AND     ar.ar_trx_code                        = 'INVOICE'
                                      GROUP   BY  ar.client_id, 
                                                  ar.party_id, 
                                                  ar.party_combination_id, 
                                                  ar.period_id
                                    ),
                              receipt_stats 
                              AS    ( SELECT  r.client_id                             client_id,
                                              r.party_id                              party_id,
                                              r.party_combination_id                  party_combination_id,
                                              r.period_id                             period_id,
                                              COUNT (*)                               receipts,
                                              SUM   (NVL(r.receipt_amount, 0))        receipts_value
                                      FROM    fins_ar_money_receipts                  r
                                      WHERE   r.client_id                           = p_client_id
                                      GROUP   BY  r.client_id,
                                                  r.party_id,
                                                  r.party_combination_id, 
                                                  r.period_id
                                    ),
                              debtor_stats 
                              AS    ( SELECT  d.client_id                             client_id,
                                              d.party_id                              party_id,
                                              d.party_combination_id                  party_combination_id,
                                              d.period_id                             period_id,
                                              COUNT (*)                               debtors,
                                              SUM   (NVL(d.net_amount, 0))            debtors_value
                                      FROM    fins_debtors_ageing_v                   d
                                      WHERE   d.client_id                           = p_client_id
                                      GROUP   BY  d.client_id, 
                                                  d.party_id, 
                                                  d.party_combination_id, 
                                                  d.period_id
                                    ),
                              credit_note_stats 
                              AS    ( SELECT  ar.client_id                            client_id,
                                              ar.party_id                             party_id,
                                              ar.party_combination_id                 party_combination_id,
                                              ar.period_id                            period_id,
                                              COUNT (*)                               invoices,
                                              SUM   (NVL(ar.ar_trx_net_amount, 0))    invoices_value
                                      FROM    fins_ar_transactions ar
                                      WHERE   ar.client_id                          = p_client_id
                                      AND     ar.ar_trx_code                       IN ('CRN','CN')
                                      GROUP   BY  ar.client_id, 
                                                  ar.party_id, 
                                                  ar.party_combination_id, 
                                                  ar.period_id
                                    ),
                              debit_note_stats 
                              AS    ( SELECT  ar.client_id                            client_id,
                                              ar.party_id                             party_id,
                                              ar.party_combination_id                 party_combination_id,
                                              ar.period_id                            period_id,
                                              COUNT (*)                               invoices,
                                              SUM   (NVL(ar.ar_trx_net_amount, 0))    invoices_value
                                      FROM    fins_ar_transactions ar
                                      WHERE   ar.client_id                          = p_client_id
                                      AND     ar.ar_trx_code                       IN ('DRN','DN')
                                      GROUP   BY  ar.client_id, 
                                                  ar.party_id, 
                                                  ar.party_combination_id, 
                                                  ar.period_id
                                    )
                          SELECT    d.client_id                                       client_id,
                                    d.party_id                                        party_id,
                                    d.party_combination_id                            party_combination_id,
                                    d.organization_id                                 organization_id,
                                    d.lob_id                                          lob_id,
                                    d.profit_centre_id                                profit_centre_id,
                                    d.fiscal_year                                     fiscal_year,
                                    d.period_id                                       period_id,
                                    NVL(pc.total_parties, 0)                          total_parties,
                                    NVL(pc2.parties_created, 0)                       parties_created,
                                    NVL(cs.calls_planned, 0)                          calls_planned,
                                    NVL(cs.calls_made, 0)                             calls_made,
                                    NVL(cs.parties_visited, 0)                        parties_visited,
                                    NVL(ps.plan_value, 0)                             plan_value,
                                    NVL(ls.open_leads, 0)                             open_leads,
                                    NVL(ls.closed_leads, 0)                           closed_leads,
                                    NVL(ls.cancelled_leads, 0)                        cancelled_leads,
                                    NVL(ls.qualified_leads, 0)                        qualified_leads,
                                    NVL(ls.customer_budget, 0)                        customer_budget,
                                    NVL(os.open_offers, 0)                            open_offers,
                                    NVL(os.open_offers_value, 0)                      open_offers_value,
                                    NVL(os.won_offers, 0)                             won_offers,
                                    NVL(os.won_offers_value, 0)                       won_offers_value,
                                    NVL(os.cancel_close_offers, 0)                    cancel_close_offers,
                                    NVL(os.cancel_close_offers_value, 0)              cancel_close_offers_value,
                                    NVL(os.lost_offers, 0)                            lost_offers,
                                    NVL(os.lost_offers_value, 0)                      lost_offers_value,
                                    0                                                 leads_to_offers,
                                    NVL(ors.orders, 0)                                orders,
                                    NVL(ors.orders_value, 0)                          orders_value,
                                    0                                                 offers_to_orders,
                                    NVL(isv.invoices, 0)                              invoices,
                                    NVL(isv.invoices_value, 0)                        invoices_value,
                                    NVL(rs.receipts, 0)                               receipts,
                                    NVL(rs.receipts_value, 0)                         receipts_value,
                                    NVL(ds.debtors, 0)                                debtors,
                                    NVL(ds.debtors_value, 0)                          debtors_value,
                                    NVL(cns.credit_notes, 0)                          credit_notes,
                                    NVL(cns.credit_notes_value, 0)                    credit_notes_value,
                                    NVL(dns.debit_notes, 0)                           debit_notes,
                                    NVL(dns.debit_notes_value, 0)                     debit_notes_value,
                                    0                                                 prs,
                                    0                                                 prs_value,
                                    0                                                 pos,
                                    0                                                 pos_value,
                                    0                                                 grrs,
                                    0                                                 grrs_value,
                                    0                                                 bills,
                                    0                                                 bills_value,
                                    0                                                 payments,
                                    0                                                 payments_value,
                                    0                                                 creditors,
                                    0                                                 creditors_value
                          FROM      account_dimensions                                d
                          LEFT JOIN party_counts                                      pc
                          ON        pc.client_id                                    = d.client_id
                          AND       pc.party_id                                     = d.party_id
                          AND       pc.party_combination_id                         = d.party_combination_id
                          LEFT JOIN party_created                                     pc2
                          ON        pc2.client_id                                   = d.client_id
                          AND       pc2.party_id                                    = d.party_id
                          AND       pc2.party_combination_id                        = d.party_combination_id
                          AND       pc2.period_id                                   = d.period_id
                          LEFT JOIN calls_stats                                       cs
                          ON        cs.client_id                                    = d.client_id
                          AND       cs.party_id                                     = d.party_id
                          AND       cs.party_combination_id                         = d.party_combination_id
                          AND       cs.period_id                                    = d.period_id
                          LEFT JOIN plan_stats                                        ps
                          ON        ps.client_id                                    = d.client_id
                          AND       ps.party_id                                     = d.party_id
                          AND       ps.party_combination_id                         = d.party_combination_id
                          AND       ps.period_id                                    = d.period_id
                          LEFT JOIN lead_stats                                        ls
                          ON        ls.client_id                                    = d.client_id
                          AND       ls.party_id                                     = d.party_id
                          AND       ls.party_combination_id                         = d.party_combination_id
                          AND       ls.period_id                                    = d.period_id
                          LEFT JOIN offer_stats                                       os
                          ON        os.client_id                                    = d.client_id
                          AND       os.party_id                                     = d.party_id
                          AND       os.party_combination_id                         = d.party_combination_id
                          AND       os.period_id                                    = d.period_id
                          LEFT JOIN order_stats                                       ors
                          ON        ors.client_id                                   = d.client_id
                          AND       ors.party_combination_id                        = d.party_combination_id                          
                          AND       ors.party_id                                    = d.party_id
                          AND       ors.period_id                                   = d.period_id
                          LEFT JOIN invoice_stats                                     isv
                          ON        isv.client_id                                   = d.client_id
                          AND       isv.party_id                                    = d.party_id
                          AND       isv.party_combination_id                        = d.party_combination_id
                          AND       isv.period_id                                   = d.period_id
                          LEFT JOIN receipt_stats                                     rs
                          ON        rs.client_id                                    = d.client_id
                          AND       rs.party_id                                     = d.party_id
                          AND       rs.party_combination_id                         = d.party_combination_id
                          AND       rs.period_id                                    = d.period_id
                          LEFT JOIN debtor_stats                                      ds
                          ON        ds.client_id                                    = d.client_id
                          AND       ds.party_id                                     = d.party_id
                          AND       ds.party_combination_id                         = d.party_combination_id
                          AND       ds.period_id                                    = d.period_id
                          LEFT JOIN credit_note_stats                                 cns
                          ON        cns.client_id                                   = d.client_id
                          AND       cns.party_id                                    = d.party_id
                          AND       cns.party_combination_id                        = d.party_combination_id
                          AND       cns.period_id                                   = d.period_id
                          LEFT JOIN debit_note_stats                                dns
                          ON        dns.client_id                                 = d.client_id
                          AND       dns.party_id                                  = d.party_id
                          AND       dns.party_combination_id                      = d.party_combination_id
                          AND       dns.period_id                                 = d.period_id
                      )   src
              ON  ( ca3.client_id                                                 = src.client_id
              AND   ca3.party_id                                                  = src.party_id
              AND   ca3.party_combination_id                                      = src.party_combination_id
              AND   ca3.organization_id                                           = src.organization_id
              AND   ca3.lob_id                                                    = src.lob_id
              AND   ca3.profit_centre_id                                          = src.profit_centre_id
              AND   ca3.fiscal_year                                               = src.fiscal_year
              AND   ca3.period_id                                                 = src.period_id 
              )
              WHEN  MATCHED 
              THEN  UPDATE 
                    SET     total_parties                                         = NVL(src.total_parties, 0),
                            parties_created                                       = NVL(src.parties_created, 0),
                            parties_visited                                       = NVL(src.parties_visited, 0),
                            plan_value                                            = NVL(src.plan_value, 0),
                            calls_planned                                         = NVL(src.calls_planned, 0),
                            calls_made                                            = NVL(src.calls_made, 0),
                            open_leads                                            = NVL(src.open_leads, 0),
                            closed_leads                                          = NVL(src.closed_leads, 0),
                            cancelled_leads                                       = NVL(src.cancelled_leads, 0),
                            qualified_leads                                       = NVL(src.qualified_leads, 0),
                            customer_budget                                       = NVL(src.customer_budget, 0),
                            open_offers                                           = NVL(src.open_offers, 0),
                            open_offers_value                                     = NVL(src.open_offers_value, 0),
                            won_offers                                            = NVL(src.won_offers, 0),
                            won_offers_value                                      = NVL(src.won_offers_value, 0),
                            cancel_close_offers                                   = NVL(src.cancel_close_offers, 0),
                            cancel_close_offers_value                             = NVL(src.cancel_close_offers_value, 0),
                            lost_offers                                           = NVL(src.lost_offers, 0),
                            lost_offers_value                                     = NVL(src.lost_offers_value, 0),
                            leads_to_offers                                       = NVL(src.leads_to_offers, 0),
                            orders                                                = NVL(src.orders, 0),
                            orders_value                                          = NVL(src.orders_value, 0),
                            offers_to_orders                                      = NVL(src.offers_to_orders, 0),
                            invoices                                              = NVL(src.invoices, 0),
                            invoices_value                                        = NVL(src.invoices_value, 0),
                            receipts                                              = NVL(src.receipts, 0),
                            receipts_value                                        = NVL(src.receipts_value, 0),
                            debtors                                               = NVL(src.debtors, 0),
                            debtors_value                                         = NVL(src.debtors_value, 0),
                            credit_notes                                          = NVL(src.credit_notes, 0),
                            credit_notes_value                                    = NVL(src.credit_notes_value, 0),
                            debit_notes                                           = NVL(src.debit_notes, 0),
                            debit_notes_value                                     = NVL(src.debit_notes_value, 0),
                            prs                                                   = NVL(src.prs, 0),
                            prs_value                                             = NVL(src.prs_value, 0),
                            pos                                                   = NVL(src.pos, 0),
                            pos_value                                             = NVL(src.pos_value, 0),
                            grrs                                                  = NVL(src.grrs, 0),
                            grrs_value                                            = NVL(src.grrs_value, 0),
                            bills                                                 = NVL(src.bills, 0),
                            bills_value                                           = NVL(src.bills_value, 0),
                            payments                                              = NVL(src.payments, 0),
                            payments_value                                        = NVL(src.payments_value, 0),
                            creditors                                             = NVL(src.creditors, 0),
                            creditors_value                                       = NVL(src.creditors_value, 0),
                            last_update_date                                      = SYSDATE,
                            last_updated_by                                       = v_user_id;
                  commit;
        EXCEPTION
        WHEN      OTHERS
        THEN      p_return_code   :=  2;
                  p_return_message   :=  'Error in Processing Data in cmn_account_360 ' ;
                  Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Error in Processing Data in cmn_account_360 ');
                  DBMS_OUTPUT.put_line ('Error in Processing Data in cmn_account_360 ');
                  RETURN;
        END;

        p_return_code    := 0;
        p_return_message := 'Populating Data in cmn_account_360 Completed';
        DBMS_OUTPUT.put_line ('Populating Data in cmn_account_360 Completed');
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Populating Data in cmn_account_360 Completed');
        commit;
        RETURN;
EXCEPTION
WHEN        OTHERS
THEN        DBMS_OUTPUT.put_line (p_return_message || ' - ' || SQLERRM);
            Apex_Util.Set_Session_State('RETURN_MESSAGE' ,p_return_message || ' - ' || SQLERRM);
            APEX_ERROR.add_error ( p_error_code        => p_return_message || ' - ' || SQLERRM,
                                   p0                  => null,
                                   p_display_location  => apex_error.c_inline_with_field_and_notif,
                                   p_page_item_name    => null 
                                 );
            p_return_code    :=  2;
            p_return_message :=  p_return_message ||  ' - ' || SQLERRM;
            RETURN;
END     CMN_POPULATE_360_TABLES_API;
----------------------------------------------------------------------------------------------------------------------------  
