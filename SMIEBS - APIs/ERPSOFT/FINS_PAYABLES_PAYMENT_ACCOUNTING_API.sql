--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Generate Accounting for Supplier Payments in Payables.
----      These include any kind of Money Receits.
--- -     Written by    : Shriniwas Tilak.
-----     Date Written  : 03rd April 2024
-----     Modified V1   : 
-----     V1 Modified on: 
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE "FINS_PAYABLES_PAYMENT_ACCOUNTING_API" 
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
                    p_check_id                    in  number    default null
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
        v_jv_header_id                      number            :=  null;
        v_jv_line_id                        number            :=  null;
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
        d_expenses_account_id               number            :=  null;
        d_ap_bank_account_id                number            :=  null;
        v_ap_bank_account_id                number            :=  null;
        d_payment_bank_account_id           number            :=  null;
        d_ap_payments_unapplied_acct_id     number            :=  null;
        d_ap_bank_reco_account_id           number            :=  null;
        v_ap_bank_reco_account_id           number            :=  null;
        d_payment_bank_reco_account_id      number            :=  null;
        d_dr_account_id                     number            :=  null;
        d_cr_account_id                     number            :=  null;
        v_dr_account_id                     number            :=  null;
        v_cr_account_id                     number            :=  null;
        v_erp_financials_start_date         date              :=  null; 

        Some_Error                          EXCEPTION;

        CURSOR      get_jv_headers
        IS
                    SELECT  /*+ PARALLEL (fins_ap_paymnts_v, 4) */
                            null                                                          jv_id,
                            10012                                                         status_id,
                            sysdate                                                       status_date,
                            ( select  category_id
                              from  cmn_Category_master_v
                              where 1                       = 1
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = famr.client_id
                            )                                                             jv_source_set_id,
                            ( select  sub_category_id
                              from  cmn_sub_category_master_V
                              where 1                       = 1
                              and   sub_category_code       = 'PAYABLES'
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = famr.client_id
                            )                                                             jv_source_code_id,
                            ( select  category_id
                              from  cmn_category_master_V
                              where 1                       = 1
                              and   category_code           = 'SLA_JOURNAL_CATEGORY_SET'
                              and   client_id               = famr.client_id
                            )                                                             jv_category_id,
                            ( select  sub_category_id
                              from    cmn_sub_category_master_V
                              where   1                     = 1
                              and     sub_category_code     = 'PAYMENTS'
                              and     category_code         = 'SLA_JOURNAL_CATEGORY_SET'
                              and     client_id             = famr.client_id
                            )                                                             jv_sub_category_id,
                            'A'                                                           actual_flag,
                            famr.client_id                                                client_id,
                            famr.plan_header_id                                           plan_header_id,
                            famr.plan_detail_id                                           plan_detail_id,
                            famr.budget_id                                                budget_id,
                            famr.budget_line_id                                           budget_line_id,
                            famr.project_id                                               project_id,
                            famr.project_task_id                                          project_task_id,
                            famr.profit_centre_id                                         profit_centre_id,
                            famr.lob_id                                                   lob_id,
                            famr.organization_id                                          organization_id,
                            famr.client_id                                                set_of_books_id,
                            303                                                           application_id,   
                            upper(trim(famr.check_type))                                  ap_trx_code,
                            famr.check_type||' - '||famr.check_id || ' - '||
                            famr.check_number                                             jv_name,
                            famr.check_narration                                          description,
                            'PAYMENT LINE'                                                jv_line_type,
                            round(nvl(famr.check_amount,0),2)                             sla_header_amount,
                            nvl(famr.transaction_type_id,30304)                           transaction_type_id,
                            303                                                           feed_trx_application_id,
                            nvl(famr.transaction_type_id,30304)                           feed_trx_document_type_id,
                            famr.check_id                                                 feed_trx_document_id,
                            famr.check_id                                                 feed_trx_document_line_id,
                            famr.check_number                                             feed_trx_number,
                            famr.check_date                                               feed_trx_date,
                            'FINS_AP_PAYMENTS'                                            feed_transaction_table_name,
                            ( select  party_combination_id
                              from    cmn_vendor_master_v         ccmv
                              where   1                           = 1
                              and     ccmv.party_id               = famr.party_id
                              and     ccmv.client_id              = famr.client_id
                            )                                                             party_combination_id,
                            famr.party_id                                                 party_id,
                            null                                                          inventory_item_id,
                            famr.dr_account_id                                            dr_account_id,
                            famr.cr_account_id                                            cr_account_id,
                            round(nvl(famr.check_amount,0),2)                             entered_dr,
                            round(nvl(famr.check_amount,0),2)                             entered_cr,
                            'INR'                                                         currency_code,
                            1                                                             exchange_rate,
                            sysdate                                                       exchange_date,
                            round(nvl(famr.check_amount,0),2)                             accounted_dr,
                            round(nvl(famr.check_amount,0),2)                             accounted_cr,
                            famr.check_date                                               sla_accounting_date,
                            famr.period_id                                                period_id,
                            famr.period_name                                              period_name,
                            null                                                          gl_posting_id,
                            null                                                          debtors_posting_id,
                            null                                                          debtors_posted_date,
                            null                                                          creditors_posting_id,
                            null                                                          creditors_posted_date,
                            null                                                          other_sl_posting_id,
                            null                                                          other_sl_posted_date,
                            famr.check_date                                               jv_effective_date,
                            null                                                          posted_date,
                            null                                                          posted_flag,
                            null                                                          posting_error,
                            round(nvl(famr.check_amount,0),2)                             running_total_dr,
                            round(nvl(famr.check_amount,0),2)                             running_total_cr,
                            famr.check_id                                                 gl_sl_link_id,
                            'FINS_AP_PAYMENTS'                                            gl_sl_link_table,
                            null                                                          reference_1,
                            null                                                          reference_2,
                            null                                                          reference_3,
                            null                                                          reference_4,
                            null                                                          reference_5,
                            null                                                          period_begin_balance_dr_before,
                            null                                                          period_begine_balance_cr_before,
                            null                                                          period_net_dr_before,
                            null                                                          period_net_cr_before,
                            famr.start_date                                               start_date,
                            famr.end_date                                                 end_date,
                            famr.created_by                                               created_by,
                            famr.creation_date                                            creation_date,
                            famr.last_updated_by                                          last_updated_by,
                            famr.last_update_date                                         last_update_date
                    FROM    fins_ap_payments_v            famr
                    WHERE   1                                     = 1
                    AND     to_date(famr.check_date)             >= v_erp_financials_start_date
                    AND     famr.status_id                    not in (10006,10007)
                    AND     not exists
                            ( select  'c'
                              from    fins_gl_jv_headers_v          sae
                              where   1                           = 1
                              and     sae.jv_sub_category_code    = 'PAYMENTS'
                              and     sae.feed_trx_application_id = 303
                              and     sae.feed_trx_document_type_id=famr.transaction_type_id
                              and     sae.feed_trx_document_id    = famr.check_id
                            )
                    AND     exists
                            ( select  'c'
                              from    cmn_status_master             csm
                              where   1                           = 1
                              and     upper(nvl(csm.close_status,'N'))  <>  'Y'
                              and     csm.status_id               = famr.status_id
                              and     csm.client_id               = famr.client_id
                            ) 
                    AND     upper(nvl(famr.eligible_to_accounting,'Y')) = 'Y'
                    AND     famr.dr_account_id                   is not null
                    AND     famr.cr_account_id                   is not null
                    AND     nvl(famr.sla_accounting_flag,'N')     = 'N'
                    AND     famr.sla_header_id                   is null
                    AND     famr.sla_jv_name                     is null
                    AND     famr.sla_accounting_date             is null
