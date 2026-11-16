--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Generate Accounting for Receivable Transactions.
----      These include, Invoices, Credit Notes, Debit Notes.
--- -     Written by    : Shriniwas Tilak.
-----     Date Written  : 03rd April 2024
-----     Modified V1   : 
-----     V1 Modified on: 
---------------------------------------------------------------------------------------------------------------------------------
----      Generate Accounting for Accounts Receivables Transactions.
----      This process runs into three major sub processes.
----      1.  Accounting Event Generation.
----          There will one record per transaction of base and Money Receipt.
----      2.  Subledger Headers Generation.
----          There will be one header per Transaction and Per Money Receipts
----      3.  Subledger Lines Generation.
----          There will be multiple records per base transaction. Atlease 2. One for Dr entry and anoth for Cr Entry.
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE "FINS_RECEIVABLES_TRANSACTION_ACCOUNTING_API" 
              ( p_return_code                 out varchar2,
                p_return_message              out varchar2,
                p_place_lattitude             in  varchar2  default null,
                p_place_longitude             in  varchar2  default null,
                p_place_ip_address            in  varchar2  default null,
                p_transaction_type_id         in  number    default null,
                p_transaction_application_id  in  number    default 304,
                p_transaction_process_id      in  number    default null,
                p_transaction_level_id        in  number    default null,
                p_user_id                     in  varchar2  default 0,
                p_client_id                   in  number,
                p_organization_id             in  number    default null,
                p_lob_id                      in  number    default null,
                p_profit_centre_id            in  number    default null,
                p_ar_trx_id                   in  number    default null
              )
IS
----    Declare Variables and Cursors required for generation
        err_message                         varchar2(200)     :=  null;
        exists_flag                         varchar2(01)      :=  null;
        dummy_flag                          varchar2(01)      :=  null;
        events_created                      number            :=  null;
        headers_created                     number            :=  null;
        lines_created                       number            :=  null;
        v_sla_accounted_status              number            :=  null;
        v_gl_trasnfer_status                number            :=  null;
        v_transaction_type_id               number            :=  null;
        v_sla_event_id                      number            :=  null;
        v_sla_header_id                     number            :=  null;
        v_sla_line_id                       number            :=  null;
        v_jv_header_id                      number            :=  null;
        v_jv_line_id                        number            :=  null;
        v_event_source_id                   number            :=  null;
        v_event_sub_source_id               number            :=  null;
        v_event_category_id                 number            :=  null;
        v_event_sub_category_id             number            :=  null;
        v_ar_application_id                 number            :=  null;
        v_sla_source_id                     number            :=  null;
        v_sla_sub_source_id                 number            :=  null;
        v_sla_category_id                   number            :=  null;
        v_sla_sub_category_id               number            :=  null;
        v_revenue_ccid                      number            :=  null;
        v_debtors_ccid                      number            :=  null;
        v_dr_ccid                           number            :=  null;
        v_cr_ccid                           number            :=  null;
        v_dr_amount                         number            :=  null;
        v_cr_amount                         number            :=  null;
        v_accounted_dr_amount               number            :=  null;
        v_accounted_cr_amount               number            :=  null;
        v_ccid                              number            :=  null;
        d_ap_accrual_account_id             number            :=  null;
        d_vendor_liability_account_id       number            :=  null;
        d_revenue_account_id                number            :=  null;
        d_debtors_account_id                number            :=  null;
        d_credit_limit_days                 number            :=  null;
        d_credit_limit_amount               number            :=  null;
        d_payment_term_id                   number            :=  null;
        v_revenue_account_id                number            :=  null;
        v_debtors_account_id                number            :=  null;
        v_erp_financials_start_date         date              :=  null; 

        Some_Error                          EXCEPTION;

        CURSOR      get_jv_headers
        IS
                    SELECT  /*+ PARALLEL (fins_ar_transactions_v, 4) */
                            null                                                          event_id,
                            10012                                                         status_id,
                            sysdate                                                       status_date,
                            ( select  category_id                       
                              from  cmn_Category_master_v
                              where 1                       = 1
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = fatv.client_id
                            )                                                             jv_source_set_id,
                            ( select  sub_category_id
                              from  cmn_sub_category_master_V
                              where 1                       = 1
                              and   sub_category_code       = 'RECEIVABLES'
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = fatv.client_id
                            )                                                             jv_source_code_id,
                            ( select  category_id
                              from  cmn_category_master_V
                              where 1                       = 1
                              and   category_code           = 'SLA_JOURNAL_CATEGORY_SET'
                              and   client_id               = fatv.client_id
                            )                                                             jv_category_id,
                            case
                            when  (upper(trim(fatv.ar_trx_code)) = 'INVOICE')
                            then  ( select  sub_category_id
                                    from    cmn_sub_category_master_V
                                    where   1                  = 1
                                    and     sub_category_code  = 'SALES INVOICES'
                                    and     category_code      = 'SLA_JOURNAL_CATEGORY_SET'
                                    and     client_id          = fatv.client_id
                                  )
                            when  (upper(trim(fatv.ar_trx_code)) = 'DRN')
                            then  ( select  sub_category_id
                                    from    cmn_sub_category_master_V
                                    where   1                  = 1
                                    and     sub_category_code  = 'DEBIT MEMOS'
                                    and     category_code      = 'SLA_JOURNAL_CATEGORY_SET'
                                    and     client_id          = fatv.client_id
                                  )
                            when  (upper(trim(fatv.ar_trx_code)) = 'CRN')
                            then  ( select  sub_category_id
                                    from    cmn_sub_category_master_V
                                    where   1                  = 1
                                    and     sub_category_code  = 'CREDIT MEMOS'
                                    and     category_code      = 'SLA_JOURNAL_CATEGORY_SET'
                                    and     client_id          = fatv.client_id
                                  )
                            end   as                                                      jv_sub_category_id,
                            'A'                                                           actual_flag,
                            fatv.client_id                                                client_id,
                            fatv.plan_header_id                                           plan_header_id,
                            fatv.plan_detail_id                                           plan_detail_id,
                            fatv.budget_id                                                budget_id,
                            fatv.budget_line_id                                           budget_line_id,
                            fatv.project_id                                               project_id,
                            fatv.project_task_id                                          project_task_id,
                            fatv.profit_centre_id                                         profit_centre_id,
                            fatv.lob_id                                                   lob_id,
                            fatv.organization_id                                          organization_id,
                            fatv.client_id                                                set_of_books_id,
                            ( select  application_id
                              from    cmn_applications_master     cam
                              where   1                         = 1
                              and     trim(upper(cam.application_code)) = 'AR'
                              and     client_id                 = fatv.client_id
                            )                                                             application_id,
                            upper(trim(fatv.ar_trx_code))                                 ar_trx_code,
                            fatv.ar_trx_code||' -'|| fatv.ar_trx_id || ' - '||
                            fatv.ar_trx_number                                            jv_name,
                            fatv.ar_trx_narration                                         description,
                            abs(round(nvl(fatv.ar_trx_total_amount,0),2))                 sla_header_amount,
                            ar_trx_type_id                                                transaction_type_id,
                            ( select  application_id
                              from    cmn_applications_master     cam
                              where   1                         = 1
                              and     trim(upper(cam.application_code)) = 'AR'
                              and     client_id                 = fatv.client_id
                            )                                                             feed_trx_application_id,
                            fatv.ar_trx_type_id                                           feed_trx_document_type_id,
                            fatv.ar_trx_id                                                feed_trx_document_id,
                            fatv.ar_trx_number                                            feed_trx_number,
                            fatv.ar_trx_date                                              feed_trx_date,
                            'FINS_AR_TRANSACTIONS'                                        feed_transaction_table_name,
                            ( select  party_combination_id
                              from    cmn_customer_master_v         ccmv
                              where   1                           = 1
                              and     ccmv.party_id               = fatv.party_id
                              and     ccmv.client_id              = fatv.client_id
                            )                                                             party_combination_id,
                            fatv.party_id                                                 party_id,
                            fatv.ar_trx_date                                              sla_accounting_date,
                            fatv.period_id                                                period_id,
                            fatv.period_name                                              period_name,
                            null                                                          gl_posting_id,
                            null                                                          debtors_posting_id,
                            null                                                          debtors_posted_date,
                            null                                                          creditors_posting_id,
                            null                                                          creditors_posted_date,
                            null                                                          other_sl_posting_id,
                            null                                                          other_sl_posted_date,
                            fatv.ar_trx_date                                              jv_effective_date,
                            null                                                          posted_date,
                            null                                                          posted_flag,
                            null                                                          posting_error,
                            case                      
                            when  (fatv.ar_trx_code in  ('CRN','CN'))
                            then  (-1*round(nvl(fatv.ar_trx_total_amount,0),2))   
                            else  round(nvl(fatv.ar_trx_total_amount,0),2)
                            end   as                                                      running_total_dr,
                            case
                            when  (fatv.ar_trx_code in  ('CRN','CN'))
                            then  (-1*round(nvl(fatv.ar_trx_total_amount,0),2))   
                            else  round(nvl(fatv.ar_trx_total_amount,0),2)
                            end   as                                                      running_total_cr,
                            fatv.ar_trx_id                                                gl_sl_link_id,
                            'FINS_AR_TRANSACTIONS'                                        gl_sl_link_table,
                            null                                                          reference_1,
                            null                                                          reference_2,
                            null                                                          reference_3,
                            null                                                          reference_4,
                            null                                                          reference_5,
                            null                                                          period_begin_balance_dr_before,
                            null                                                          period_begine_balance_cr_before,
                            null                                                          period_net_dr_before,
                            null                                                          period_net_cr_before,
                            fatv.start_date                                               start_date,
                            fatv.end_date                                                 end_date,
                            fatv.created_by                                               created_by,
                            fatv.creation_date                                            creation_date,
                            fatv.last_updated_by                                          last_updated_by,
                            fatv.last_update_date                                         last_update_date
                    FROM    fins_ar_transactions_v                  fatv
                    WHERE   1                                     = 1
                    AND     to_date(fatv.ar_trx_date)            >= v_erp_financials_start_date
                    AND     fatv.status_id                    not in (10006,10007)
                    AND     not exists
                            ( select  'c'
                              from    fins_gl_jv_headers_v          sae
                              where   1                           = 1
                              and     sae.jv_sub_category_code   in ('SALES INVOICES','CREDIT MEMOS','DEBIT MEMOS')
                              and     sae.feed_trx_application_id = 304
                              and     sae.feed_trx_document_type_id=fatv.ar_trx_type_id
                              and     sae.feed_trx_document_id    = fatv.ar_trx_id
                            )
                    AND     exists
                            ( select  'c'
                              from    cmn_status_master             csm
                              where   1                           = 1
                              and     upper(nvl(csm.close_status,'N'))  <>  'Y'
                              and     csm.status_id               = fatv.status_id
                              and     csm.client_id               = fatv.client_id
                            ) 
