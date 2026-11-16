--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Generate Accounting for Receivable Applications.
----      These include any kind of Money Receits and Credit Memos
--- -     Written by    : Shriniwas Tilak.
-----     Date Written  : 03rd April 2024
-----     Modified V1   : Shriniwas Tilak - SLA Accounting is demolished. Entries Directly in GL Tables
-----     V1 Modified on: 21st April 2025
--------------------------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE FINS_RECEIVABLES_APPLICATION_ACCOUNTING_API
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
                p_ar_aplication_id            in  number    default null
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
        v_proceeds_unapplied_acct_id        number            :=  null;
        d_debtors_ccid                      number            :=  null;
        d_proceeds_unapplied_acct_id        number            :=  null;
        V_DEBTORS_ACCOUNT_ID                number            :=  null;
        D_DEBTORS_ACCOUNT_ID                number            :=  null;
        v_dr_ccid                           number            :=  null;
        v_cr_ccid                           number            :=  null;
        v_dr_amount                         number            :=  null;
        v_cr_amount                         number            :=  null;
        v_accounted_dr_amount               number            :=  null;
        v_accounted_cr_amount               number            :=  null;
        v_ccid                              number            :=  null;
        V_DR_ACCOUNT_ID                     number            :=  null;
        V_CR_ACCOUNT_ID                     number            :=  null;
        v_erp_financials_start_date         date              :=  null; 

        Some_Error                          EXCEPTION;

        CURSOR      get_jv_headers
        IS
                    SELECT  /*+ PARALLEL (fins_ar_applications_v, 4) */
                            null                                                          event_id,
                            10012                                                         status_id,
                            sysdate                                                       status_date,
                            ( select  category_id
                              from  cmn_Category_master_v
                              where 1                       = 1
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = faav.client_id
                            )                                                             jv_source_set_id,
                            ( select  sub_category_id
                              from  cmn_sub_category_master_V
                              where 1                       = 1
                              and   sub_category_code       = 'RECEIVABLES'
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = faav.client_id
                            )                                                             jv_source_code_id,
                            ( select  category_id
                              from  cmn_category_master_V
                              where 1                       = 1
                              and   category_code           = 'SLA_JOURNAL_CATEGORY_SET'
                              and   client_id               = faav.client_id
                            )                                 jv_category_id,
                            ( select  sub_category_id
                              from  cmn_sub_category_master_V
                              where 1                       = 1
                              and   sub_category_code       = 'RECEIPT_APPLICATIONS'
                              and   category_code           = 'SLA_JOURNAL_CATEGORY_SET'
                              and   client_id               = faav.client_id
                            )                                                             jv_sub_category_id,
                            'APP - '                      ||
                            faav.receivable_aplication_id ||
                            ' RECEIPT - '                 ||      
                            faav.receipt_number           ||  
                            ' TRX - '                     ||
                            faav.ar_trx_number                                            jv_name,
                            'RECEIPT APPLICATION'                                         jv_line_type,
                            faav.transaction_type_id                                      feed_trx_document_type_id,
                            faav.receivable_aplication_id                                 feed_trx_document_id,
                            faav.receivable_aplication_id                                 feed_trx_document_line_id,
                            faav.receivable_aplication_id                                 feed_trx_number,
                            faav.applied_date                                             feed_trx_date,
                            'FINS_AR_APPLICATIONS'                                        feed_transaction_table_name,
                            ( select  application_id
                              from    cmn_applications_master     cam
                              where   1                         = 1
                              and     trim(upper(cam.application_code)) = 'AR'
                              and     client_id                 = faav.client_id
                            )                                                             feed_trx_application_id,
                            faav.applied_date                                             applied_date,
                            abs(round(nvl(faav.applied_amount,0),2))                      sla_header_amount,
                            faav.dr_account_id                                            dr_account_id,
                            abs(round(nvl(faav.applied_amount,0),2))                      entered_dr,
                            abs(round(nvl(faav.applied_amount,0),2))                      accounted_dr,
                            faav.cr_account_id                                            cr_account_id,
                            abs(round(nvl(faav.applied_amount,0),2))                      entered_cr,
                            abs(round(nvl(faav.applied_amount,0),2))                      accounted_cr,
                            faav.receipt_number                                           receipt_number,
                            faav.receipt_date                                             receipt_date,
                            faav.receipt_type                                             receipt_type,
                            faav.receipt_amt_bef_application                              receipt_amount_before_application,
                            faav.ar_trx_number                                            ar_trx_number,
                            faav.ar_trx_date                                              ar_trx_date,
                            faav.ar_trx_code                                              ar_trx_code,
                            faav.ar_trx_amt_bef_application                               trx_amount_before_application,
                            faav.dr_account_name                                          dr_account_name,
                            faav.cr_account_name                                          cr_account_name,
                            faav.salesrep_name                                            salesrep_name,
                            faav.project_name                                             project_name,
                            faav.project_task_name                                        project_task_name,
                            faav.plan_header_name                                         plan_header_name,
                            faav.plan_detail_name                                         plan_detail_name,
                            faav.budget_name                                              budget_name,
                            faav.budget_line_name                                         budget_line_name,
                            faav.Profit_Centre_Name                                       Profit_Centre_Name,
                            faav.Lob_Name                                                 lob_name,
                            faav.Organization_Name                                        Organization_Name,
                            faav.client_name                                              client_name,
                            faav.transaction_type_id                                      transaction_type_id,
                            faav.ar_receipt_id                                            ar_receipt_id,
                            faav.ar_trx_id                                                ar_trx_id,
                            faav.project_task_id                                          project_task_id,
                            faav.project_id                                               project_id,
                            faav.budget_line_id                                           budget_line_id,
                            faav.budget_id                                                budget_id,
                            faav.plan_detail_id                                           plan_detail_id,
                            faav.plan_header_id                                           plan_header_id,
                            faav.party_id                                                 party_id,
                            faav.salesrep_id                                              salesrep_id,
                            faav.profit_centre_id                                         profit_centre_id,
                            faav.lob_id                                                   lob_id,
                            faav.organization_id                                          organization_id,
                            faav.client_id                                                client_id,
                            faav.client_id                                                set_of_books_id,
                            ( select  application_id
                              from    cmn_applications_master     cam
                              where   1                         = 1
                              and     trim(upper(cam.application_code)) = 'AR'
                              and     client_id                 = faav.client_id
                            )                                                             application_id,
                            'A'                                                           actual_flag,
                            'Being Amount of Receipt Applied to Receivable Transaction'   description,
                            ( select  party_combination_id
                              from    cmn_customer_master_v         ccmv
                              where   1                           = 1
                              and     ccmv.party_id               = faav.party_id
                              and     ccmv.client_id              = faav.client_id
                            )                                                             party_combination_id,
                            null                                                          inventory_item_id,
                            'INR'                                                         currency_code,
                            1                                                             exchange_rate,
                            sysdate                                                       exchange_date,
                            faav.applied_date                                             sla_accounting_date,
                            faav.period_id                                                period_id,
                            faav.period_name                                              period_name,
                            null                                                          gl_posting_id,
                            null                                                          debtors_posting_id,
                            null                                                          debtors_posted_date,
                            null                                                          creditors_posting_id,
                            null                                                          creditors_posted_date,
                            null                                                          other_sl_posting_id,
                            null                                                          other_sl_posted_date,
                            faav.applied_date                                             jv_effective_date,
                            null                                                          posted_date,
                            null                                                          posted_flag,
                            null                                                          posting_error,
                            abs(round(nvl(faav.applied_amount,0),2))                      running_total_dr,
                            abs(round(nvl(faav.applied_amount,0),2))                     running_total_cr,
                            faav.receivable_aplication_id                                 gl_sl_link_id,
                            'FINS_AR_APPLICATIONS'                                        gl_sl_link_table,
                            null                                                          reference_1,
                            null                                                          reference_2,
                            null                                                          reference_3,
                            null                                                          reference_4,
                            null                                                          reference_5,
                            null                                                          period_begin_balance_dr_before,
                            null                                                          period_begine_balance_cr_before,
                            null                                                          period_net_dr_before,
                            null                                                          period_net_cr_before,
                            faav.start_date                                               start_date,
                            faav.end_date                                                 end_date,
                            faav.creation_date                                            creation_date,
                            faav.created_by                                               created_by,
                            faav.last_updated_by                                          last_updated_by,
                            faav.last_update_date                                         last_update_date
                    FROM    fins_ar_applications_v                  faav
                    WHERE   1                                     = 1
                    AND     to_date(faav.applied_date)           >= v_erp_financials_start_date
                    AND     faav.status_id                  not in (10006,10007)
                    AND     not exists
                            ( select  'c'
                              from    fins_gl_jv_headers_v          sae
                              where   1                           = 1
                              and     sae.jv_sub_category_code    = 'RECEIPT_APPLICATIONS'
                              and     sae.jv_source_code          = 'RECEIVABLES'
                              and     sae.feed_trx_application_id = 304
                              and     sae.feed_trx_document_type_id=faav.transaction_type_id
                              and     sae.feed_trx_document_id    = faav.receivable_aplication_id
                            )
                    AND     exists
                            ( select  'c'
                              from    cmn_status_master             csm
                              where   1                           = 1
                              and     upper(nvl(csm.close_status,'N'))  <>  'Y'
                              and     csm.status_id               = faav.status_id
                              and     csm.client_id               = faav.client_id
                            ) 