----                    AND     round(nvl(famr.check_amount,0),2)    <> 0
                    AND     famr.check_id                         = nvl(p_check_id, famr.check_id) 
                    AND     famr.profit_centre_id                 = nvl(p_profit_centre_id,famr.profit_centre_id)
                    AND     famr.lob_id                           = nvl(p_lob_id,famr.lob_id)
                    AND     famr.organization_id                  = nvl(p_organization_id,famr.organization_id)
                    AND     famr.client_id                        = p_client_id
                    ORDER   BY  famr.client_id, 
                                famr.organization_id, 
                                famr.lob_id, 
                                famr.profit_centre_id, 
                                famr.check_id;

----        Main Process for Generate Payments Accounting Starts Here.
BEGIN
----        Initially, we check for the existing accounting transactions which are not transferred to GL. 
----        If they do exist and they are not transferred to GL, we delete the same.
----        Deletion would tak place in all the threee tables namely events, headrs and lines.
            p_return_code     :=  null;
            p_return_message  :=  'Execution Started for Accounting of AP Supplier Payments...';

----        Initialize the Dr and Cr Account id on Base transactions if, they are missing.
            d_ap_accrual_account_id         :=  null;
            d_vendor_liability_account_id   :=  null;
            d_expenses_account_id           :=  null;
            d_ap_bank_account_id            :=  null;
            d_payment_bank_account_id       :=  null;
            d_ap_bank_reco_account_id       :=  null;
            d_payment_bank_reco_account_id  :=  null;
            d_dr_account_id                 :=  null;
            d_cr_account_id                 :=  null;
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
                              expenditure_acct_id,
                              ap_bank_acct_id,
                              AP_PAYMENTS_UNAPPLIED_ACCT_ID,
                              bank_reco_acct_id
                      INTO    d_ap_accrual_account_id,
                              d_vendor_liability_account_id,
                              d_expenses_account_id,
                              d_ap_bank_account_id,
                              d_ap_payments_unapplied_acct_id,
                              d_ap_bank_reco_account_id
                      FROM    cmn_transaction_types_v
                      WHERE   1                       = 1
                      AND     trim(upper(transaction_type_code))  = 'DEFAULT_ACCOUNT_CODES'
                      AND     client_id               = p_client_id;
            EXCEPTION 
            WHEN      OTHERS
            THEN      d_ap_accrual_account_id         :=  null;
                      d_vendor_liability_account_id   :=  null;
                      d_expenses_account_id           :=  null;
                      d_ap_bank_account_id            :=  null;
                      d_ap_payments_unapplied_acct_id :=  null;
                      d_ap_bank_reco_account_id       :=  null;
            END;

            v_ap_bank_account_id                      :=  d_ap_bank_account_id;
            v_ap_bank_reco_account_id                 :=  d_ap_bank_reco_account_id;

            BEGIN
                        SELECT  cbam.bank_account_gl_code_id
                        INTO    v_ap_bank_reco_account_id
                        FROM    cmn_bank_account_master   cbam,
                                cmn_profit_centre_master  cpcm
                        WHERE   1                     =   1
                        AND     cbam.bank_account_id  =   cpcm.payment_bank_account_id
                        AND     cbam.client_id        =   cpcm.client_id
                        AND     cpcm.profit_centre_id =   p_profit_centre_id
                        AND     cpcm.lob_id           =   p_lob_id
                        AND     cpcm.organization_id  =   p_organization_id
                        AND     cpcm.client_id        =   p_client_id;
            EXCEPTION 
            WHEN        OTHERS
            THEN        v_ap_bank_reco_account_id    :=  d_ap_bank_reco_account_id;
            END;

            BEGIN
                        UPDATE  cmn_party_combinations
                        SET     ap_accrual_account_id         =  d_ap_accrual_account_id,
                                creditor_liability_account_id =  d_vendor_liability_account_id
                        WHERE   1                             =   1
                        AND     ( ap_accrual_account_id           is  null
                        OR        creditor_liability_account_id   is  null
                                )
                        AND     client_id                     =   p_client_id;
            EXCEPTION
            WHEN        OTHERS
            THEN        p_return_code     :=  1;
                        p_return_message  :=  p_return_message ||' - '||'Some Error in Initializing Default DR and CR Account Codes...'||SQLERRM;
            END;

            for   set_jv_headers   in  get_jv_headers
            loop