/*                    AND     exists
                            ( select  'c'
                              from    fins_ar_transaction_lines     fatl
                              where   1                           = 1
----                              and     round(nvl(fatl.dr_amount,fatl.ar_trx_line_amount),2)  <> 0
                              and     fatl.ar_trx_id              = fatv.ar_trx_id
                              and     fatl.client_id              = fatv.client_id
                            )*/
----                    AND     round(nvl(fatv.ar_trx_total_amount,0),2)  <> 0
                    AND     upper(nvl(fatv.eligible_to_accounting,'Y')) = 'Y'
                    AND     fatv.debtors_account_id              is not null
                    AND     nvl(fatv.sla_accounting_flag,'N')     = 'N'
                    and     fatv.sla_header_id                   is null
                    and     fatv.sla_jv_name                     is null
                    AND     fatv.ar_trx_id                        = nvl(p_ar_trx_id, fatv.ar_trx_id) 
                    AND     fatv.profit_centre_id                 = nvl(p_profit_centre_id,fatv.profit_centre_id)
                    AND     fatv.lob_id                           = nvl(p_lob_id,fatv.lob_id)
                    AND     fatv.organization_id                  = nvl(p_organization_id,fatv.organization_id)
                    AND     fatv.client_id                        = p_client_id
                    ORDER   BY  fatv.client_id, 
                                fatv.organization_id, 
                                fatv.lob_id, 
                                fatv.profit_centre_id, 
                                fatv.ar_trx_id;

            CURSOR  get_jv_lines 
                    ( c_ar_trx_id         number,
                      c_profit_centre_id  number,
                      c_lob_id            number,
                      c_organization_id   number,
                      c_client_id         number
                    )
            IS
                    SELECT  /*+ PARALLEL (fins_ar_transaction_lines_v, 4) */
                            fatl.creation_date                                            creation_date,
                            fatl.created_by                                               created_by,
                            fatl.last_update_date                                         last_update_date,
                            fatl.last_updated_by                                          last_updated_by,
                            fatl.start_date                                               start_date,
                            fatl.end_date                                                 end_date,
                            10012                                                         status_id,
                            sysdate                                                       status_date,
                            fatl.client_id                                                client_id,
                            fatl.ar_trx_id                                                ar_trx_id,
                            fatl.ar_trx_line_id                                           ar_trx_line_id,
                            fatl.ar_trx_line_narration                                    description,
                            'ITEM'                                                        jv_line_type,
                            fatl.ar_trx_line_amount                                       ar_trx_line_amount,
                            fatl.period_id                                                period_id,
                            fatl.period_name                                              period_name,
                            ( select  party_combination_id
                              from    cmn_customer_master_v         ccmv
                              where   1                           = 1
                              and     ccmv.party_id               = fatl.party_id
                              and     ccmv.client_id              = fatl.client_id
                            )                                                             party_combination_id,
                            fatl.party_id                                                 party_id,
                            fatl.inventory_item_id                                        inventory_item_id,
                            304                                                           feed_trx_application_id,
                            fatl.ar_trx_type_id                                           feed_trx_document_type_id,
                            fatl.ar_trx_id                                                feed_trx_document_id,
                            fatl.ar_trx_line_id                                           feed_trx_document_line_id,
                            fatl.ar_trx_number                                            feed_trx_number,
                            fatl.ar_trx_date                                              feed_trx_date,
                            fatl.ar_trx_code                                              ar_trx_code,
                            'FINS_AR_TRANSACTION_LINES'                                   feed_transaction_table_name,
                            fatl.revenue_account_id                                       revenue_account_id,
                            fatl.debtors_account_id                                       debtors_account_id,
                            abs(round(nvl(fatl.dr_amount,fatl.ar_trx_line_amount),2))     entered_dr,
                            abs(round(nvl(fatl.dr_amount,fatl.ar_trx_line_amount),2))     entered_cr,
/*
                            case
                            when  (fatl.ar_trx_code in  ('INVOICE','DRN','DN'))
                            then  round(nvl(fatl.dr_amount,fatl.ar_trx_line_amount),2)
                            else  null
                            end   as                                                      entered_dr,
                            case
                            when  (fatl.ar_trx_code in  ('CRN','CN'))
                            then  (-1 * round(nvl(fatl.dr_amount,fatl.ar_trx_line_amount),2))
                            else  null
                            end   as                                                      entered_cr,
*/
                            fatl.currency_code                                            currency_code,
                            fatl.exchange_rate                                            exchange_rate,
                            fatl.exchange_date                                            exchange_date,
                            abs(round ( ( nvl(fatl.dr_amount,fatl.ar_trx_line_amount)  *
                                      nvl(fatl.exchange_rate,1)
                                    ),2
                                    ))                                                    accounted_dr,
                            abs(round ( ( nvl(fatl.dr_amount,fatl.ar_trx_line_amount)  *
                                      nvl(fatl.exchange_rate,1)
                                    ),2
                                    ))                                                    accounted_cr,
/*
                            case
                            when  (fatl.ar_trx_code in  ('INVOICE','DRN','DN'))
                            then  round ( ( nvl(fatl.dr_amount,fatl.ar_trx_line_amount)  *
                                      nvl(fatl.exchange_rate,1)
                                    ),2
                                    )
                            end   as                                                      accounted_dr,
                            case
                            when  (fatl.ar_trx_code in  ('CRN','CN'))
                            then  (-1 * round ( ( nvl(fatl.dr_amount,fatl.ar_trx_line_amount)  *
                                      nvl(fatl.exchange_rate,1)
                                    ),2)
                                    )
                            end   as                                                      accounted_cr,
*/
                            fatl.ar_trx_line_id                                           gl_sl_link_id,
                            'FINS_AR_TRANSACTION_LINES'                                   gl_sl_link_table,
                            null                                                          reference_1,
                            null                                                          reference_2,
                            null                                                          reference_3,
                            null                                                          reference_4,
                            null                                                          reference_5,
                            null                                                          period_begin_balance_dr_before,
                            null                                                          period_begine_balance_cr_before,
                            null                                                          period_net_dr_before,
                            null                                                          period_net_cr_before
                    FROM    fins_ar_transaction_lines_v             fatl
                    WHERE   1                                     = 1
                    AND     to_date(fatl.ar_trx_date)            >= v_erp_financials_start_date
                    AND     fatl.status_id                    not in (10006,10007)
                    AND     fatl.sla_accounting_date             is null
                    AND     nvl(fatl.sla_accounting_flag,'N')     = 'N'
                    AND     fatl.sla_header_id                   is null
                    AND     fatl.sla_line_id                     is null
                    AND     fatl.sla_line_number                 is null
                    AND     fatl.ar_trx_id                        = c_ar_trx_id
                    AND     fatl.profit_centre_id                 = c_profit_centre_id
                    AND     fatl.lob_id                           = c_lob_id
                    AND     fatl.organization_id                  = c_organization_id
                    AND     fatl.client_id                        = c_client_id;