----                    AND     round(nvl(faav.applied_amount,0),2)  <> 0
                    AND     upper(nvl(faav.eligible_to_accounting,'Y')) = 'Y'
                    AND     nvl(faav.sla_accounting_flag,'N')     = 'N'
                    AND     faav.sla_header_id                   is null
                    AND     faav.sla_jv_name                     is null
                    AND     faav.sla_accounting_date             is null
----                Bypass Credit Note Application Accounting, as it is not required, since credit note accounting itself is usfficient
                    AND     faav.ar_cn_id                        is null
                    AND     faav.receivable_aplication_id         = nvl(p_ar_aplication_id, faav.receivable_aplication_id) 
                    AND     faav.profit_centre_id                 = nvl(p_profit_centre_id,faav.profit_centre_id)
                    AND     faav.lob_id                           = nvl(p_lob_id,faav.lob_id)
                    AND     faav.organization_id                  = nvl(p_organization_id,faav.organization_id)
                    AND     faav.client_id                        = p_client_id
                    ORDER   BY  faav.client_id, 
                                faav.organization_id, 
                                faav.lob_id, 
                                faav.profit_centre_id, 
                                faav.receivable_aplication_id;

----        Main Process for Generate Application Accounting Starts Here.
BEGIN
----        Initially, we check for the existing accounting transactions which are not transferred to GL. 
----        If they do exist and they are not transferred to GL, we delete the same.
----        Deletion would tak place in all the threee tables namely events, headrs and lines.
            p_return_code     :=  null;
            p_return_message  :=  'Execution Started for Accounting of AR Applications...';