----              Creation of JV HEaders
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
      ----                    Standard Who Columns       
                              created_by,
                              last_update_date,
                              last_updated_by,
                              start_date,
                              end_date,
      -----                   GL JV Document and Status Colmns
                              status_id,
                              status_date,
                              place_lattitude,
                              place_longitude,
                              place_ip_address,
                              transaction_type_id,
                              transaction_application_id,
                              transaction_process_id,
                              transaction_level_id,
      ----                    GL JV Identificaiton and Information
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
      ----                    Organization Information
                              profit_centre_id,
                              lob_id,
                              organization_id,
      ----                    Planning and Budgeting Information
                              plan_header_id,
                              plan_detail_id,
                              budget_id,
                              budget_line_id,
                              project_id,
                              project_task_id,
      ----                    GL / SL Linking Identificaiton and Information
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
      ----                    Standard Who Columns       
                              set_jv_headers.created_by,
                              set_jv_headers.last_update_date,
                              set_jv_headers.last_updated_by,
                              set_jv_headers.start_date,
                              set_jv_headers.end_date,
      -----                   GL JV Document and Status Colmns
                              set_jv_headers.status_id,
                              set_jv_headers.status_date,
                              p_place_lattitude,
                              p_place_longitude,
                              p_place_ip_address,
                              set_jv_headers.feed_trx_document_type_id,
                              p_transaction_application_id,
                              p_transaction_process_id,
                              p_transaction_level_id,
      ----                    GL JV Identificaiton and Information
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
      ----                    Organization Information
                              set_jv_headers.profit_centre_id,
                              set_jv_headers.lob_id,
                              set_jv_headers.organization_id,
      ----                    Planning and Budgeting Information
                              set_jv_headers.plan_header_id,
                              set_jv_headers.plan_detail_id,
                              set_jv_headers.budget_id,
                              set_jv_headers.budget_line_id,
                              set_jv_headers.project_id,
                              set_jv_headers.project_task_id,
      ----                    GL / SL Linking Identificaiton and Information
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
      ----        Set / Update Sequence for Plan Header ID
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

