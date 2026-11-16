--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Generate Accounting for Payable Transactions.
----      These include, Invoices, Credit Notes, Debit Notes which are manualy created.
--- -     Written by    : Shriniwas Tilak.
-----     Date Written  : 03rd April 2024
-----     Modified V1   : 
-----     V1 Modified on: 
--------------------------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE "FINS_INVENTORY_GRR_RECEIPT_ACCOUNTING_API" 
              ( p_return_code                 out varchar2,
                p_return_message              out varchar2,
                p_place_lattitude             in  varchar2  default null,
                p_place_longitude             in  varchar2  default null,
                p_place_ip_address            in  varchar2  default null,
                p_transaction_type_id         in  number    default null,
                p_transaction_application_id  in  number    default 302,
                p_transaction_process_id      in  number    default null,
                p_transaction_level_id        in  number    default null,
                p_user_id                     in  varchar2  default 0,
                p_client_id                   in  number,
                p_organization_id             in  number    default null,
                p_lob_id                      in  number    default null,
                p_profit_centre_id            in  number    default null,
                p_receipt_header_id           in  number    default null
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
        v_sla_event_id                      number            :=  null;
        v_sla_header_id                     number            :=  null;
        v_sla_line_id                       number            :=  null;
        v_event_source_id                   number            :=  null;
        v_event_sub_source_id               number            :=  null;
        v_event_category_id                 number            :=  null;
        v_event_sub_category_id             number            :=  null;
        v_ap_application_id                 number            :=  null;
        v_sla_source_id                     number            :=  null;
        v_sla_sub_source_id                 number            :=  null;
        v_sla_category_id                   number            :=  null;
        v_sla_sub_category_id               number            :=  null;
        v_accrual_account_id                number            :=  null;
        v_creditors_account_id              number            :=  null;
        v_ppv_id                            number            :=  null;
        v_receiving_inspection_acct_id      number            :=  null;
        v_inventory_acct_id                 number            :=  null;
        d_accrual_account_id                number            :=  null;
        d_creditors_account_id              number            :=  null;
        d_ppv_id                            number            :=  null;
        d_receiving_inspection_acct_id      number            :=  null;
        d_inventory_acct_id                 number            :=  null;
        v_dr_account_id                     number            :=  null;
        v_cr_account_id                     number            :=  null;
        v_dr_ccid                           number            :=  null;
        v_cr_ccid                           number            :=  null;
        v_dr_amount                         number            :=  null;
        v_cr_amount                         number            :=  null;
        v_accounted_dr_amount               number            :=  null;
        v_accounted_cr_amount               number            :=  null;
        v_ccid                              number            :=  null;
        v_erp_financials_start_date         date              :=  null; 

        Some_Error                          EXCEPTION;

        CURSOR      get_jv_headers
        IS
                    SELECT  /*+ PARALLEL (imr_receipt_headers, 4) */
                            null                                  event_id,
                            10012                                 status_id,
                            sysdate                               status_date,
                            ( select  category_id
                              from  cmn_Category_master_v
                              where 1                       = 1
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = irh.client_id
                            )                                 jv_source_set_id,
                            ( select  sub_category_id
                              from  cmn_sub_category_master_V
                              where 1                       = 1
                              and   sub_category_code       = 'PURCHASING'
                              and   category_code           = 'GL_JOURNAL_SOURCE_SET'
                              and   client_id               = irh.client_id
                            )                                 jv_source_code_id,
                            ( select  category_id
                              from  cmn_category_master_V
                              where 1                       = 1
                              and   category_code           = 'SLA_JOURNAL_CATEGORY_SET'
                              and   client_id               = irh.client_id
                            )                                 jv_category_id,
                            ( select  sub_category_id
                              from    cmn_sub_category_master_V
                              where   1                     = 1
                              and     sub_category_code     = 'RECEIVING'
                              and     category_code         = 'SLA_JOURNAL_CATEGORY_SET'
                              and     client_id             = irh.client_id
                            )                                         jv_sub_category_id,
                            'A'                                       actual_flag,
                            irh.client_id                             client_id,
                            ( select  accounting_method
                              from    cmn_client_master_v     ccm
                              where   1                     = 1
                              and     ccm.client_id         = irh.client_id
                            )                                         accounting_method,
                            irh.plan_header_id                        plan_header_id,
                            irh.plan_detail_id                        plan_detail_id,
                            irh.budget_id                             budget_id,
                            irh.budget_line_id                        budget_line_id,
                            irh.project_id                            project_id,
                            irh.project_task_id                       project_task_id,
                            irh.profit_centre_id                      profit_centre_id,
                            irh.lob_id                                lob_id,
                            irh.organization_id                       organization_id,
                            irh.client_id                             set_of_books_id,
                            ( select  application_id
                              from    cmn_applications_master         cam
                              where   1                             = 1
                              and     application_code              = 'PUR'
                              and     client_id                     = irh.client_id
                            )                                         application_id,
                            'GRR Receipt - '  || irh.receipt_number   jv_name,
                            'GRR Created for Supplier Bill ID - ' ||
                            irh.ap_trx_id               || ' - '  ||
                            'Supplier Bill Number - '             ||
                            irh.supplier_invoice_number               description,
                            round(nvl(irh.line_taxable_amount,0),2)   line_taxable_amount,
                            round(nvl(irh.line_taxable_amount,0),2)   TR_line_taxable_amount,
                            round(nvl(irh.line_taxable_amount,0),2)   AR_line_taxable_amount,
                            round(nvl(irh.line_taxable_amount,0),2)   SR_line_taxable_amount,
                            round(nvl(irh.line_landed_amount,0),2)    sla_header_amount,
                            irh.type_code_id                          transaction_type_id,
                            ( select  application_id
                              from    cmn_applications_master         cam
                              where   1                             = 1
                              and     application_code              = 'PUR'
                              and     client_id                     = irh.client_id
                            )                                         feed_trx_application_id,
                            irh.type_code_id                          feed_trx_document_type_id,
                            irh.receipt_header_id                     feed_trx_document_id,
                            irh.supplier_invoice_number               feed_trx_number,
                            irh.receipt_date                          feed_trx_date,
                            'IMR_RECEIPT_HEADERS'                     feed_transaction_table_name,
                            irh.ap_trx_id                             ap_trx_id,
                            ( select  party_combination_id
                              from    cmn_vendor_master_v             ccmv
                              where   1                             = 1
                              and     ccmv.party_id                 = irh.vendor_party_id
                              and     ccmv.client_id                = irh.client_id
                            )                                         party_combination_id,
                            irh.vendor_party_id                       vendor_party_id,
                            irh.vendor_party_id                       party_id,
                            to_char(irh.receipt_date,'DD-MON-YYYY')   sla_accounting_date,
                            ( select  period_id
                              from    cmn_operating_periods           cop
                              where   1                             = 1
                              and     trunc(irh.receipt_date) between cop.period_start_date 
                                                              and     cop.period_end_date
                              and     cop.client_id                 = irh.client_id 
                            )                                         period_id,
                            ( select  period_name
                              from    cmn_operating_periods           cop
                              where   1                             = 1
                              and     trunc(irh.receipt_date) between cop.period_start_date 
                                                              and     cop.period_end_date
                              and     cop.client_id                 = irh.client_id 
                            )                                         period_name,
                            null                                      gl_posting_id,
                            null                                      debtors_posting_id,
                            null                                      debtors_posted_date,
                            null                                      creditors_posting_id,
                            null                                      creditors_posted_date,
                            null                                      other_sl_posting_id,
                            null                                      other_sl_posted_date,
                            irh.receipt_date                          jv_effective_date,
                            null                                      posted_date,
                            null                                      posted_flag,
                            null                                      posting_error,
                            round(nvl(irh.line_taxable_amount,0),2)   running_total_dr,
                            round(nvl(irh.line_taxable_amount,0),2)   running_total_cr,
                            irh.receipt_header_id                     gl_sl_link_id,
                            'IMR_RECEIPT_HEADERS'                     gl_sl_link_table,
                            null                                      reference_1,
                            null                                      reference_2,
                            null                                      reference_3,
                            null                                      reference_4,
                            null                                      reference_5,
                            null                                      period_begin_balance_dr_before,
                            null                                      period_begine_balance_cr_before,
                            null                                      period_net_dr_before,
                            null                                      period_net_cr_before,
                            irh.start_date                            start_date,
                            irh.end_date                              end_date,
                            irh.created_by                            created_by,
                            irh.creation_date                         creation_date,
                            irh.last_updated_by                       last_updated_by,
                            irh.last_update_date                      last_update_date
                    FROM    imr_receipt_headers                       irh
                    WHERE   1                                       = 1
                    AND     to_date(irh.receipt_date)              >= v_erp_financials_start_date
                    AND     irh.status_id                   not in (10006,10007)
                    AND     not exists
                            ( select  'c'
                              from    fins_gl_jv_headers_v            sae
                              where   1                             = 1
                              and     sae.jv_sub_category_code      = upper('RECEIVING')
                              and     sae.feed_trx_application_id   = 801
                              and     sae.feed_trx_document_type_id = irh.type_code_id
                              and     sae.feed_trx_document_id      = irh.receipt_header_id
                            )
----                    AND     round(nvl(irh.line_taxable_amount,0),2) <>  0
                    AND     upper(nvl(irh.receipt_eligible_to_accounting,'Y'))  = 'Y' 
                    AND     irh.receipt_accounted_flag             is null
                    AND     irh.receipt_accounting_date            is null
                    AND     irh.receipt_accounting_header_id       is null
                    AND     irh.receipt_accounting_event_id        is null
                    AND     irh.receipt_header_id                   = nvl(p_receipt_header_id, irh.receipt_header_id) 
                    AND     irh.profit_centre_id                    = nvl(p_profit_centre_id,irh.profit_centre_id)
                    AND     irh.lob_id                              = nvl(p_lob_id,irh.lob_id)
                    AND     irh.organization_id                     = nvl(p_organization_id,irh.organization_id)
                    AND     irh.client_id                           = p_client_id
                    ORDER   BY  irh.client_id, 
                                irh.organization_id, 
                                irh.lob_id, 
                                irh.profit_centre_id, 
                                irh.receipt_header_id;

            CURSOR  get_jv_lines 
                    ( c_receipt_header_id number,
                      c_profit_centre_id  number,
                      c_lob_id            number,
                      c_organization_id   number,
                      c_client_id         number
                    )
            IS
                    SELECT  /*+ PARALLEL (imr_receipt_lines, 4) */
                            irl.creation_date                         creation_date,
                            irl.created_by                            created_by,
                            irl.last_update_date                      last_update_date,
                            irl.last_updated_by                       last_updated_by,
                            irl.start_date                            start_date,
                            irl.end_date                              end_date,
                            10012                                     status_id,
                            sysdate                                   status_date,
                            irl.client_id                             client_id,
                            ( select  accounting_method
                              from    cmn_client_master_v     ccm
                              where   1                     = 1
                              and     ccm.client_id         = irl.client_id
                            )                                         accounting_method,
                            irh.receipt_header_id                     receipt_header_id,
                            irl.receipt_line_id                       receipt_line_id,
                            'Receipt Accounting for GRR - ' ||  
                            irh.receipt_number                        description,
                            'ITEM'                                    jv_line_type,
                            ( select  application_id
                              from    cmn_applications_master         cam
                              where   1                             = 1
                              and     application_code              = 'PUR'
                              and     client_id                     = irl.client_id
                            )                                         feed_trx_application_id,
                            irh.type_code_id                          feed_trx_document_type_id,
                            irh.receipt_header_id                     feed_trx_document_id,
                            irl.receipt_line_id                       feed_trx_document_line_id,
                            irh.supplier_invoice_number               feed_trx_number,
                            irh.supplier_invoice_date                 feed_trx_date,
                            'IMR_RECEIPT_LINES'                       feed_transaction_table_name,
                            round(nvl(irl.line_base_amount,0),2)      trx_line_amount,
                            round(nvl(irl.line_base_amount,0),2)      TR_trx_line_amount,
                            round(nvl(irl.line_base_amount,0),2)      AR_trx_line_amount,
                            round(nvl(irl.line_base_amount,0),2)      SR_trx_line_amount,
                            ( select  period_id
                              from    cmn_operating_periods           cop
                              where   1                             = 1
                              and     trunc(irh.receipt_date) between cop.period_start_date 
                                                              and     cop.period_end_date
                              and     cop.client_id                 = irh.client_id 
                            )                                         period_id,
                            ( select  period_name
                              from    cmn_operating_periods           cop
                              where   1                             = 1
                              and     trunc(irh.receipt_date) between cop.period_start_date 
                                                              and     cop.period_end_date
                              and     cop.client_id                 = irh.client_id 
                            )                                         period_name,
                            ( select  party_combination_id
                              from    cmn_vendor_master_v           ccmv
                              where   1                             = 1
                              and     ccmv.party_id                 = irl.vendor_party_id
                              and     ccmv.client_id                = irl.client_id
                            )                                         party_combination_id,
                            irl.vendor_party_id                       vendor_party_id,
                            irl.vendor_party_id                       party_id,
                            irl.inventory_item_id                     inventory_item_id,
                            irh.vendor_liability_account_id           vendor_liability_account_id,
                            irh.recieving_inspection_account_id       dr_account_id,
                            irh.ap_accrual_account_id                 cr_account_id,
                            round(nvl(irl.line_base_amount,0),2)      entered_dr,
                            round(nvl(irl.line_base_amount,0),2)      entered_cr,
                            round(nvl(irl.line_base_amount,0),2)      TR_entered_dr,
                            round(nvl(irl.line_base_amount,0),2)      TR_entered_cr,
                            round(nvl(irl.line_base_amount,0),2)      AR_entered_dr,
                            round(nvl(irl.line_base_amount,0),2)      AR_entered_cr,
                            round(nvl(irl.line_base_amount,0),2)      SR_entered_dr,
                            round(nvl(irl.line_base_amount,0),2)      SR_entered_cr,
                            nvl(irh.currency_code,'INR')              currency_code,
                            nvl(irh.conversion_rate,1)                exchange_rate,
                            nvl(irh.conversion_date,sysdate)          exchange_date,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   accounted_dr,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   accounted_cr,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   TR_accounted_dr,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   TR_accounted_cr,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   AR_accounted_dr,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   AR_accounted_cr,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   SR_accounted_dr,
                            round ( irl.line_base_amount *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   SR_accounted_cr,
                            'IMR_RECEIPT_LINES'                       gl_sl_link_table,
                            irl.receipt_line_id                       gl_sl_link_id,
                            irl.ap_trx_id                             ap_trx_id,
                            irl.ap_trx_line_id                        ap_trx_line_id
                    FROM    imr_receipt_lines                         irl,
                            imr_receipt_headers                       irh
                    WHERE   1                                       = 1
                    AND     to_date(irh.receipt_date)              >= v_erp_financials_start_date
                    AND     upper(nvl(irl.receipt_eligible_to_accounting,'Y'))  = 'Y' 
                    AND     irl.receipt_accounted_flag             is null
                    AND     irl.receipt_accounting_date            is null
                    AND     irl.receipt_accounting_header_id       is null
                    AND     irl.receipt_accounting_event_id        is null
                    AND     irl.status_id                   not in (10006,10007)
                    AND     irl.receipt_header_id                   = irh.receipt_header_id
                    AND     irl.client_id                           = irh.client_id
                    AND     irh.status_id                   not in (10006,10007)
                    AND     irh.receipt_header_id                   = c_receipt_header_id
                    AND     irh.profit_centre_id                    = c_profit_centre_id
                    AND     irh.lob_id                              = c_lob_id
                    AND     irh.organization_id                     = c_organization_id
                    AND     irh.client_id                           = c_client_id;

----        Cursor for Tax Lines
            CURSOR  get_trx_tax_lines 
                    ( c_receipt_line_id   number,
                      c_receipt_header_id number,
                      c_profit_centre_id  number,
                      c_lob_id            number,
                      c_organization_id   number,
                      c_client_id         number
                    )
            IS
                    SELECT  /*+ PARALLEL (bt_trx_tax_lines, 4) */
                            bttl.trx_tax_line_id                    trx_tax_line_id,
                            bttl.trx_tax_header_id                  trx_tax_header_id,
                            'TAX'                                   jv_line_type,
                            bttl.base_trx_id                        base_trx_id,
                            bttl.base_trx_line_id                   base_trx_line_id,
                            bttl.dr_account_id                      dr_account_id,
                            bttl.cr_account_id                      cr_account_id,
                            round(nvl(bttl.tax_value,0),2)          dr_amount,
                            round(nvl(bttl.tax_value,0),2)          cr_amount,
                            round(nvl(bttl.tax_value,0),2)          TR_dr_amount,
                            round(nvl(bttl.tax_value,0),2)          TR_cr_amount,
                            round(nvl(bttl.tax_value,0),2)          AR_dr_amount,
                            round(nvl(bttl.tax_value,0),2)          AR_cr_amount,
                            round(nvl(bttl.tax_value,0),2)          SR_dr_amount,
                            round(nvl(bttl.tax_value,0),2)          SR_cr_amount
                    FROM    bt_trx_tax_lines                  bttl
                    WHERE   1                               = 1
                    AND     bttl.status_id                   not in (10006,10007)
                    AND     trim(upper(bttl.base_trx_type)) = 'GRR'
                    AND     bttl.base_trx_line_id           = c_receipt_line_id
                    AND     bttl.base_trx_id                = c_receipt_header_id
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
            dbms_output.put_line ('Execution Started for Accounting of AP Transactions...');
            p_return_message  :=  null;
            p_return_message  :=  p_return_message  ||  'Execution Started ';

----        Initialize the Dr and Cr Account id on Base transactions if, they are missing.
            v_accrual_account_id                :=  null;
            v_creditors_account_id              :=  null;
            v_ppv_id                            :=  null;
            v_receiving_inspection_acct_id      :=  null;
            v_inventory_acct_id                 :=  null;
            d_accrual_account_id                :=  null;
            d_creditors_account_id              :=  null;
            d_ppv_id                            :=  null;
            d_receiving_inspection_acct_id      :=  null;
            d_inventory_acct_id                 :=  null;
            v_dr_account_id                     :=  null;
            v_cr_account_id                     :=  null;
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
                      SELECT  receiving_inspection_acct_id,
                              ap_accrual_acct_id,
                              vendor_liability_acct_id,
                              sub_inventory_acct_id,
                              ppv_acct_id
                      INTO    d_receiving_inspection_acct_id,
                              d_accrual_account_id,
                              d_creditors_account_id,
                              d_inventory_acct_id,
                              d_ppv_id
                      FROM    cmn_transaction_types_v
                      WHERE   1                       = 1
                      AND     trim(upper(transaction_type_code))  = 'DEFAULT_ACCOUNT_CODES'
                      AND     client_id               = p_client_id;
            EXCEPTION 
            WHEN      OTHERS
            THEN              d_receiving_inspection_acct_id  :=  null;
                              d_accrual_account_id            :=  null;
                              d_creditors_account_id          :=  null;
                              d_inventory_acct_id             :=  null;
                              d_ppv_id                        :=  null;
            END;
----        Start Processing GRR Receipt Transactions
            for   set_jv_headers   in  get_jv_headers
            loop

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
                            p_return_message  :=  p_return_message || 'Record Can not create in FINS_GL_JVHEADERS - '||set_jv_headers.jv_name||'-'||SQLERRM;
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

----              We will create the Accounting Lines in a loop
                  for   set_jv_lines  in  get_jv_lines
                                      ( set_jv_headers.feed_trx_document_id,
                                        set_jv_headers.profit_centre_id,
                                        set_jv_headers.lob_id,
                                        set_jv_headers.organization_id,
                                        set_jv_headers.client_id
                                      )
                  loop
----                    Create Lines based on imr_receipt_lines
                        v_accrual_account_id                :=  d_accrual_account_id;
                        v_creditors_account_id              :=  d_creditors_account_id;
                        v_ppv_id                            :=  d_ppv_id;
                        v_receiving_inspection_acct_id      :=  d_receiving_inspection_acct_id;
                        v_inventory_acct_id                 :=  d_inventory_acct_id;

                        v_dr_account_id                     :=  null;
                        v_cr_account_id                     :=  null;

                        v_dr_ccid                           :=  null;
                        v_cr_ccid                           :=  null;
                        v_dr_amount                         :=  null;
                        v_cr_amount                         :=  null;
                        v_accounted_dr_amount               :=  null;
                        v_accounted_cr_amount               :=  null;

                        if    (set_jv_lines.dr_account_id is not null)
                        then  v_dr_account_id               :=  set_jv_lines.dr_account_id;
                        else  v_dr_account_id               :=  d_receiving_inspection_acct_id;
                        end   if;

                        if    (set_jv_lines.cr_account_id is not null)
                        then  v_cr_account_id               :=  set_jv_lines.cr_account_id;
                        else  v_cr_account_id               :=  d_accrual_account_id;
                        end   if;

----                    get DR ccid
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
                        THEN        p_return_code     :=  1;
                                    p_return_message  :=  p_return_message || 'DR Code Combination ID Can not be built for  - '||set_jv_lines.dr_account_id||' - '||set_jv_headers.feed_trx_document_id||SQLERRM;
                                    RAISE  some_error;
                                    rollback;
                                    RETURN;
                        END;

----                    get CR ccid
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
                        THEN        p_return_code     :=  1;
                                    p_return_message  :=  p_return_message || 'CR Code Combination ID Can not be built for  - '||set_jv_lines.dr_account_id||' - '||SQLERRM;
                                    RAISE  some_error;
                                    rollback;
                                    RETURN;
                        END;

----                    First Generate Debit and Credit Lines for GRR Line
----                    Debit Record First - Debit the Receiving Inspection
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
                              v_dr_ccid,

                              set_jv_lines.entered_dr,
                              null, ----  set_jv_headers.entered_cr,

                              set_jv_lines.TR_entered_dr,
                              null, ----  set_jv_headers.entered_cr,

                              set_jv_lines.AR_entered_dr,
                              null, ----  set_jv_headers.entered_cr,

                              set_jv_lines.SR_entered_dr,
                              null, ----  set_jv_headers.entered_cr,

                              set_jv_lines.exchange_rate,
                              set_jv_lines.exchange_date,

                              set_jv_lines.accounted_dr,
                              null, ----  set_jv_headers.accounted_cr,

                              set_jv_lines.TR_accounted_dr,
                              null, ----  set_jv_headers.accounted_cr,

                              set_jv_lines.AR_accounted_dr,
                              null, ----  set_jv_headers.accounted_cr,

                              set_jv_lines.SR_accounted_dr,
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
                                  p_return_message  :=  p_return_message || 'DR JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||'-'||SQLERRM;
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
----                    Credit Record nex - credit the AP Accrual
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
                              v_cr_ccid,

                              null, ----  set_jv_lines.entered_dr,
                              set_jv_lines.entered_cr, 

                              null, ----  set_jv_lines.entered_dr,
                              set_jv_lines.TR_entered_cr, 

                              null, ----  set_jv_lines.entered_dr,
                              set_jv_lines.AR_entered_cr, 

                              null, ----  set_jv_lines.entered_dr,
                              set_jv_lines.SR_entered_cr, 

                              set_jv_lines.exchange_rate,
                              set_jv_lines.exchange_date,

                              null, ----  set_jv_lines.accounted_dr,
                              set_jv_lines.accounted_cr, ----  set_jv_headers.accounted_cr,

                              null, ----  set_jv_lines.accounted_dr,
                              set_jv_lines.TR_accounted_cr, ----  set_jv_headers.accounted_cr,

                              null, ----  set_jv_lines.accounted_dr,
                              set_jv_lines.AR_accounted_cr, ----  set_jv_headers.accounted_cr,

                              null, ----  set_jv_lines.accounted_dr,
                              set_jv_lines.SR_accounted_cr, ----  set_jv_headers.accounted_cr,

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
                                  p_return_message  :=  p_return_message || 'CR JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||'-'||SQLERRM;
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

----                    Write Back and Update fins_ap_transactions and transaction_lines tables
                        BEGIN
                                update  imr_receipt_lines
                                set     receipt_accounted_flag        = 'Y',
                                        receipt_accounting_date       = to_date(set_jv_headers.sla_accounting_date,'DD-MON-YYYY'),
                                        receipt_accounting_event_id   = v_jv_header_id,
                                        receipt_accounting_header_id  = v_jv_header_id,
                                        receipt_eligible_to_accounting= 'N',
                                        status_id                     = 10065,
                                        status_date                   = sysdate
                                where   1                             = 1
                                AND     status_id                not in (10006,10007)
                                and     receipt_line_id               = set_jv_lines.receipt_line_id
                                and     receipt_header_id             = set_jv_headers.feed_trx_document_id
                                and     vendor_party_id               = set_jv_headers.vendor_party_id
                                and     client_id                     = set_jv_headers.client_id;
                        EXCEPTION
                        WHEN    OTHERS
                        THEN    p_return_code     :=  2;
                                p_return_message  :=  p_return_message ||  ' - '  ||
                                                      'Can not write back on imr_receipt_lines for - '||set_jv_lines.receipt_line_id||' - '||SQLERRM;
                        END;
                        commit;

----                    Write Back and Update fins_ap_transactions and transaction_lines tables
                        BEGIN
                                update  fins_ap_transaction_lines
                                set     sla_accounting_flag   = 'Y',
                                        sla_accounting_date   = to_date(set_jv_headers.sla_accounting_date,'DD-MON-YYYY'),
                                        sla_jv_name           = set_jv_headers.jv_name,
                                        sla_header_id         = v_jv_header_id,
                                        eligible_to_accounting= 'N',
                                        status_id             = 10065,
                                        status_date           = sysdate
                                where   1                     = 1
                                AND     status_id                   not in (10006,10007)
                                and     ap_trx_line_id        = set_jv_lines.ap_trx_line_id
                                and     ap_trx_id             = set_jv_lines.ap_trx_id
                                and     client_id             = set_jv_lines.client_id;
                        EXCEPTION
                        WHEN    OTHERS
                        THEN    p_return_code     :=  2;
                                p_return_message  :=  p_return_message ||  ' - '  ||
                                                      'Can not write back on fins_ap_transaction_line for - '||set_jv_lines.receipt_line_id||' - '||SQLERRM;
                        END; 
                        commit;

----                    Now Generate Accounting Records for Associated Tax Records of the base transaction. First Dr Record

                        ----  Tax Lines for Debit Entries
                        for   set_tax   in  get_trx_tax_lines
                                            ( set_jv_lines.receipt_line_id,
                                              set_jv_headers.feed_trx_document_id,
                                              set_jv_headers.profit_centre_id,
                                              set_jv_headers.lob_id,
                                              set_jv_headers.organization_id,
                                              set_jv_headers.client_id
                                            )
                        loop
                        ----  Tax Debit Entry
                              v_ccid            :=  null;
                              v_ccid            :=  get_code_combination_id
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            set_tax.dr_account_id
                                                    );

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
                                  insert into /*+ PARALLEL (fins_gl_jv_lines, 4) */
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
                                    set_jv_lines.client_id,
                                    v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                                    set_jv_headers.jv_effective_date,
                                    set_jv_headers.period_id,
                                    set_jv_headers.period_name,
                                    set_jv_headers.jv_name,
                                    set_jv_lines.description,
                                    set_tax.jv_line_type,
                                    v_ccid,

                                    set_tax.dr_amount,
                                    null,   ----  set_tax.cr_amount,

                                    set_tax.TR_dr_amount,
                                    null,   ----  set_tax.cr_amount,

                                    set_tax.AR_dr_amount,
                                    null,   ----  set_tax.cr_amount,

                                    set_tax.SR_dr_amount,
                                    null,   ----  set_tax.cr_amount,

                                    set_jv_lines.exchange_rate,
                                    set_jv_lines.exchange_date,

                                    set_tax.dr_amount,          ----  Dr Amount
                                    null,                       ----  Cr Amount,

                                    set_tax.TR_dr_amount,          ----  Dr Amount
                                    null,                       ----  Cr Amount,

                                    set_tax.AR_dr_amount,          ----  Dr Amount
                                    null,                       ----  Cr Amount,

                                    set_tax.SR_dr_amount,          ----  Dr Amount
                                    null,                       ----  Cr Amount,

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
                                        p_return_message  :=  p_return_message || 'Tax Dr JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||SQLERRM;
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
                              dbms_output.put_line ('GRR Tax Deebit Accounting for Transaction Line '||set_jv_lines.receipt_line_id||' Generated Successfully...'||v_ccid||' - Tax Amount - '||set_tax.TR_dr_amount);

                        ----  Tax Debit Entry
                              v_ccid            :=  null;
                              v_ccid            :=  get_code_combination_id
                                                    (       set_jv_headers.client_id,
                                                            set_jv_headers.organization_id,
                                                            set_jv_headers.lob_id,
                                                            set_jv_headers.profit_centre_id,
                                                            set_tax.cr_account_id
                                                    );

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
                                  insert into /*+ PARALLEL (fins_gl_jv_lines, 4) */
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
                                    set_jv_lines.client_id,
                                    v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                                    set_jv_headers.jv_effective_date,
                                    set_jv_headers.period_id,
                                    set_jv_headers.period_name,
                                    set_jv_headers.jv_name,
                                    set_jv_lines.description,
                                    set_tax.jv_line_type,
                                    v_ccid,

                                    null,                       ----  Dr Amount
                                    set_tax.cr_amount,          ----  Cr Amount,

                                    null,                       ----  Dr Amount
                                    set_tax.TR_cr_amount,          ----  Cr Amount,

                                    null,                       ----  Dr Amount
                                    set_tax.AR_cr_amount,          ----  Cr Amount,

                                    null,                       ----  Dr Amount
                                    set_tax.SR_cr_amount,          ----  Cr Amount,

                                    set_jv_lines.exchange_rate,
                                    set_jv_lines.exchange_date,

                                    null,                       ----  Dr Amount
                                    set_tax.cr_amount,          ----  Cr Amount,

                                    null,                       ----  Dr Amount
                                    set_tax.TR_cr_amount,          ----  Cr Amount,

                                    null,                       ----  Dr Amount
                                    set_tax.AR_cr_amount,          ----  Cr Amount,

                                    null,                       ----  Dr Amount
                                    set_tax.SR_cr_amount,          ----  Cr Amount,

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
                                        p_return_message  :=  p_return_message || 'Tax Cr JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||SQLERRM;
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
                              dbms_output.put_line ('GRR Tax Credit Accounting for Transaction Line '||set_jv_lines.receipt_line_id||' Generated Successfully...'||v_ccid||' - Tax Amount - '||set_tax.TR_dr_amount);
                        end loop;       ---- end  Tax Loop
                  end   loop;         -----   end line    loop

----              Write Back and Update fins_ap_transactions and transaction_lines tables
                  BEGIN
                          update  imr_receipt_headers
                          set     receipt_accounted_flag        = 'Y',
                                  receipt_accounting_date       = to_date(set_jv_headers.sla_accounting_date,'DD-MON-YYYY'),
                                  receipt_accounting_event_id   = v_jv_header_id,
                                  receipt_accounting_header_id  = v_jv_header_id,
                                  receipt_eligible_to_accounting= 'N',
                                  status_id                     = 10065,
                                  status_date                   = sysdate
                          where   1                             = 1
                          AND     status_id                not in (10006,10007)
                          and     receipt_header_id             = set_jv_headers.feed_trx_document_id
                          and     vendor_party_id               = set_jv_headers.vendor_party_id
                          and     client_id                     = set_jv_headers.client_id;
                  EXCEPTION
                  WHEN    OTHERS
                  THEN    p_return_code     :=  2;
                          p_return_message  :=  p_return_message ||  ' - '  ||
                                                'Can not write back on fins_ap_transaction_line for - '||SQLERRM;
                  END;
                  commit;

                  BEGIN
                          update  fins_ap_transactions
                          set     sla_accounting_flag   = 'Y',
                                  sla_accounting_date   = to_date(set_jv_headers.sla_accounting_date,'DD-MON-YYYY'),
                                  sla_jv_name           = set_jv_headers.jv_name,
                                  sla_header_id         = v_jv_header_id,
                                  eligible_to_accounting= 'N',
                                  status_id             = 10065,
                                  status_date           = sysdate
                          where   1                     = 1
                          AND     status_id                   not in (10006,10007)
                          and     ap_trx_id             = set_jv_headers.ap_trx_id
                          and     client_id             = set_jv_headers.client_id;
                  EXCEPTION
                  WHEN    OTHERS
                  THEN    p_return_code     :=  2;
                          p_return_message  :=  p_return_message ||  ' - '  ||
                                                'Can not write back on fins_ap_transaction_line for - '||SQLERRM;
                  END;
                  commit; 

            end   loop;         -----   end header  loop
            commit;

            p_return_code     :=  0;
            p_return_message  :=  'GRR Accounting for Transaction/s '||p_receipt_header_id||' Generated Successfully...';
            dbms_output.put_line (p_return_message);
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
END         fins_inventory_grr_receipt_accounting_api;
---------------------------------------------------------------------------------------------------------------------------------