----        Cursor for Tax Lines
            CURSOR  get_trx_tax_lines 
                    ( c_ar_trx_line_id    number,
                      c_ar_trx_id         number,
                      c_profit_centre_id  number,
                      c_lob_id            number,
                      c_organization_id   number,
                      c_client_id         number
                    )
            IS
                    SELECT  /*+ PARALLEL (bt_trx_tax_lines, 4) */
                            bttl.trx_tax_line_id                    trx_tax_line_id,
                            bttl.trx_tax_header_id                  trx_tax_header_id,
                            bttl.base_trx_id                        base_trx_id,
                            bttl.base_trx_line_id                   base_trx_line_id,
                            'TAX'                                   trx_tax_line_type,
                            bttl.dr_account_id                      dr_account_id,
                            bttl.cr_account_id                      cr_account_id,
                            abs(bttl.dr_amount)                     dr_amount,
                            abs(bttl.cr_amount)                     cr_amount
                    FROM    bt_trx_tax_lines                  bttl
                    WHERE   1                               = 1
                    AND     bttl.status_id                    not in (10006,10007)
                    AND     trim(upper(bttl.base_trx_type)) = 'ARI'
                    AND     bttl.base_trx_line_id           = c_ar_trx_line_id
                    AND     bttl.base_trx_id                = c_ar_trx_id
                    AND     bttl.profit_centre_id           = c_profit_centre_id
                    AND     bttl.lob_id                     = c_lob_id
                    AND     bttl.organization_id            = c_organization_id
                    AND     bttl.client_id                  = c_client_id;

----        Main Process for Generate Transactions Accounting Starts Here.
BEGIN
----        Initially, we check for the existing accounting transactions which are not transferred to GL. 
----        If they do exist and they are not transferred to GL, we delete the same.
----        Deletion would tak place in all the threee tables namely events, headrs and lines.
----        First We will create the Accounting Events in a loop
            dbms_output.put_line ('Execution Started for Accounting of AR Transactions...');
            p_return_code     :=  0;
            p_return_message  :=  null;

----        Initialize the Dr and Cr Account id on Base transactions if, they are missing.
            d_ap_accrual_account_id         :=  null;
            d_vendor_liability_account_id   :=  null;
            d_revenue_account_id            :=  null;
            d_debtors_account_id            :=  null;
            d_credit_limit_days             :=  null;
            d_credit_limit_amount           :=  null;
            d_payment_term_id               :=  null;
            v_erp_financials_start_date         :=  null;

              BEGIN
                        SELECT  nvl(erp_financials_start_date,to_date('15-AUG-1947','DD-MON-YYYY'))
                        INTO    v_erp_financials_start_date
                        FROM    cmn_client_master
                        WHERE   1               = 1
                        AND     client_id       = p_client_id;
              EXCEPTION 
              WHEN      NO_DATA_FOUND
              THEN      v_erp_financials_start_date :=  to_date('15-AUG-1947','DD-MON-YYYY');
              WHEN      OTHERS
              THEN      v_erp_financials_start_date :=  to_date('15-AUG-1947','DD-MON-YYYY');
              END;

            BEGIN 
                      SELECT  ap_accrual_acct_id,
                              vendor_liability_acct_id,
                              ar_revenue_acct_id,
                              ar_debtors_acct_id,
                              7,
                              0,
                              1
                      INTO    d_ap_accrual_account_id,
                              d_vendor_liability_account_id,
                              d_revenue_account_id,
                              d_debtors_account_id,
                              d_credit_limit_days,
                              d_credit_limit_amount,
                              d_payment_term_id
                      FROM    cmn_transaction_types_v
                      WHERE   1                       = 1
                      AND     trim(upper(transaction_type_code))  = 'DEFAULT_ACCOUNT_CODES'
                      AND     client_id               = p_client_id;
            EXCEPTION 
            WHEN      OTHERS
            THEN      d_ap_accrual_account_id         :=  null;
                      d_vendor_liability_account_id   :=  null;
                      d_revenue_account_id            :=  null;
                      d_debtors_account_id            :=  null;
                      d_credit_limit_days             :=  null;
                      d_credit_limit_amount           :=  null;
                      d_payment_term_id               :=  null;
            END;

            BEGIN
                        UPDATE  cmn_party_combinations
                        SET     ap_accrual_account_id         =  d_ap_accrual_account_id,
                                creditor_liability_account_id =  d_vendor_liability_account_id,
                                revenue_account_id            =  d_revenue_account_id,
                                debtors_account_id            =  d_debtors_account_id
                        WHERE   1                             =   1
                        AND     ( ap_accrual_account_id           is  null
                        OR        creditor_liability_account_id   is  null
                        OR        revenue_account_id              is  null
                        OR        debtors_account_id              is  null
                                )
                        AND     client_id                     =   p_client_id;
            EXCEPTION
            WHEN        OTHERS
            THEN        p_return_code     :=  1;
                        p_return_message  :=  p_return_message ||' - '||'Some Error in Initializing Default DR and CR Account Codes...'||SQLERRM;
            END;

----        Accounting Processin Starts here...
            for   set_jv_headers   in  get_jv_headers
            loop
----              Initialize the working storage parameters
                  v_event_source_id         :=  null;
                  v_event_sub_source_id     :=  null;
                  v_event_category_id       :=  null;
                  v_event_sub_category_id   :=  null;
                  v_sla_event_id            :=  null;
                  v_sla_header_id           :=  null;
                  v_sla_line_id             :=  null;

----              get rvenue and debtors accounts from transaction types

                  v_revenue_account_id  :=  null;
                  v_debtors_account_id  :=  null;

                  BEGIN
                              SELECT  revenue_account_id,
                                      debtors_account_id
                              INTO    v_revenue_account_id,
                                      v_debtors_account_id
                              FROM    cmn_customer_master_v 
                              WHERE   1                   = 1
                              AND     ( v_revenue_account_id  is  null
                              OR        v_debtors_account_id  is  null
                                      )
                              AND     party_id            = set_jv_headers.party_id
                              AND     client_id           = set_jv_headers.client_id;
                  EXCEPTION
                  WHEN        OTHERS
                  THEN        v_revenue_account_id  :=  d_revenue_account_id;
                              v_debtors_account_id  :=  d_debtors_account_id;
                  END;

                  BEGIN
                            SELECT  ar_revenue_acct_id,
                                    ar_debtors_acct_id
                            INTO    v_revenue_account_id,
                                    v_debtors_account_id
                            FROM    cmn_transaction_types_v
                            WHERE   1                   = 1
                            AND     application_id      = 304
                            AND     transaction_type_id = set_jv_headers.transaction_type_id
                            AND     client_id           = set_jv_headers.client_id;
                  EXCEPTION
                  WHEN      OTHERS
                  THEN      v_revenue_account_id  :=  null;
                            v_debtors_account_id  :=  null;
                  END;

                  if    ( v_revenue_account_id  is  null)
                  then  v_revenue_account_id  :=  d_revenue_account_id;
                  end   if;

                  if    ( v_debtors_account_id  is  null)
                  then  v_debtors_account_id  :=  d_debtors_account_id;
                  end   if;

----              Get the JV Header ID

                  v_jv_header_id   :=  0;
                  v_jv_header_id   :=  Get_Sequence_ID 
                                        (       set_jv_headers.client_id,
                                                set_jv_headers.organization_id,
                                                set_jv_headers.lob_id,
                                                set_jv_headers.profit_centre_id,
                                                upper('FINS_GL_JV_HEADERS')
                                        );
                  commit;
                  IF      (v_jv_header_id   < 0 )
                  THEN    p_return_code     := 2;
                          p_return_message  := p_return_message ||  ' - '  ||
                                               'JV Header ID Can not be Generated..';
                          rollback;
                          raise some_error;
                  END     IF;