----              We will create the Accounting Lines 

                  v_revenue_ccid        :=  null;
                  v_debtors_ccid        :=  null;
                  v_dr_ccid             :=  null;
                  v_cr_ccid             :=  null;
                  v_dr_amount           :=  null;
                  v_cr_amount           :=  null;
                  v_accounted_dr_amount :=  null;
                  v_accounted_cr_amount :=  null;

----              initialize the Debit and Credit Accounts first.
                  v_dr_account_id       :=  null;   ----  Unapplied Payments Account ID
                  v_cr_account_id       :=  null;   ----  Payment Bank Account.

                  v_dr_account_id       :=  d_ap_payments_unapplied_acct_id;
                  v_cr_account_id       :=  v_ap_bank_reco_account_id;

                  IF    (set_jv_headers.dr_account_id is not null)
                  then  v_dr_account_id :=  set_jv_headers.dr_account_id;
                  else  v_dr_account_id :=  d_ap_payments_unapplied_acct_id;
                  END   IF;

                  IF    (set_jv_headers.cr_account_id is not null)
                  then  v_cr_account_id :=  set_jv_headers.cr_account_id;
                  else  v_cr_account_id :=  v_ap_bank_reco_account_id;
                  END   IF;

----              get Debit ccid
                  BEGIN
                              select  code_combination_id
                              into    v_dr_ccid
                              from    cmn_account_code_combinations_v   cacc
                              where   1                     = 1
                              and     cacc.account_code_id  = v_dr_account_id
                              and     cacc.profit_centre_id = set_jv_headers.profit_centre_id
                              and     cacc.lob_id           = set_jv_headers.lob_id
                              and     cacc.organization_id  = set_jv_headers.organization_id
                              and     cacc.client_id        = set_jv_headers.client_id;
                  EXCEPTION
                  WHEN        OTHERS
                  THEN        v_dr_ccid                :=  null;
                  END;