----        Initialize the Dr and Cr Account id on Base transactions if, they are missing.
            d_proceeds_unapplied_acct_id    :=  null;
            d_debtors_account_id            :=  null;
            v_proceeds_unapplied_acct_id    :=  null;
            v_debtors_account_id            :=  null;
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
                      SELECT  ar_proceeds_unapplied_acct_id,
                              ar_debtors_acct_id
                      INTO    d_proceeds_unapplied_acct_id,
                              d_debtors_account_id
                      FROM    cmn_transaction_types_v
                      WHERE   1                       = 1
                      AND     trim(upper(transaction_type_code))  = 'DEFAULT_ACCOUNT_CODES'
                      AND     client_id               = p_client_id;
            EXCEPTION 
            WHEN      OTHERS
            THEN      d_proceeds_unapplied_acct_id    :=  null;
                      d_debtors_account_id            :=  null;
            END;
            v_proceeds_unapplied_acct_id              :=  d_proceeds_unapplied_acct_id;
            v_debtors_account_id                      :=  d_debtors_account_id;

----        First We will create the Accounting Events in a loop
            dbms_output.put_line ('Execution Started for Accounting of AR Applications...');
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
                            insert into /*+ PARALLEL (FINS_GL_JV_HEADERS, 4) */
                            FINS_GL_JV_HEADERS
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

----              We will create the Accounting Lines 

                  v_revenue_ccid        :=  null;
                  v_debtors_ccid        :=  null;
                  v_dr_ccid             :=  null;
                  v_cr_ccid             :=  null;
                  v_dr_amount           :=  null;
                  v_cr_amount           :=  null;
                  v_accounted_dr_amount :=  null;
                  v_accounted_cr_amount :=  null;

                  v_dr_account_id       :=  set_jv_headers.dr_account_id;
                  v_cr_account_id       :=  set_jv_headers.cr_account_id;

                  if    (v_dr_account_id  is null)
                  then  v_dr_account_id :=  v_proceeds_unapplied_acct_id;
                  end   if;

                  if    (v_cr_account_id  is null)
                  then  v_cr_account_id :=  v_debtors_account_id;
                  end   if;

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