---               Now we will create fins_gl_jv_headers
                  BEGIN
                            insert into FINS_GL_JV_HEADERS
                            ( creation_date,
----                          Standard Who Columns       
                              created_by,
                              last_update_date,
                              last_updated_by,
                              start_date,
                              end_date,
-----                         GL JV Document and Status Colmns
                              status_id,
                              status_date,
                              place_lattitude,
                              place_longitude,
                              place_ip_address,
                              transaction_type_id,
                              transaction_application_id,
                              transaction_process_id,
                              transaction_level_id,
----                          GL JV Identificaiton and Information
                              jv_header_id,
                              client_id,
                              jv_name,
                              jv_description,
                              actual_flag,
                              jv_source_set_id,
                              jv_source_code_id,
                              jv_category_id,
                              jv_sub_category_id,
                              period_id,
                              period_name,
                              posted_date,
                              posted_flag,
                              posting_error,
                              running_total_dr,
                              running_total_cr,
                              TR_running_total_dr,
                              TR_running_total_cr,
                              AR_running_total_dr,
                              AR_running_total_cr,
                              SR_running_total_dr,
                              SR_running_total_cr,
----                          Organization Information
                              profit_centre_id,
                              lob_id,
                              organization_id,
----                          Planning and Budgeting Information
                              plan_header_id,
                              plan_detail_id,
                              budget_id,
                              budget_line_id,
                              project_id,
                              project_task_id,
----                          GL / SL Linking Identificaiton and Information
                              gl_sl_link_id,
                              gl_sl_link_table,
                              sla_event_id,
                              sla_header_id,
                              gl_posting_id,
                              debtors_posting_id,
                              debtors_posted_date,
                              creditors_posting_id,
                              creditors_posted_date,
                              other_sl_posting_id,
                              other_sl_posted_date,
                              feed_trx_application_id,
                              feed_trx_document_type_id,
                              feed_trx_document_id,
                              feed_trx_number,
                              feed_trx_date,
                              feed_transaction_table_name
                            )
                            VALUES
                            ( set_jv_headers.creation_date,
----                          Standard Who Columns       
                              set_jv_headers.created_by,
                              set_jv_headers.last_update_date,
                              set_jv_headers.last_updated_by,
                              set_jv_headers.start_date,
                              set_jv_headers.end_date,
-----                         GL JV Document and Status Colmns
                              set_jv_headers.status_id,
                              set_jv_headers.status_date,
                              p_place_lattitude,
                              p_place_longitude,
                              p_place_ip_address,
                              set_jv_headers.feed_trx_document_type_id,
                              p_transaction_application_id,
                              p_transaction_process_id,
                              p_transaction_level_id,
----                          GL JV Identificaiton and Information
                              v_jv_header_id,
                              set_jv_headers.client_id,
                              set_jv_headers.jv_name,
                              set_jv_headers.description,
                              set_jv_headers.actual_flag,
                              set_jv_headers.jv_source_set_id,
                              set_jv_headers.jv_source_code_id,
                              set_jv_headers.jv_category_id,
                              set_jv_headers.jv_sub_category_id,
                              set_jv_headers.period_id,
                              set_jv_headers.period_name,
                              set_jv_headers.posted_date,
                              set_jv_headers.posted_flag,
                              set_jv_headers.posting_error,
                              set_jv_headers.running_total_dr,
                              set_jv_headers.running_total_cr,
                              set_jv_headers.running_total_dr,
                              set_jv_headers.running_total_cr,
                              set_jv_headers.running_total_dr,
                              set_jv_headers.running_total_cr,
                              set_jv_headers.running_total_dr,
                              set_jv_headers.running_total_cr,
----                          Organization Information
                              set_jv_headers.profit_centre_id,
                              set_jv_headers.lob_id,
                              set_jv_headers.organization_id,
----                          Planning and Budgeting Information
                              set_jv_headers.plan_header_id,
                              set_jv_headers.plan_detail_id,
                              set_jv_headers.budget_id,
                              set_jv_headers.budget_line_id,
                              set_jv_headers.project_id,
                              set_jv_headers.project_task_id,
----                          GL / SL Linking Identificaiton and Information
                              set_jv_headers.gl_sl_link_id,
                              set_jv_headers.gl_sl_link_table,
                              v_jv_header_id,
                              v_jv_header_id,
                              set_jv_headers.gl_posting_id,
                              set_jv_headers.debtors_posting_id,
                              set_jv_headers.debtors_posted_date,
                              set_jv_headers.creditors_posting_id,
                              set_jv_headers.creditors_posted_date,
                              set_jv_headers.other_sl_posting_id,
                              set_jv_headers.other_sl_posted_date,
                              set_jv_headers.feed_trx_application_id,
                              set_jv_headers.feed_trx_document_type_id,
                              set_jv_headers.feed_trx_document_id,
                              set_jv_headers.feed_trx_number,
                              set_jv_headers.feed_trx_date,
                              set_jv_headers.feed_transaction_table_name
                            );
                  EXCEPTION
                  WHEN      OTHERS
                  THEN      p_return_code     :=  2;
                            p_return_message  :=  p_return_message || 'Record Can not create in FINS_GL_JVHEADERS - '||SQLERRM;
                            RAISE  some_error;
                            rollback;
                            RETURN;
                  END;
                  commit;
----              Set / Update Sequence for Plan Header ID
                  IF      ( SET_Sequence_ID 
                            ( set_jv_headers.client_id, 
                              set_jv_headers.organization_id,
                              set_jv_headers.lob_id,
                              set_jv_headers.profit_centre_id,
                              upper('FINS_GL_JV_HEADERS'), 
                              v_jv_header_id
                            )
                          )
                  THEN    commit;
                  ELSE    p_return_code     :=  2;
                          p_return_message  :=  p_return_message ||  ' - '  ||
                                              'GL JV Header ID Can not be Updated..';
                          rollback;
                          RAISE some_error;
                  END     IF;
                  commit;

----              We will create the Accounting Lines in a loop
                  for   set_jv_lines  in  get_jv_lines
                                      ( set_jv_headers.feed_trx_document_id,
                                        set_jv_headers.profit_centre_id,
                                        set_jv_headers.lob_id,
                                        set_jv_headers.organization_id,
                                        set_jv_headers.client_id
                                      )
                  loop
----                    Create Lines based on FINS_AR_TRANSACTION_LINES
                        v_revenue_ccid        :=  null;
                        v_debtors_ccid        :=  null;
                        v_dr_ccid             :=  null;
                        v_cr_ccid             :=  null;
                        v_dr_amount           :=  null;
                        v_cr_amount           :=  null;
                        v_accounted_dr_amount :=  null;
                        v_accounted_cr_amount :=  null;

----                    get Revenue ccid
                        BEGIN
                                    select  code_combination_id
                                    into    v_revenue_ccid
                                    from    cmn_account_code_combinations_v   cacc
                                    where   1                     = 1
                                    and     cacc.account_code_id  = v_revenue_account_id
                                    and     cacc.profit_centre_id = set_jv_headers.profit_centre_id
                                    and     cacc.lob_id           = set_jv_headers.lob_id
                                    and     cacc.organization_id  = set_jv_headers.organization_id
                                    and     cacc.client_id        = set_jv_headers.client_id;
                        EXCEPTION
                        WHEN        OTHERS
                        THEN        v_revenue_ccid                :=  null;
                        END;

----                    get debtors ccid
                        BEGIN
                                    select  code_combination_id
                                    into    v_debtors_ccid
                                    from    cmn_account_code_combinations_v   cacc
                                    where   1                     = 1
                                    and     cacc.account_code_id  = v_debtors_account_id
                                    and     cacc.profit_centre_id = set_jv_headers.profit_centre_id
                                    and     cacc.lob_id           = set_jv_headers.lob_id
                                    and     cacc.organization_id  = set_jv_headers.organization_id
                                    and     cacc.client_id        = set_jv_headers.client_id;
                        EXCEPTION
                        WHEN        OTHERS
                        THEN        v_revenue_ccid                :=  null;
                        END;