----              get Credit ccid
                  BEGIN
                              select  code_combination_id
                              into    v_cr_ccid
                              from    cmn_account_code_combinations_v   cacc
                              where   1                     = 1
                              and     cacc.account_code_id  = v_cr_account_id
                              and     cacc.profit_centre_id = set_jv_headers.profit_centre_id
                              and     cacc.lob_id           = set_jv_headers.lob_id
                              and     cacc.organization_id  = set_jv_headers.organization_id
                              and     cacc.client_id        = set_jv_headers.client_id;
                  EXCEPTION
                  WHEN        OTHERS
                  THEN        v_cr_ccid                :=  null;
                  END;

----              Generate Debit Line - Debit Payments Unapplied Account
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
      -----             GL JV Lines Document and Status Colmns
                        status_id,
                        status_date,
                        place_lattitude,
                        place_longitude,
                        place_ip_address,
                        transaction_type_id,
                        transaction_application_id,
                        transaction_process_id,
                        transaction_level_id,
      ----              GL JV Lines Identificaiton and Information
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
      ----              GL JV Organization Information
                        profit_centre_id,
                        lob_id,
                        organization_id,
      ----              GL / SL Linking Identificaiton and Information
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
      -----             GL JV Lines Document and Status Colmns
                        set_jv_headers.status_id,
                        set_jv_headers.status_date,
                        p_place_lattitude,
                        p_place_longitude,
                        p_place_ip_address,
                        set_jv_headers.feed_trx_document_type_id,
                        p_transaction_application_id,
                        p_transaction_process_id,
                        p_transaction_level_id,
      ----              GL JV Lines Identificaiton and Information
                        v_jv_line_id,
                        v_jv_header_id,
                        set_jv_headers.client_id,
                        v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                        set_jv_headers.jv_effective_date,
                        set_jv_headers.period_id,
                        set_jv_headers.period_name,
                        set_jv_headers.jv_name,
                        set_jv_headers.description,
                        set_jv_headers.jv_line_type,
                        v_dr_ccid,

                        set_jv_headers.entered_dr,
                        null, ----  set_jv_headers.entered_cr,

                        set_jv_headers.entered_dr,
                        null, ----  set_jv_headers.entered_cr,

                        set_jv_headers.entered_dr,
                        null, ----  set_jv_headers.entered_cr,

                        set_jv_headers.entered_dr,
                        null, ----  set_jv_headers.entered_cr,

                        1,    ----  set_jv_headers.exchange_rate,
                        set_jv_headers.jv_effective_date,

                        set_jv_headers.accounted_dr,
                        null, ----  set_jv_headers.accounted_cr,

                        set_jv_headers.accounted_dr,
                        null, ----  set_jv_headers.accounted_cr,

                        set_jv_headers.accounted_dr,
                        null, ----  set_jv_headers.accounted_cr,

                        set_jv_headers.accounted_dr,
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
                        set_jv_headers.party_combination_id,
                        set_jv_headers.party_id,
                        set_jv_headers.inventory_item_id,
      ----              GL JV Organization Information
                        set_jv_headers.profit_centre_id,
                        set_jv_headers.lob_id,
                        set_jv_headers.organization_id,
      ----              GL / SL Linking Identificaiton and Information
                        set_jv_headers.gl_sl_link_id,
                        set_jv_headers.gl_sl_link_table,
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
                        set_jv_headers.feed_trx_document_line_id,
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
      ----        Set / Update Sequence for Plan Header ID
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