----              get debtors ccid
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

----              Generate Debit Line
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
                        set_jv_headers.exchange_rate,
                        set_jv_headers.exchange_date,
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
----                    GL JV Organization Information
                        set_jv_headers.profit_centre_id,
                        set_jv_headers.lob_id,
                        set_jv_headers.organization_id,
----                    GL / SL Linking Identificaiton and Information
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
                        set_jv_headers.feed_trx_Date,
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

----              Credit Entry for the Line
                  v_jv_line_id     :=  null;
                  v_jv_line_id     :=  Get_Sequence_ID 
                                        (       set_jv_headers.client_id,
                                                set_jv_headers.organization_id,
                                                set_jv_headers.lob_id,
                                                set_jv_headers.profit_centre_id,
                                                upper('FINS_GL_JV_LINES')
                                        );
                  IF      (v_sla_line_id     < 0 )
                  THEN    p_return_code     := 2;
                          p_return_message  := p_return_message ||  ' - '  ||
                                              'SLA Credit Line ID Can not be Generated..';
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
                        set_jv_headers.exchange_rate,
                        set_jv_headers.exchange_date,
                        null,   ----- set_jv_headers.accounted_dr,
                        set_jv_headers.accounted_cr,
                        null,   ----- set_jv_headers.accounted_dr,
                        set_jv_headers.accounted_cr,
                        null,   ----- set_jv_headers.accounted_dr,
                        set_jv_headers.accounted_cr,
                        null,   ----- set_jv_headers.accounted_dr,
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
----                    GL JV Organization Information
                        set_jv_headers.profit_centre_id,
                        set_jv_headers.lob_id,
                        set_jv_headers.organization_id,
----                    GL / SL Linking Identificaiton and Information
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

----              Write Back and Update fins_ar_applications
                  BEGIN
                          update  fins_ar_applications
                          set     sla_accounting_date       = set_jv_headers.sla_accounting_date,
                                  sla_accounting_flag       = 'Y',
                                  eligible_to_accounting    = 'N',
                                  sla_jv_name               = set_jv_headers.jv_name,
                                  sla_header_id             = v_jv_header_id,
                                  dr_account_id             = v_dr_account_id,
                                  cr_account_id             = v_cr_account_id,
                                  gl_transfer_flag          = 'Y',
                                  gl_transfer_status        = 'T',
                                  gl_transfer_error         = null,
                                  gl_transfer_date          = set_jv_headers.sla_accounting_date,
                                  jv_header_id              = v_jv_header_id,
                                  jv_line_id                = v_jv_line_id,
                                  jv_dr_account_id          = v_dr_account_id,
                                  jv_cr_account_id          = v_cr_account_id,
                                  jv_dr_transfer_amount     = set_jv_headers.entered_dr,
                                  jv_cr_transfer_amount     = set_jv_headers.entered_cr,
                                  gl_sl_link_table          = set_jv_headers.gl_sl_link_table,
                                  gl_sl_link_id             = set_jv_headers.gl_sl_link_id,
                                  status_id                 = 10065,
                                  status_date               = sysdate,
                                  last_updated_by           = p_user_id,
                                  last_update_date          = sysdate
                          where   1                         = 1
                          AND     status_id                  not in (10006,10007)
                          and     receivable_aplication_id  = set_jv_headers.feed_trx_document_id
                          and     party_id                  = set_jv_headers.party_id
                          and     client_id                 = set_jv_headers.client_id;
                          commit;
---                          p_return_message := p_return_message || 'SLA JV Name - '||set_jv_headers.event_name||' - Header ID '||v_sla_header_id;
                  EXCEPTION
                  WHEN    OTHERS
                  THEN    p_return_code     :=  2;
                          p_return_message  :=  p_return_message ||  ' - '  ||
                                                'Can not write back on fins_ar_transaction_line  - '||SQLERRM;
                                RAISE some_error;
                                rollback;
                                RETURN;
                  END;
                  commit;
            end   loop;         -----   end header  loop
            commit;

            p_return_message  :=  p_return_message || ' AR Accounting for Money Receipt/s Generated Successfully...';
            dbms_output.put_line (p_return_message);
            return;
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
END fins_receivables_application_accounting_api;
---------------------------------------------------------------------------------------------------------------------------------