----                    First Generate Debit and Credit Lines for Event
----                    Debit Record First - Debit the Debtors
                        v_ccid  :=  null;
                        IF    (set_jv_headers.ar_trx_code in  ('INVOICE','DRN','DN'))
                        then  v_ccid  :=  v_debtors_ccid;
                        ELSE  v_ccid  :=  v_revenue_ccid;
                        END   IF;

                        v_jv_line_id      :=  0;
                        v_jv_line_id      :=  Get_Sequence_ID 
                                              (       set_jv_headers.client_id,
                                                      set_jv_headers.organization_id,
                                                      set_jv_headers.lob_id,
                                                      set_jv_headers.profit_centre_id,
                                                      upper('FINS_GL_JV_LINES')
                                              );
                        commit;
                        IF      (v_jv_line_id   < 0 )
                        THEN    p_return_code     := 2;
                                p_return_message  := p_return_message ||  ' - '  ||
                                                    'JV Line ID Can not be Generated..';
                                rollback;
                                raise some_error;
                        END     IF;

                        BEGIN
                            insert into FINS_GL_JV_LINES
                            ( creation_date,
                              created_by,
                              last_update_date,
                              last_updated_by,
                              start_date,
                              end_date,
      -----                   GL JV Lines Document and Status Colmns
                              status_id,
                              status_date,
                              place_lattitude,
                              place_longitude,
                              place_ip_address,
                              transaction_type_id,
                              transaction_application_id,
                              transaction_process_id,
                              transaction_level_id,
      ----                    GL JV Lines Identificaiton and Information
                              jv_line_id,
                              jv_header_id,
                              client_id,
                              jv_line_number,
                              jv_effective_date,
                              period_id,
                              period_name,
                              jv_line_name,
                              jv_line_description,
                              jv_line_type,
                              code_combination_id,
                              entered_dr,
                              entered_cr,
                              TR_entered_dr,
                              TR_entered_cr,
                              AR_entered_dr,
                              AR_entered_cr,
                              SR_entered_dr,
                              SR_entered_cr,
                              exchange_rate,
                              exchange_rate_date,
                              accounted_dr,
                              accounted_cr,
                              TR_accounted_dr,
                              TR_accounted_cr,
                              AR_accounted_dr,
                              AR_accounted_cr,
                              SR_accounted_dr,
                              SR_accounted_cr,
                              actual_flag,
                              posted_date,
                              posted_flag,
                              posting_error,
                              reference_1,
                              reference_2,
                              reference_3,
                              reference_4,
                              reference_5,
                              party_combination_id,
                              party_id,
                              inventory_item_id,
      ----                    GL JV Organization Information
                              profit_centre_id,
                              lob_id,
                              organization_id,
      ----                    GL / SL Linking Identificaiton and Information
                              gl_sl_link_id,
                              gl_sl_link_table,
                              sla_event_id,
                              sla_header_id,
                              sla_line_id,
                              period_begin_balance_dr_before,
                              period_begine_balance_cr_before,
                              period_net_dr_before,
                              period_net_cr_before,
                              TR_period_begin_balance_dr_before,
                              TR_period_begine_balance_cr_before,
                              TR_period_net_dr_before,
                              TR_period_net_cr_before,
                              AR_period_begin_balance_dr_before,
                              AR_period_begine_balance_cr_before,
                              AR_period_net_dr_before,
                              AR_period_net_cr_before,
                              SR_period_begin_balance_dr_before,
                              SR_period_begine_balance_cr_before,
                              SR_period_net_dr_before,
                              SR_period_net_cr_before,
                              debtors_posting_id,
                              debtors_posted_date,
                              creditors_posting_id,
                              creditors_posted_date,
                              other_sl_posting_id,
                              other_sl_posted_date,
                              feed_trx_application_id,
                              feed_trx_document_type_id,
                              feed_trx_document_id,
                              feed_trx_document_line_id,
                              feed_trx_number,
                              feed_trx_date,
                              feed_transaction_table_name
                            )
                            VALUES
                            ( set_jv_headers.creation_date,
                              set_jv_headers.created_by,
                              set_jv_headers.last_update_date,
                              set_jv_headers.last_updated_by,
                              set_jv_headers.start_date,
                              set_jv_headers.end_date,
      -----                   GL JV Lines Document and Status Colmns
                              set_jv_headers.status_id,
                              set_jv_headers.status_date,
                              p_place_lattitude,
                              p_place_longitude,
                              p_place_ip_address,
                              set_jv_headers.feed_trx_document_type_id,
                              p_transaction_application_id,
                              p_transaction_process_id,
                              p_transaction_level_id,
      ----                    GL JV Lines Identificaiton and Information
                              v_jv_line_id,
                              v_jv_header_id,
                              set_jv_lines.client_id,
                              v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                              set_jv_headers.jv_effective_date,
                              set_jv_headers.period_id,
                              set_jv_headers.period_name,
                              set_jv_headers.jv_name,
                              set_jv_lines.description,
                              set_jv_lines.jv_line_type,
                              v_ccid,
----                          Amounts based on Accounting Method
                              set_jv_lines.entered_dr,
                              null, ----  set_jv_headers.entered_cr,
----                          Amounts based on Transaction Rates
                              set_jv_lines.entered_dr,
                              null, ----  set_jv_headers.entered_cr,
----                          Amounts based on Average Rates
                              set_jv_lines.entered_dr,
                              null, ----  set_jv_headers.entered_cr,
----                          Amounts based on Standard Rates
                              set_jv_lines.entered_dr,
                              null, ----  set_jv_headers.entered_cr,
                              set_jv_lines.exchange_rate,
                              set_jv_lines.exchange_date,
----                          Amounts based on Accounting Method
                              set_jv_lines.accounted_dr,
                              null, ----  set_jv_headers.accounted_cr,
----                          Amounts based on Transaction Rates
                              set_jv_lines.accounted_dr,
                              null, ----  set_jv_headers.accounted_cr,
----                          Amounts based on Average Rates
                              set_jv_lines.accounted_dr,
                              null, ----  set_jv_headers.accounted_cr,
----                          Amounts based on Standard Rates
                              set_jv_lines.accounted_dr,
                              null, ----  set_jv_headers.accounted_cr,
                              set_jv_headers.actual_flag,
                              set_jv_headers.posted_date,
                              set_jv_headers.posted_flag,
                              set_jv_headers.posting_error,
                              set_jv_headers.reference_1,
                              set_jv_headers.reference_2,
                              set_jv_headers.reference_3,
                              set_jv_headers.reference_4,
                              set_jv_headers.reference_5,
                              set_jv_lines.party_combination_id,
                              set_jv_lines.party_id,
                              set_jv_lines.inventory_item_id,
      ----                    GL JV Organization Information
                              set_jv_headers.profit_centre_id,
                              set_jv_headers.lob_id,
                              set_jv_headers.organization_id,
      ----                    GL / SL Linking Identificaiton and Information
                              set_jv_lines.gl_sl_link_id,
                              set_jv_lines.gl_sl_link_table,
                              v_jv_header_id,
                              v_jv_header_id,
                              v_jv_line_id,
----                          Amounts based on Accounting Method
                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,
----                          Amounts based on Transaction Rates
                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,
----                          Amounts based on Average Rates
                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,
----                          Amounts based on Standard Rates
                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,
                              set_jv_headers.debtors_posting_id,
                              set_jv_headers.debtors_posted_date,
                              set_jv_headers.creditors_posting_id,
                              set_jv_headers.creditors_posted_date,
                              set_jv_headers.other_sl_posting_id,
                              set_jv_headers.other_sl_posted_date,
                              set_jv_headers.feed_trx_application_id,
                              set_jv_headers.feed_trx_document_type_id,
                              set_jv_headers.feed_trx_document_id,
                              set_jv_lines.feed_trx_document_line_id,
                              set_jv_headers.feed_trx_number,
                              set_jv_headers.feed_trx_date,
                              set_jv_headers.feed_transaction_table_name
                            );
                            commit;
                        EXCEPTION
                        WHEN      OTHERS
                        THEN      p_return_code     :=  2;
                                  p_return_message  :=  p_return_message || 'JV Line Record Can not created in FINS_GL_JV_LINES - '||SQLERRM;
                                  RAISE  some_error;
                                  rollback;
                                  RETURN;
                        END;
      ----              Set / Update Sequence for Plan Header ID
                        IF      ( SET_Sequence_ID 
                                  ( set_jv_headers.client_id, 
                                    set_jv_headers.organization_id,
                                    set_jv_headers.lob_id,
                                    set_jv_headers.profit_centre_id,
                                    upper('FINS_GL_JV_LINES'), 
                                    v_jv_line_id
                                  )
                                )
                        THEN    commit;
                        ELSE    p_return_code     :=  2;
                                p_return_message  :=  p_return_message ||  ' - '  ||
                                                    'JV Line ID Can not be Updated..';
                                rollback;
                                RAISE some_error;
                        END     IF;
                        commit;