----              Credit Entry for the Line
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
      -----             GL JV Lines Document and Status Colmns
                        status_id,
                        status_date,
                        place_lattitude,
                        place_longitude,
                        place_ip_address,
                        transaction_type_id,
                        transaction_application_id,
                        transaction_process_id,
                        transaction_level_id,
      ----              GL JV Lines Identificaiton and Information
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
      ----              GL JV Organization Information
                        profit_centre_id,
                        lob_id,
                        organization_id,
      ----              GL / SL Linking Identificaiton and Information
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
                        feed_trx_Date,
                        feed_transaction_table_name
                      )
                      VALUES
                      ( set_jv_headers.creation_date,
                        set_jv_headers.created_by,
                        set_jv_headers.last_update_date,
                        set_jv_headers.last_updated_by,
                        set_jv_headers.start_date,
                        set_jv_headers.end_date,
      -----             GL JV Lines Document and Status Colmns
                        set_jv_headers.status_id,
                        set_jv_headers.status_date,
                        p_place_lattitude,
                        p_place_longitude,
                        p_place_ip_address,
                        set_jv_headers.feed_trx_document_type_id,
                        p_transaction_application_id,
                        p_transaction_process_id,
                        p_transaction_level_id,
      ----              GL JV Lines Identificaiton and Information
                        v_jv_line_id,
                        v_jv_header_id,
                        set_jv_headers.client_id,
                        v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                        set_jv_headers.jv_effective_date,
                        set_jv_headers.period_id,
                        set_jv_headers.period_name,
                        set_jv_headers.jv_name,
                        set_jv_headers.description,
                        set_jv_headers.jv_line_type,
                        v_cr_ccid,

                        null,   ----  set_jv_headers.entered_dr,
                        set_jv_headers.entered_cr,

                        null,   ----  set_jv_headers.entered_dr,
                        set_jv_headers.entered_cr,

                        null,   ----  set_jv_headers.entered_dr,
                        set_jv_headers.entered_cr,

                        null,   ----  set_jv_headers.entered_dr,
                        set_jv_headers.entered_cr,

                        1,      ----  set_jv_headers.exchange_rate,
                        set_jv_headers.jv_effective_date,

                        null,   ----  set_jv_headers.accounted_dr,
                        set_jv_headers.accounted_cr,

                        null,   ----  set_jv_headers.accounted_dr,
                        set_jv_headers.accounted_cr,

                        null,   ----  set_jv_headers.accounted_dr,
                        set_jv_headers.accounted_cr,

                        null,   ----  set_jv_headers.accounted_dr,
                        set_jv_headers.accounted_cr,

                        set_jv_headers.actual_flag,
                        set_jv_headers.posted_date,
                        set_jv_headers.posted_flag,
                        set_jv_headers.posting_error,
                        set_jv_headers.reference_1,
                        set_jv_headers.reference_2,
                        set_jv_headers.reference_3,
                        set_jv_headers.reference_4,
                        set_jv_headers.reference_5,
                        set_jv_headers.party_combination_id,
                        set_jv_headers.party_id,
                        set_jv_headers.inventory_item_id,
      ----              GL JV Organization Information
                        set_jv_headers.profit_centre_id,
                        set_jv_headers.lob_id,
                        set_jv_headers.organization_id,
      ----              GL / SL Linking Identificaiton and Information
                        set_jv_headers.gl_sl_link_id,
                        set_jv_headers.gl_sl_link_table,
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
                        set_jv_headers.feed_trx_document_line_id,
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
      ----        Set / Update Sequence for Plan Header ID
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

----              Write Back and Update fins_ap_transactions and transaction_lines tables
                 BEGIN
                          update  fins_ap_Payments
                          set     sla_accounting_date   = set_jv_headers.sla_accounting_date,
                                  sla_accounting_flag   = 'Y',
                                  eligible_to_accounting= 'N',
                                  sla_jv_name           = set_jv_headers.jv_name,
                                  sla_header_id         = v_jv_header_id,
                                  dr_account_id         = v_dr_account_id,
                                  cr_account_id         = v_cr_account_id,
                                  status_id             = 10065,
                                  status_date           = sysdate
                          where   1                     = 1
                          AND     status_id                    not in (10006,10007)
                          and     check_id              = set_jv_headers.feed_trx_document_id
                          and     party_id              = set_jv_headers.party_id
                          and     client_id             = set_jv_headers.client_id;
                          commit;
                  EXCEPTION
                  WHEN    OTHERS
                  THEN    p_return_code     :=  2;
                          p_return_message  :=  p_return_message ||  ' - '  ||
                                                'Can not write back on fins_ap_transaction_line  - '||SQLERRM;
                                RAISE some_error;
                                rollback;
                                RETURN;
                  END;
                  commit;

            end   loop;         -----   end header  loop
            commit;

            p_return_message  :=  p_return_message || ' AP Accounting for Payment/s Generated Successfully...';
            dbms_output.put_line (p_return_message);
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
END fins_payables_payment_accounting_api;
---------------------------------------------------------------------------------------------------------------------------------