----                    Credit Entry for the Line
----                    Credit Record Now - Credit the Revenue

                        v_ccid  :=  null;
                        IF    (set_jv_headers.ar_trx_code in  ('INVOICE','DRN','DN'))
                        then  v_ccid  :=  v_revenue_ccid;
                        ELSE  v_ccid  :=  v_debtors_ccid;
                        END   IF;

                        v_jv_line_id      :=  0;
                        v_jv_line_id      :=  Get_Sequence_ID 
                                              (       set_jv_headers.client_id,
                                                      set_jv_headers.organization_id,
                                                      set_jv_headers.lob_id,
                                                      set_jv_headers.profit_centre_id,
                                                      upper('FINS_GL_JV_LINES')
                                              );
                        commit;
                        IF      (v_jv_line_id   < 0 )
                        THEN    p_return_code     := 2;
                                p_return_message  := p_return_message ||  ' - '  ||
                                                    'JV Line ID Can not be Generated..';
                                rollback;
                                raise some_error;
                        END     IF;

                        BEGIN
                            insert into FINS_GL_JV_LINES
                            ( creation_date,
                              created_by,
                              last_update_date,
                              last_updated_by,
                              start_date,
                              end_date,
      -----                   GL JV Lines Document and Status Colmns
                              status_id,
                              status_date,
                              place_lattitude,
                              place_longitude,
                              place_ip_address,
                              transaction_type_id,
                              transaction_application_id,
                              transaction_process_id,
                              transaction_level_id,
      ----                    GL JV Lines Identificaiton and Information
                              jv_line_id,
                              jv_header_id,
                              client_id,
                              jv_line_number,
                              jv_effective_date,
                              period_id,
                              period_name,
                              jv_line_name,
                              jv_line_description,
                              jv_line_type,
                              code_combination_id,
                              entered_dr,
                              entered_cr,
                              TR_entered_dr,
                              TR_entered_cr,
                              AR_entered_dr,
                              AR_entered_cr,
                              SR_entered_dr,
                              SR_entered_cr,
                              exchange_rate,
                              exchange_rate_date,
                              accounted_dr,
                              accounted_cr,
                              TR_accounted_dr,
                              TR_accounted_cr,
                              AR_accounted_dr,
                              AR_accounted_cr,
                              SR_accounted_dr,
                              SR_accounted_cr,
                              actual_flag,
                              posted_date,
                              posted_flag,
                              posting_error,
                              reference_1,
                              reference_2,
                              reference_3,
                              reference_4,
                              reference_5,
                              party_combination_id,
                              party_id,
                              inventory_item_id,
      ----                    GL JV Organization Information
                              profit_centre_id,
                              lob_id,
                              organization_id,
      ----                    GL / SL Linking Identificaiton and Information
                              gl_sl_link_id,
                              gl_sl_link_table,
                              sla_event_id,
                              sla_header_id,
                              sla_line_id,
                              period_begin_balance_dr_before,
                              period_begine_balance_cr_before,
                              period_net_dr_before,
                              period_net_cr_before,

                              TR_period_begin_balance_dr_before,
                              TR_period_begine_balance_cr_before,
                              TR_period_net_dr_before,
                              TR_period_net_cr_before,

                              AR_period_begin_balance_dr_before,
                              AR_period_begine_balance_cr_before,
                              AR_period_net_dr_before,
                              AR_period_net_cr_before,

                              SR_period_begin_balance_dr_before,
                              SR_period_begine_balance_cr_before,
                              SR_period_net_dr_before,
                              SR_period_net_cr_before,
                              debtors_posting_id,
                              debtors_posted_date,
                              creditors_posting_id,
                              creditors_posted_date,
                              other_sl_posting_id,
                              other_sl_posted_date,
                              feed_trx_application_id,
                              feed_trx_document_type_id,
                              feed_trx_document_id,
                              feed_trx_document_line_id,
                              feed_trx_number,
                              feed_trx_date,
                              feed_transaction_table_name
                            )
                            VALUES
                            ( set_jv_headers.creation_date,
                              set_jv_headers.created_by,
                              set_jv_headers.last_update_date,
                              set_jv_headers.last_updated_by,
                              set_jv_headers.start_date,
                              set_jv_headers.end_date,
      -----                   GL JV Lines Document and Status Colmns
                              set_jv_headers.status_id,
                              set_jv_headers.status_date,
                              p_place_lattitude,
                              p_place_longitude,
                              p_place_ip_address,
                              set_jv_headers.feed_trx_document_type_id,
                              p_transaction_application_id,
                              p_transaction_process_id,
                              p_transaction_level_id,
      ----                    GL JV Lines Identificaiton and Information
                              v_jv_line_id,
                              v_jv_header_id,
                              set_jv_headers.client_id,
                              v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                              set_jv_headers.jv_effective_date,
                              set_jv_headers.period_id,
                              set_jv_headers.period_name,
                              set_jv_headers.jv_name,
                              set_jv_lines.description,
                              set_jv_lines.jv_line_type,
                              v_ccid,
                              null, ----  set_jv_headers.entered_dr,
                              set_jv_lines.entered_cr,

                              null, ----  set_jv_headers.entered_dr,
                              set_jv_lines.entered_cr,

                              null, ----  set_jv_headers.entered_dr,
                              set_jv_lines.entered_cr,

                              null, ----  set_jv_headers.entered_dr,
                              set_jv_lines.entered_cr,

                              set_jv_lines.exchange_rate,
                              set_jv_lines.exchange_date,

                              null, ----  set_jv_headers.accounted_dr,
                              set_jv_lines.accounted_cr,

                              null, ----  set_jv_headers.accounted_dr,
                              set_jv_lines.accounted_cr,

                              null, ----  set_jv_headers.accounted_dr,
                              set_jv_lines.accounted_cr,

                              null, ----  set_jv_headers.accounted_dr,
                              set_jv_lines.accounted_cr,

                              set_jv_headers.actual_flag,
                              set_jv_headers.posted_date,
                              set_jv_headers.posted_flag,
                              set_jv_headers.posting_error,
                              set_jv_headers.reference_1,
                              set_jv_headers.reference_2,
                              set_jv_headers.reference_3,
                              set_jv_headers.reference_4,
                              set_jv_headers.reference_5,
                              set_jv_lines.party_combination_id,
                              set_jv_lines.party_id,
                              set_jv_lines.inventory_item_id,
      ----                    GL JV Organization Information
                              set_jv_headers.profit_centre_id,
                              set_jv_headers.lob_id,
                              set_jv_headers.organization_id,
      ----                    GL / SL Linking Identificaiton and Information
                              set_jv_lines.gl_sl_link_id,
                              set_jv_lines.gl_sl_link_table,
                              v_jv_header_id,
                              v_jv_header_id,
                              v_jv_line_id,

                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,

                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,

                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,

                              set_jv_headers.period_begin_balance_dr_before,
                              set_jv_headers.period_begine_balance_cr_before,
                              set_jv_headers.period_net_dr_before,
                              set_jv_headers.period_net_cr_before,

                              set_jv_headers.debtors_posting_id,
                              set_jv_headers.debtors_posted_date,
                              set_jv_headers.creditors_posting_id,
                              set_jv_headers.creditors_posted_date,
                              set_jv_headers.other_sl_posting_id,
                              set_jv_headers.other_sl_posted_date,
                              set_jv_headers.feed_trx_application_id,
                              set_jv_headers.feed_trx_document_type_id,
                              set_jv_headers.feed_trx_document_id,
                              set_jv_lines.feed_trx_document_line_id,
                              set_jv_headers.feed_trx_number,
                              set_jv_headers.feed_trx_date,
                              set_jv_headers.feed_transaction_table_name
                            );
                            commit;
                        EXCEPTION
                        WHEN      OTHERS
                        THEN      p_return_code     :=  2;
                                  p_return_message  :=  p_return_message || 'JV Line Record Can not created in FINS_GL_JV_LINES - '||SQLERRM;
                                  RAISE  some_error;
                                  rollback;
                                  RETURN;
                        END;
      ----              Set / Update Sequence for Plan Header ID
                        IF      ( SET_Sequence_ID 
                                  ( set_jv_headers.client_id, 
                                    set_jv_headers.organization_id,
                                    set_jv_headers.lob_id,
                                    set_jv_headers.profit_centre_id,
                                    upper('FINS_GL_JV_LINES'), 
                                    v_jv_line_id
                                  )
                                )
                        THEN    commit;
                        ELSE    p_return_code     :=  2;
                                p_return_message  :=  p_return_message ||  ' - '  ||
                                                    'JV Line ID Can not be Updated..';
                                rollback;
                                RAISE some_error;
                        END     IF;
                        commit;

----                    Write Back and Update fins_ar_transactions and transaction_lines tables
                        BEGIN
                                update  fins_ar_transaction_lines
                                set     sla_accounting_date   = set_jv_headers.sla_accounting_date,
                                        sla_accounting_flag   = 'Y',
                                        eligible_to_accounting= 'N',
                                        sla_line_id           = v_jv_line_id,
                                        sla_line_number       = set_jv_lines.ar_trx_line_id,
                                        sla_header_id         = v_jv_header_id,
                                        revenue_account_id    = v_revenue_account_id,
                                        gl_transfer_flag      = 'Y',
                                        gl_transfer_status    = 'T',
                                        gl_transfer_error     = null,
                                        gl_transfer_date      = set_jv_headers.sla_accounting_date,
                                        jv_header_id          = v_jv_header_id,
                                        jv_line_id            = v_jv_line_id,
                                        jv_dr_account_id      = v_debtors_account_id,
                                        jv_cr_account_id      = v_revenue_account_id,
                                        jv_dr_transfer_amount = set_jv_lines.entered_dr,
                                        jv_cr_transfer_amount = set_jv_lines.entered_cr,
                                        gl_sl_link_table      = set_jv_lines.gl_sl_link_table,
                                        gl_sl_link_id         = set_jv_lines.gl_sl_link_id,
                                        status_id             = 10065,
                                        status_date           = sysdate
                                where   1                     = 1
                                AND     status_id                    not in (10006,10007)
                                and     ar_trx_line_id        = set_jv_lines.ar_trx_line_id
                                and     ar_trx_id             = set_jv_lines.ar_trx_id
                                and     client_id             = set_jv_lines.client_id;
                        EXCEPTION
                        WHEN    OTHERS
                        THEN    p_return_code     :=  2;
                                p_return_message  :=  p_return_message ||  ' - '  ||
                                                      'Can not write back on fins_ar_transaction_line for - '||set_jv_lines.ar_trx_line_id||' - '||SQLERRM;
                                      RAISE some_error;
                                      rollback;
                                      RETURN;
                        END;
                        commit;

----                    Now Generate Accounting Records for Associated Tax Records of the base transaction. First Dr Record

                        ----  Tax Lines for Debit Entries
                        for   set_tax   in  get_trx_tax_lines
                                            ( set_jv_lines.ar_trx_line_id,
                                              set_jv_headers.feed_trx_document_id,
                                              set_jv_headers.profit_centre_id,
                                              set_jv_headers.lob_id,
                                              set_jv_headers.organization_id,
                                              set_jv_headers.client_id
                                            )
                        loop
----                          Debit Record Now - Debit the taxes
----                          First get the Code Combination Id
                              v_ccid            :=  null;
                              IF    (set_jv_headers.ar_trx_code in  ('INVOICE','DRN','DN'))
                              then  v_ccid            :=  get_code_combination_id
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            set_tax.dr_account_id
                                                    );
                              end   if;

                              IF    (set_jv_headers.ar_trx_code in  ('CRN','CN'))
                              then  v_ccid            :=  get_code_combination_id
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            set_tax.cr_account_id
                                                    );
                              end   if;

                              v_jv_line_id      :=  0;
                              v_jv_line_id      :=  Get_Sequence_ID 
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            upper('FINS_GL_JV_LINES')
                                                    );
                              commit;
                              IF      (v_jv_line_id   < 0 )
                              THEN    p_return_code     := 2;
                                      p_return_message  := p_return_message ||  ' - '  ||
                                                          'JV Line ID Can not be Generated..';
                                      rollback;
                                      raise some_error;
                              END     IF;

                              BEGIN
                                  insert into 
                                  FINS_GL_JV_LINES
                                  ( creation_date,
                                    created_by,
                                    last_update_date,
                                    last_updated_by,
                                    start_date,
                                    end_date,
            -----                   GL JV Lines Document and Status Colmns
                                    status_id,
                                    status_date,
                                    place_lattitude,
                                    place_longitude,
                                    place_ip_address,
                                    transaction_type_id,
                                    transaction_application_id,
                                    transaction_process_id,
                                    transaction_level_id,
            ----                    GL JV Lines Identificaiton and Information
                                    jv_line_id,
                                    jv_header_id,
                                    client_id,
                                    jv_line_number,
                                    jv_effective_date,
                                    period_id,
                                    period_name,
                                    jv_line_name,
                                    jv_line_description,
                                    jv_line_type,
                                    code_combination_id,
                                    entered_dr,
                                    entered_cr,
                                    TR_entered_dr,
                                    TR_entered_cr,
                                    AR_entered_dr,
                                    AR_entered_cr,
                                    SR_entered_dr,
                                    SR_entered_cr,
                                    exchange_rate,
                                    exchange_rate_date,
                                    accounted_dr,
                                    accounted_cr,
                                    TR_accounted_dr,
                                    TR_accounted_cr,
                                    AR_accounted_dr,
                                    AR_accounted_cr,
                                    SR_accounted_dr,
                                    SR_accounted_cr,
                                    actual_flag,
                                    posted_date,
                                    posted_flag,
                                    posting_error,
                                    reference_1,
                                    reference_2,
                                    reference_3,
                                    reference_4,
                                    reference_5,
                                    party_combination_id,
                                    party_id,
                                    inventory_item_id,
            ----                    GL JV Organization Information
                                    profit_centre_id,
                                    lob_id,
                                    organization_id,
            ----                    GL / SL Linking Identificaiton and Information
                                    gl_sl_link_id,
                                    gl_sl_link_table,
                                    sla_event_id,
                                    sla_header_id,
                                    sla_line_id,

                                    period_begin_balance_dr_before,
                                    period_begine_balance_cr_before,
                                    period_net_dr_before,
                                    period_net_cr_before,

                                    TR_period_begin_balance_dr_before,
                                    TR_period_begine_balance_cr_before,
                                    TR_period_net_dr_before,
                                    TR_period_net_cr_before,

                                    AR_period_begin_balance_dr_before,
                                    AR_period_begine_balance_cr_before,
                                    AR_period_net_dr_before,
                                    AR_period_net_cr_before,

                                    SR_period_begin_balance_dr_before,
                                    SR_period_begine_balance_cr_before,
                                    SR_period_net_dr_before,
                                    SR_period_net_cr_before,
                                    debtors_posting_id,
                                    debtors_posted_date,
                                    creditors_posting_id,
                                    creditors_posted_date,
                                    other_sl_posting_id,
                                    other_sl_posted_date,
                                    feed_trx_application_id,
                                    feed_trx_document_type_id,
                                    feed_trx_document_id,
                                    feed_trx_document_line_id,
                                    feed_trx_number,
                                    feed_trx_date,
                                    feed_transaction_table_name
                                  )
                                  VALUES
                                  ( set_jv_headers.creation_date,
                                    set_jv_headers.created_by,
                                    set_jv_headers.last_update_date,
                                    set_jv_headers.last_updated_by,
                                    set_jv_headers.start_date,
                                    set_jv_headers.end_date,
            -----                   GL JV Lines Document and Status Colmns
                                    set_jv_headers.status_id,
                                    set_jv_headers.status_date,
                                    p_place_lattitude,
                                    p_place_longitude,
                                    p_place_ip_address,
                                    set_jv_headers.feed_trx_document_type_id,
                                    p_transaction_application_id,
                                    p_transaction_process_id,
                                    p_transaction_level_id,
            ----                    GL JV Lines Identificaiton and Information
                                    v_jv_line_id,
                                    v_jv_header_id,
                                    set_jv_headers.client_id,
                                    v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                                    set_jv_headers.jv_effective_date,
                                    set_jv_headers.period_id,
                                    set_jv_headers.period_name,
                                    set_jv_headers.jv_name,
                                    set_jv_lines.description,
                                    set_tax.trx_tax_line_type,
                                    v_ccid,
                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.cr_amount

                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.cr_amount

                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.cr_amount

                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.cr_amount

                                    set_jv_lines.exchange_rate,
                                    set_jv_lines.exchange_date,

                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.accounted_cr,

                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.accounted_cr,

                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.cr_amount

                                    set_tax.dr_amount, 
                                    null,   ----  set_tax.cr_amount

                                    set_jv_headers.actual_flag,
                                    set_jv_headers.posted_date,
                                    set_jv_headers.posted_flag,
                                    set_jv_headers.posting_error,
                                    set_jv_headers.reference_1,
                                    set_jv_headers.reference_2,
                                    set_jv_headers.reference_3,
                                    set_jv_headers.reference_4,
                                    set_jv_headers.reference_5,
                                    set_jv_lines.party_combination_id,
                                    set_jv_lines.party_id,
                                    set_jv_lines.inventory_item_id,
            ----                    GL JV Organization Information
                                    set_jv_headers.profit_centre_id,
                                    set_jv_headers.lob_id,
                                    set_jv_headers.organization_id,
            ----                    GL / SL Linking Identificaiton and Information
                                    set_jv_lines.gl_sl_link_id,
                                    set_jv_lines.gl_sl_link_table,
                                    v_jv_header_id,
                                    v_jv_header_id,
                                    v_jv_line_id,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.debtors_posting_id,
                                    set_jv_headers.debtors_posted_date,
                                    set_jv_headers.creditors_posting_id,
                                    set_jv_headers.creditors_posted_date,
                                    set_jv_headers.other_sl_posting_id,
                                    set_jv_headers.other_sl_posted_date,
                                    set_jv_headers.feed_trx_application_id,
                                    set_jv_headers.feed_trx_document_type_id,
                                    set_jv_headers.feed_trx_document_id,
                                    set_jv_lines.feed_trx_document_line_id,
                                    set_jv_headers.feed_trx_number,
                                    set_jv_headers.feed_trx_date,
                                    set_jv_headers.feed_transaction_table_name
                                  );
                                  commit;
                              EXCEPTION
                              WHEN      OTHERS
                              THEN      p_return_code     :=  2;
                                        p_return_message  :=  p_return_message || 'JV Line Record Can not created in FINS_GL_JV_LINES - '||SQLERRM;
                                        RAISE  some_error;
                                        rollback;
                                        RETURN;
                              END;
            ----              Set / Update Sequence for Plan Header ID
                              IF      ( SET_Sequence_ID 
                                        ( set_jv_headers.client_id, 
                                          set_jv_headers.organization_id,
                                          set_jv_headers.lob_id,
                                          set_jv_headers.profit_centre_id,
                                          upper('FINS_GL_JV_LINES'), 
                                          v_jv_line_id
                                        )
                                      )
                              THEN    commit;
                              ELSE    p_return_code     :=  2;
                                      p_return_message  :=  p_return_message ||  ' - '  ||
                                                          'JV Line ID Can not be Updated..';
                                      rollback;
                                      RAISE some_error;
                              END     IF;
                              commit;

----                          dbms_output.put_line ('AR Tax Deebit Accounting for Transaction Line '||set_jv_lines.ar_trx_line_id||' Generated Successfully...'||v_ccid||' - Tax Amount - '||set_tax.dr_amount);

----                          Create Credit Record for Taxes
                              v_ccid            :=  null;

                              IF    (set_jv_headers.ar_trx_code in  ('INVOICE','DRN','DN'))
                              then  v_ccid            :=  get_code_combination_id
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            set_tax.cr_account_id
                                                    );
                              end   if;

                              IF    (set_jv_headers.ar_trx_code in  ('CRN','CN'))
                              then  v_ccid            :=  get_code_combination_id
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            set_tax.dr_account_id
                                                    );
                              end   if;

                              v_jv_line_id      :=  0;
                              v_jv_line_id      :=  Get_Sequence_ID 
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            upper('FINS_GL_JV_LINES')
                                                    );
                              commit;
                              IF      (v_jv_line_id   < 0 )
                              THEN    p_return_code     := 2;
                                      p_return_message  := p_return_message ||  ' - '  ||
                                                          'JV Line ID Can not be Generated..';
                                      rollback;
                                      raise some_error;
                              END     IF;

                              BEGIN
                                  insert into 
                                  FINS_GL_JV_LINES
                                  ( creation_date,
                                    created_by,
                                    last_update_date,
                                    last_updated_by,
                                    start_date,
                                    end_date,
            -----                   GL JV Lines Document and Status Colmns
                                    status_id,
                                    status_date,
                                    place_lattitude,
                                    place_longitude,
                                    place_ip_address,
                                    transaction_type_id,
                                    transaction_application_id,
                                    transaction_process_id,
                                    transaction_level_id,
            ----                    GL JV Lines Identificaiton and Information
                                    jv_line_id,
                                    jv_header_id,
                                    client_id,
                                    jv_line_number,
                                    jv_effective_date,
                                    period_id,
                                    period_name,
                                    jv_line_name,
                                    jv_line_description,
                                    jv_line_type,
                                    code_combination_id,
                                    entered_dr,
                                    entered_cr,
                                    TR_entered_dr,
                                    TR_entered_cr,
                                    AR_entered_dr,
                                    AR_entered_cr,
                                    SR_entered_dr,
                                    SR_entered_cr,
                                    exchange_rate,
                                    exchange_rate_date,
                                    accounted_dr,
                                    accounted_cr,
                                    TR_accounted_dr,
                                    TR_accounted_cr,
                                    AR_accounted_dr,
                                    AR_accounted_cr,
                                    SR_accounted_dr,
                                    SR_accounted_cr,
                                    actual_flag,
                                    posted_date,
                                    posted_flag,
                                    posting_error,
                                    reference_1,
                                    reference_2,
                                    reference_3,
                                    reference_4,
                                    reference_5,
                                    party_combination_id,
                                    party_id,
                                    inventory_item_id,
            ----                    GL JV Organization Information
                                    profit_centre_id,
                                    lob_id,
                                    organization_id,
            ----                    GL / SL Linking Identificaiton and Information
                                    gl_sl_link_id,
                                    gl_sl_link_table,
                                    sla_event_id,
                                    sla_header_id,
                                    sla_line_id,

                                    period_begin_balance_dr_before,
                                    period_begine_balance_cr_before,
                                    period_net_dr_before,
                                    period_net_cr_before,

                                    TR_period_begin_balance_dr_before,
                                    TR_period_begine_balance_cr_before,
                                    TR_period_net_dr_before,
                                    TR_period_net_cr_before,

                                    AR_period_begin_balance_dr_before,
                                    AR_period_begine_balance_cr_before,
                                    AR_period_net_dr_before,
                                    AR_period_net_cr_before,

                                    SR_period_begin_balance_dr_before,
                                    SR_period_begine_balance_cr_before,
                                    SR_period_net_dr_before,
                                    SR_period_net_cr_before,

                                    debtors_posting_id,
                                    debtors_posted_date,
                                    creditors_posting_id,
                                    creditors_posted_date,
                                    other_sl_posting_id,
                                    other_sl_posted_date,
                                    feed_trx_application_id,
                                    feed_trx_document_type_id,
                                    feed_trx_document_id,
                                    feed_trx_document_line_id,
                                    feed_trx_number,
                                    feed_trx_date,
                                    feed_transaction_table_name
                                  )
                                  VALUES
                                  ( set_jv_headers.creation_date,
                                    set_jv_headers.created_by,
                                    set_jv_headers.last_update_date,
                                    set_jv_headers.last_updated_by,
                                    set_jv_headers.start_date,
                                    set_jv_headers.end_date,
            -----                   GL JV Lines Document and Status Colmns
                                    set_jv_headers.status_id,
                                    set_jv_headers.status_date,
                                    p_place_lattitude,
                                    p_place_longitude,
                                    p_place_ip_address,
                                    set_jv_headers.feed_trx_document_type_id,
                                    p_transaction_application_id,
                                    p_transaction_process_id,
                                    p_transaction_level_id,
            ----                    GL JV Lines Identificaiton and Information
                                    v_jv_line_id,
                                    v_jv_header_id,
                                    set_jv_headers.client_id,
                                    v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                                    set_jv_headers.jv_effective_date,
                                    set_jv_headers.period_id,
                                    set_jv_headers.period_name,
                                    set_jv_headers.jv_name,
                                    set_jv_lines.description,
                                    set_tax.trx_tax_line_type,
                                    v_ccid,
                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    set_jv_lines.exchange_rate,
                                    set_jv_lines.exchange_date,

                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    null,   ----  set_tax.dr_amount, 
                                    set_tax.cr_amount,

                                    set_jv_headers.actual_flag,
                                    set_jv_headers.posted_date,
                                    set_jv_headers.posted_flag,
                                    set_jv_headers.posting_error,
                                    set_jv_headers.reference_1,
                                    set_jv_headers.reference_2,
                                    set_jv_headers.reference_3,
                                    set_jv_headers.reference_4,
                                    set_jv_headers.reference_5,
                                    set_jv_lines.party_combination_id,
                                    set_jv_lines.party_id,
                                    set_jv_lines.inventory_item_id,
            ----                    GL JV Organization Information
                                    set_jv_headers.profit_centre_id,
                                    set_jv_headers.lob_id,
                                    set_jv_headers.organization_id,
            ----                    GL / SL Linking Identificaiton and Information
                                    set_jv_lines.gl_sl_link_id,
                                    set_jv_lines.gl_sl_link_table,
                                    v_jv_header_id,
                                    v_jv_header_id,
                                    v_jv_line_id,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.period_begin_balance_dr_before,
                                    set_jv_headers.period_begine_balance_cr_before,
                                    set_jv_headers.period_net_dr_before,
                                    set_jv_headers.period_net_cr_before,

                                    set_jv_headers.debtors_posting_id,
                                    set_jv_headers.debtors_posted_date,
                                    set_jv_headers.creditors_posting_id,
                                    set_jv_headers.creditors_posted_date,
                                    set_jv_headers.other_sl_posting_id,
                                    set_jv_headers.other_sl_posted_date,
                                    set_jv_headers.feed_trx_application_id,
                                    set_jv_headers.feed_trx_document_type_id,
                                    set_jv_headers.feed_trx_document_id,
                                    set_jv_lines.feed_trx_document_line_id,
                                    set_jv_headers.feed_trx_number,
                                    set_jv_headers.feed_trx_date,
                                    set_jv_headers.feed_transaction_table_name
                                  );
                                  commit;
                              EXCEPTION
                              WHEN      OTHERS
                              THEN      p_return_code     :=  2;
                                        p_return_message  :=  p_return_message || 'JV Line Record Can not created in FINS_GL_JV_LINES - '||SQLERRM;
                                        RAISE  some_error;
                                        rollback;
                                        RETURN;
                              END;
            ----              Set / Update Sequence for Plan Header ID
                              IF      ( SET_Sequence_ID 
                                        ( set_jv_headers.client_id, 
                                          set_jv_headers.organization_id,
                                          set_jv_headers.lob_id,
                                          set_jv_headers.profit_centre_id,
                                          upper('FINS_GL_JV_LINES'), 
                                          v_jv_line_id
                                        )
                                      )
                              THEN    commit;
                              ELSE    p_return_code     :=  2;
                                      p_return_message  :=  p_return_message ||  ' - '  ||
                                                          'JV Line ID Can not be Updated..';
                                      rollback;
                                      RAISE some_error;
                              END     IF;
                              commit;
                        end loop;       ---- end  Tax Loop
                  end   loop;         -----   end line    loop

----              Write Back and Update fins_ar_transactions and transaction_lines tables
                  BEGIN
                          update  fins_ar_transactions
                          set     sla_jv_name           = set_jv_headers.jv_name,
                                  sla_accounting_flag   = 'Y',
                                  sla_header_id         = v_jv_header_id,
                                  debtors_account_id    = v_debtors_account_id,
                                  eligible_to_accounting= 'N',
                                  status_id             = 10065,
                                  status_date           = sysdate
                          where   1                     = 1
                          AND     status_id                    not in (10006,10007)
                          and     ar_trx_id             = set_jv_headers.feed_trx_document_id
                          and     party_id              = set_jv_headers.party_id
                          and     client_id             = set_jv_headers.client_id;
                  EXCEPTION
                  WHEN    OTHERS
                  THEN    p_return_code     :=  2;
                          p_return_message  :=  p_return_message ||  ' - '  ||
                                                'Can not write back on fins_ar_transaction_line for - '||SQLERRM;
                                RAISE some_error;
                                rollback;
                                RETURN;
                  END;
                  commit;

            end   loop;         -----   end header  loop
            commit;
            p_return_code     :=  0;
            p_return_message  :=  'AR Accounting for Transaction/s '||p_ar_trx_id||' Generated Successfully...';
            dbms_output.put_line ('AR Accounting for Transaction/s '||p_ar_trx_id||' Generated Successfully...');
            RETURN;
EXCEPTION
WHEN        some_error
THEN        DBMS_OUTPUT.put_line (p_return_message || ' - ' || SQLERRM);
            Apex_Util.Set_Session_State('RETURN_MESSAGE' , p_return_message || ' - ' || SQLERRM);
            APEX_ERROR.add_error ( p_error_code         => p_return_message || ' - ' || SQLERRM,
                                   p0                   => null,
                                   p_display_location   => apex_error.c_inline_with_field_and_notif,
                                   p_page_item_name     => null 
                                );
            p_return_code     :=  2;
            p_return_message  :=  p_return_message || ' - ' || SQLERRM;
            RETURN;
END         fins_receivables_transaction_accounting_api;
---------------------------------------------------------------------------------------------------------------------------------
