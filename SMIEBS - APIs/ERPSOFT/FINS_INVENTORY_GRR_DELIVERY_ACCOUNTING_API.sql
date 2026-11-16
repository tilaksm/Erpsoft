--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Generate Accounting for GRR Delivery Transactions
----      These include, Invoices, Credit Notes, Debit Notes which are manualy created.
--- -     Written by    : Shriniwas Tilak.
-----     Date Written  : 03rd April 2024
-----     Modified V1   : 
-----     V1 Modified on: 
--------------------------------------------------------------------------------------------------------------------------------------------------
----      This API Generates Accounting transactions for the Delivery of the GRR To Stores. 
----      1.  It creates a record into Accounting Event, Accounting Headers and Accounting Lines of SLA.
----      2.  Difference between the standard value of the delivery transaction and Base value of the GRR
----          is posted to the PPV Account either as debit transaction or Credit transaction. 
----      3.  If the base value is greater than the standard value, then PPV is debited, other wise PPV is credited.
--------------------------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE "FINS_INVENTORY_GRR_DELIVERY_ACCOUNTING_API" 
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
        v_ppv_ccid                          number            :=  null;
        v_dr_amount                         number            :=  null;
        v_cr_amount                         number            :=  null;
        v_transacion_value                  number            :=  null;
        v_standard_value                    number            :=  null;
        v_average_value                     number            :=  null;
        v_ppv_amount                        number            :=  null;
        v_ppv_amount_standard               number            :=  null;
        v_ppv_amount_average                number            :=  null;
        v_accounted_dr_amount               number            :=  null;
        v_accounted_cr_amount               number            :=  null;
        v_accounting_amount                 number            :=  null;
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
                              and     sub_category_code     = 'GRR-DELIVERY'
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
                            irh.receipt_header_id                     receipt_header_id,
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
                            'GRR DELIVERY - '  || irh.receipt_number  jv_name,
                            'GRR Delivery transaction for Supplier Bill ID - ' ||
                            irh.ap_trx_id               || ' - '  ||
                            'Supplier Bill Number - '             ||
                            irh.supplier_invoice_number               description,
                            round(nvl(irh.line_taxable_amount,0),2)   line_taxable_amount,
                            round(nvl(irh.line_taxable_amount,0),2)   sla_header_amount,
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
                            irh.supplier_invoice_date                 feed_trx_date,
                            'IMR_RECEIPT_HEADERS'                     feed_transaction_table_name,
                            irh.ap_trx_id                             ap_trx_id,
                            ( select  party_combination_id
                              from    cmn_vendor_master_v             ccmv
                              where   1                             = 1
                              and     ccmv.party_id                 = irh.vendor_party_id
                              and     ccmv.client_id                = irh.client_id
                            )                                         party_combination_id,
                            irh.vendor_party_id                       party_id,
                            irh.vendor_party_id                       vendor_party_id,
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
                            irh.ap_trx_id                             gl_sl_link_id,
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
                              from    fins_gl_jv_headers_v           sae
                              where   1                             = 1
                              and     sae.jv_sub_category_code      = upper('GRR-DELIVERY')
                              and     sae.feed_trx_application_id   = 801
                              and     sae.feed_trx_document_type_id = irh.type_code_id
                              and     sae.feed_trx_document_id      = irh.receipt_header_id
                            )
----                    AND     round(nvl(irh.line_taxable_amount,0),2) <>  0
                    AND     nvl(irh.DELIVERY_ELIGIBLE_TO_ACCOUNTING,'Y')  = 'Y'
                    AND     irh.DELIVERY_ACCOUNTED_FLAG            is null
                    AND     irh.DELIVERY_ACCOUNTING_DATE           is null
                    AND     irh.DELIVERY_ACCOUNTING_EVENT_ID       is null
                    AND     irh.DELIVERY_ACCOUNTING_HEADER_ID      is null
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

            CURSOR  get_transaction_lines 
                    ( c_receipt_header_id number,
                      c_profit_centre_id  number,
                      c_lob_id            number,
                      c_organization_id   number,
                      c_client_id         number
                    )
            IS
                    SELECT  /*+ PARALLEL (imr_receipt_lines, 4) PARALLEL (imr_receipt_headers,4 )*/
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
                              and     ccm.client_id         = irh.client_id
                            )                                         accounting_method,
                            irh.receipt_header_id                     receipt_header_id,
                            irl.receipt_line_id                       receipt_line_id,
                            'ITEM'                                    jv_line_type,
                            'Delivery Accounting for GRR - ' ||  
                            irh.receipt_number                        description,
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
                            irl.primary_quantity_delivered            quantity_dr,
                            null                                      quantity_cr,
                            round(irl.line_base_amount,2)             trx_line_amount,
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
                            ( select  round ( nvl(cim.standard_cost,0)  *
                                              nvl(irl.quantity_delivered,0),2
                                            )
                              from    cmn_item_master_v               cim
                              where   1                             = 1
                              and     cim.inventory_item_id         = irl.inventory_item_id
                              and     cim.profit_centre_id          = irl.profit_centre_id
                              and     cim.lob_id                    = irl.lob_id
                              and     cim.organization_id           = irl.organization_id
                              and     cim.client_id                 = irl.client_id
                            )                                         standard_value,
                            ( select  round ( nvl(cim.weighted_average_rate,0)  *
                                              nvl(irl.quantity_delivered,0),2
                                            )
                              from    cmn_item_master_v               cim
                              where   1                             = 1
                              and     cim.inventory_item_id         = irl.inventory_item_id
                              and     cim.profit_centre_id          = irl.profit_centre_id
                              and     cim.lob_id                    = irl.lob_id
                              and     cim.organization_id           = irl.organization_id
                              and     cim.client_id                 = irl.client_id
                            )                                         average_value,
                            round(irl.line_base_amount,2)             actual_amount,
                            round(irl.line_base_amount,2)             transaction_amount,
                            irh.vendor_liability_account_id           vendor_liability_account_id,
                            irh.recieving_inspection_account_id       cr_account_id,
                            ( select  default_stock_acct_id
                              from    cmn_item_master_v               cim
                              where   1                             = 1
                              and     cim.inventory_item_id         = irl.inventory_item_id
                              and     cim.profit_centre_id          = irl.profit_centre_id
                              and     cim.lob_id                    = irl.lob_id
                              and     cim.organization_id           = irl.organization_id
                              and     cim.client_id                 = irl.client_id
                            )                                         stock_account_id,
                            'IMR_RECEIPT_LINES'                       gl_sl_link_table,
                            irl.receipt_line_id                       gl_sl_link_id,
                            round(nvl(irl.line_base_amount,0),2)      TR_entered_dr,
                            round(nvl(irl.line_base_amount,0),2)      TR_entered_cr,
                            nvl(irh.currency_code,'INR')              currency_code,
                            nvl(irh.conversion_rate,1)                exchange_rate,
                            nvl(irh.conversion_date,sysdate)          exchange_date,
                            round ( round(nvl(irl.line_base_amount,0),2)  *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   actual_accounted_dr,
                            round ( round(nvl(irl.line_base_amount,0),2)  *
                                    nvl(irh.conversion_rate,1),2
                                  )                                   actual_accounted_cr,
                            irl.ap_trx_id                             ap_trx_id,
                            irl.ap_trx_line_id                        ap_trx_line_id
                    FROM    imr_receipt_lines                         irl,
                            imr_receipt_headers                       irh
                    WHERE   1                                       = 1
                    AND     nvl(irl.DELIVERY_ELIGIBLE_TO_ACCOUNTING,'Y')  = 'Y'
                    AND     irl.DELIVERY_ACCOUNTED_FLAG            is null
                    AND     irl.DELIVERY_ACCOUNTING_DATE           is null
                    AND     irl.DELIVERY_ACCOUNTING_EVENT_ID       is null
                    AND     irl.DELIVERY_ACCOUNTING_HEADER_ID      is null
                    AND     irl.status_id                   not in (10006,10007)
                    AND     irl.receipt_header_id                   = irh.receipt_header_id
                    AND     irl.client_id                           = irh.client_id
                    AND     to_date(irh.receipt_date)              >= v_erp_financials_start_date
                    AND     irh.status_id                   not in (10006,10007)
                    AND     irh.receipt_header_id                   = c_receipt_header_id
                    AND     irh.profit_centre_id                    = c_profit_centre_id
                    AND     irh.lob_id                              = c_lob_id
                    AND     irh.organization_id                     = c_organization_id
                    AND     irh.client_id                           = c_client_id;

----        Main Process for Generate Transactions Accounting Starts Here.
BEGIN
----        Initially, we check for the existing accounting transactions which are not transferred to GL. 
----        If they do exist and they are not transferred to GL, we delete the same.
----        Deletion would tak place in all the threee tables namely events, headrs and lines.
----        First We will create the Accounting Events in a loop
            dbms_output.put_line ('Execution Started for Accounting of GRR Delivery Transactions...');
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
                            p_return_message  :=  p_return_message || 'Record Can not create in FINS_GL_JVHEADERS - '||set_jv_headers.jv_name||SQLERRM;
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
                  for   set_jv_line in  get_transaction_lines
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

                        v_dr_account_id                     :=  d_inventory_acct_id;
                        v_cr_account_id                     :=  d_receiving_inspection_acct_id;

                        v_dr_ccid                           :=  null;
                        v_cr_ccid                           :=  null;
                        v_ppv_ccid                          :=  null;
                        v_dr_amount                         :=  null;
                        v_cr_amount                         :=  null;

                        IF    (set_jv_line.accounting_method  = 'ACTUAL')
                        THEN  v_dr_amount                   :=  round(set_jv_line.trx_line_amount,2);
                              v_cr_amount                   :=  round(set_jv_line.trx_line_amount,2);
                              v_ppv_amount                  :=  0;
                        END   IF;

                        IF    (set_jv_line.accounting_method  = 'TRANSACTION')
                        THEN  v_dr_amount                   :=  round(set_jv_line.trx_line_amount,2);
                              v_cr_amount                   :=  round(set_jv_line.trx_line_amount,2);
                              v_ppv_amount                  :=  0;
                        END   IF;

                        IF    (set_jv_line.accounting_method  = 'AVERAGE')
                        THEN  v_dr_amount                   :=  round(set_jv_line.average_value,2);
                              v_cr_amount                   :=  round(set_jv_line.trx_line_amount,2);
                              v_ppv_amount                  :=  abs(round(set_jv_line.average_value,2)-round(set_jv_line.trx_line_amount,2));
                        END   IF;

                        IF    (set_jv_line.accounting_method  = 'STANDARD')
                        THEN  v_dr_amount                   :=  round(set_jv_line.standard_value,2);
                              v_cr_amount                   :=  round(set_jv_line.trx_line_amount,2);
                              v_ppv_amount                  :=  abs(round(set_jv_line.standard_value,2)-round(set_jv_line.trx_line_amount,2));
                        END   IF;

                        v_ppv_amount_standard               :=  abs(round(set_jv_line.standard_value,2)-round(set_jv_line.trx_line_amount,2));
                        v_ppv_amount_average                :=  abs(round(set_jv_line.average_value,2)-round(set_jv_line.trx_line_amount,2));

                        v_accounted_dr_amount               :=  v_dr_amount;
                        v_accounted_cr_amount               :=  v_cr_amount;

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
                                    p_return_message  :=  p_return_message || 'DR Code Combination ID Can not be built for  - '||v_dr_account_id||' - '||set_jv_headers.feed_trx_document_id||SQLERRM;
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
                                    p_return_message  :=  p_return_message || 'CR Code Combination ID Can not be built for  - '||v_cr_account_id||' - '||SQLERRM;
                                    RAISE  some_error;
                                    rollback;
                                    RETURN;
                        END;

----                    get PPV ccid
                        BEGIN
                                    select  code_combination_id
                                    into    v_ppv_ccid
                                    from    cmn_account_code_combinations_v   cacc
                                    where   1                     = 1
                                    and     cacc.account_code_id  = v_ppv_id
                                    and     cacc.profit_centre_id = set_jv_headers.profit_centre_id
                                    and     cacc.lob_id           = set_jv_headers.lob_id
                                    and     cacc.organization_id  = set_jv_headers.organization_id
                                    and     cacc.client_id        = set_jv_headers.client_id;
                        EXCEPTION
                        WHEN        OTHERS
                        THEN        p_return_code     :=  1;
                                    p_return_message  :=  p_return_message || 'PPV Code Combination ID Can not be built for  - '||v_ppv_ccid||' - '||set_jv_headers.feed_trx_document_id||SQLERRM;
                                    RAISE  some_error;
                                    rollback;
                                    RETURN;
                        END;

----                    First Generate Debit and Credit Lines for GRR Line
----                    Debit Record First - Debit the Inventory

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
                              quantity_dr,
                              quantity_cr,
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
                              set_jv_line.client_id,
                              v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                              set_jv_headers.jv_effective_date,
                              set_jv_headers.period_id,
                              set_jv_headers.period_name,
                              set_jv_headers.jv_name,
                              set_jv_line.description,
                              set_jv_line.jv_line_type,
                              v_dr_ccid,

                              v_dr_amount,
                              null, ----  set_jv_headers.entered_cr,

                              v_dr_amount,
                              null, ----  set_jv_headers.entered_cr,

                              v_dr_amount,
                              null, ----  set_jv_headers.entered_cr,

                              v_dr_amount,
                              null, ----  set_jv_headers.entered_cr,
                              set_jv_line.exchange_rate,
                              set_jv_line.exchange_date,

                              v_accounted_dr_amount,
                              null, ----  set_jv_headers.accounted_cr,

                              v_accounted_dr_amount,
                              null, ----  set_jv_headers.accounted_cr,

                              v_accounted_dr_amount,
                              null, ----  set_jv_headers.accounted_cr,

                              v_accounted_dr_amount,
                              null, ----  set_jv_headers.accounted_cr,

                              set_jv_line.quantity_dr,
                              set_jv_line.quantity_cr,
                              set_jv_headers.actual_flag,
                              set_jv_headers.posted_date,
                              set_jv_headers.posted_flag,
                              set_jv_headers.posting_error,
                              set_jv_headers.reference_1,
                              set_jv_headers.reference_2,
                              set_jv_headers.reference_3,
                              set_jv_headers.reference_4,
                              set_jv_headers.reference_5,
                              set_jv_line.party_combination_id,
                              set_jv_line.party_id,
                              set_jv_line.inventory_item_id,
      ----                    GL JV Organization Information
                              set_jv_headers.profit_centre_id,
                              set_jv_headers.lob_id,
                              set_jv_headers.organization_id,
      ----                    GL / SL Linking Identificaiton and Information
                              set_jv_line.gl_sl_link_id,
                              set_jv_line.gl_sl_link_table,
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
                              set_jv_line.feed_trx_document_line_id,
                              set_jv_headers.feed_trx_number,
                              set_jv_headers.feed_trx_date,
                              set_jv_headers.feed_transaction_table_name
                            );
                            commit;
                        EXCEPTION
                        WHEN      OTHERS
                        THEN      p_return_code     :=  2;
                                  p_return_message  :=  p_return_message || 'DR JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||SQLERRM;
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
----                    Debit Record First - Debit the Inventory

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
                              quantity_dr,
                              quantity_cr,
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
                              set_jv_line.client_id,
                              v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                              set_jv_headers.jv_effective_date,
                              set_jv_headers.period_id,
                              set_jv_headers.period_name,
                              set_jv_headers.jv_name,
                              set_jv_line.description,
                              set_jv_line.jv_line_type,
                              v_cr_ccid,

                              null,         ----  entered dr,
                              v_cr_amount,  ----  set_jv_headers.entered_cr,

                              null,         ----  entered dr,
                              v_cr_amount,  ----  set_jv_headers.entered_cr,

                              null,         ----  entered dr,
                              v_cr_amount,  ----  set_jv_headers.entered_cr,

                              null,         ----  entered dr,
                              v_cr_amount,  ----  set_jv_headers.entered_cr,

                              set_jv_line.exchange_rate,
                              set_jv_line.exchange_date,

                              null,         ----  v_accounted_dr_amount,
                              v_accounted_cr_amount, ----  set_jv_headers.accounted_cr,

                              null,         ----  v_accounted_dr_amount,
                              v_accounted_cr_amount, ----  set_jv_headers.accounted_cr,

                              null,         ----  v_accounted_dr_amount,
                              v_accounted_cr_amount, ----  set_jv_headers.accounted_cr,

                              null,         ----  v_accounted_dr_amount,
                              v_accounted_cr_amount, ----  set_jv_headers.accounted_cr,

                              set_jv_line.quantity_dr,
                              set_jv_line.quantity_cr,
                              set_jv_headers.actual_flag,
                              set_jv_headers.posted_date,
                              set_jv_headers.posted_flag,
                              set_jv_headers.posting_error,
                              set_jv_headers.reference_1,
                              set_jv_headers.reference_2,
                              set_jv_headers.reference_3,
                              set_jv_headers.reference_4,
                              set_jv_headers.reference_5,
                              set_jv_line.party_combination_id,
                              set_jv_line.party_id,
                              set_jv_line.inventory_item_id,
      ----                    GL JV Organization Information
                              set_jv_headers.profit_centre_id,
                              set_jv_headers.lob_id,
                              set_jv_headers.organization_id,
      ----                    GL / SL Linking Identificaiton and Information
                              set_jv_line.gl_sl_link_id,
                              set_jv_line.gl_sl_link_table,
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
                              set_jv_line.feed_trx_document_line_id,
                              set_jv_headers.feed_trx_number,
                              set_jv_headers.feed_trx_date,
                              set_jv_headers.feed_transaction_table_name
                            );
                            commit;
                        EXCEPTION
                        WHEN      OTHERS
                        THEN      p_return_code     :=  2;
                                  p_return_message  :=  p_return_message || 'CR JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||SQLERRM;
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

                        IF    ( set_jv_headers.accounting_method in ('STANDARD','AVERAGE'))
                        THEN
      ----                    Post PPV amount
                              if    ( (set_jv_line.trx_line_amount > set_jv_line.standard_value)
                                      or
                                      (set_jv_line.trx_line_amount > set_jv_line.average_value)
                                    )
                              then
            ----                    Debit Entry for the PPV 
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
                                          quantity_dr,
                                          quantity_cr,
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
                                          set_jv_line.client_id,
                                          v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                                          set_jv_headers.jv_effective_date,
                                          set_jv_headers.period_id,
                                          set_jv_headers.period_name,
                                          set_jv_headers.jv_name,
                                          set_jv_line.description,
                                          set_jv_line.jv_line_type,
                                          v_ppv_ccid,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.entered_cr,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.entered_cr,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.entered_cr,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.entered_cr,

                                          set_jv_line.exchange_rate,
                                          set_jv_line.exchange_date,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.accounted_cr,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.accounted_cr,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.accounted_cr,

                                          v_ppv_amount,
                                          null, ----  set_jv_headers.accounted_cr,

                                          set_jv_line.quantity_dr,
                                          set_jv_line.quantity_cr,
                                          set_jv_headers.actual_flag,
                                          set_jv_headers.posted_date,
                                          set_jv_headers.posted_flag,
                                          set_jv_headers.posting_error,
                                          set_jv_headers.reference_1,
                                          set_jv_headers.reference_2,
                                          set_jv_headers.reference_3,
                                          set_jv_headers.reference_4,
                                          set_jv_headers.reference_5,
                                          set_jv_line.party_combination_id,
                                          set_jv_line.party_id,
                                          set_jv_line.inventory_item_id,
                  ----                    GL JV Organization Information
                                          set_jv_headers.profit_centre_id,
                                          set_jv_headers.lob_id,
                                          set_jv_headers.organization_id,
                  ----                    GL / SL Linking Identificaiton and Information
                                          set_jv_line.gl_sl_link_id,
                                          set_jv_line.gl_sl_link_table,
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
                                          set_jv_line.feed_trx_document_line_id,
                                          set_jv_headers.feed_trx_number,
                                          set_jv_headers.feed_trx_date,
                                          set_jv_headers.feed_transaction_table_name
                                        );
                                        commit;
                                    EXCEPTION
                                    WHEN      OTHERS
                                    THEN      p_return_code     :=  2;
                                              p_return_message  :=  p_return_message || 'DR JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||SQLERRM;
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
                              ELSE  ---- Else path of PPV value check
            ----                    Credit Entry for the PPV 
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
                                          quantity_dr,
                                          quantity_cr,
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
                                          set_jv_line.client_id,
                                          v_jv_line_id,  ---- set_jv_headers.jv_line_number,
                                          set_jv_headers.jv_effective_date,
                                          set_jv_headers.period_id,
                                          set_jv_headers.period_name,
                                          set_jv_headers.jv_name,
                                          set_jv_line.description,
                                          set_jv_line.jv_line_type,
                                          v_ppv_ccid,

                                          null,                   ----  debit Amount
                                          round(v_ppv_amount,2),  ----  set_jv_headers.entered_cr,

                                          null,                   ----  debit Amount
                                          round(v_ppv_amount,2),  ----  set_jv_headers.entered_cr,

                                          null,                   ----  debit Amount
                                          round(v_ppv_amount,2),  ----  set_jv_headers.entered_cr,

                                          null,                   ----  debit Amount
                                          round(v_ppv_amount,2),  ----  set_jv_headers.entered_cr,

                                          set_jv_line.exchange_rate,
                                          set_jv_line.exchange_date,

                                          null,                   ----  debit Amount round(v_ppv_amount,2),
                                          round(v_ppv_amount,2),  ----  set_jv_headers.accounted_cr,

                                          null,                   ----  debit Amount round(v_ppv_amount,2),
                                          round(v_ppv_amount,2),  ----  set_jv_headers.accounted_cr,

                                          null,                   ----  debit Amount round(v_ppv_amount,2),
                                          round(v_ppv_amount,2),  ----  set_jv_headers.accounted_cr,

                                          null,                   ----  debit Amount round(v_ppv_amount,2),
                                          round(v_ppv_amount,2),  ----  set_jv_headers.accounted_cr,

                                          set_jv_line.quantity_dr,
                                          set_jv_line.quantity_cr,
                                          set_jv_headers.actual_flag,
                                          set_jv_headers.posted_date,
                                          set_jv_headers.posted_flag,
                                          set_jv_headers.posting_error,
                                          set_jv_headers.reference_1,
                                          set_jv_headers.reference_2,
                                          set_jv_headers.reference_3,
                                          set_jv_headers.reference_4,
                                          set_jv_headers.reference_5,
                                          set_jv_line.party_combination_id,
                                          set_jv_line.party_id,
                                          set_jv_line.inventory_item_id,
                  ----                    GL JV Organization Information
                                          set_jv_headers.profit_centre_id,
                                          set_jv_headers.lob_id,
                                          set_jv_headers.organization_id,
                  ----                    GL / SL Linking Identificaiton and Information
                                          set_jv_line.gl_sl_link_id,
                                          set_jv_line.gl_sl_link_table,
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
                                          set_jv_line.feed_trx_document_line_id,
                                          set_jv_headers.feed_trx_number,
                                          set_jv_headers.feed_trx_date,
                                          set_jv_headers.feed_transaction_table_name
                                        );
                                        commit;
                                    EXCEPTION
                                    WHEN      OTHERS
                                    THEN      p_return_code     :=  2;
                                              p_return_message  :=  p_return_message || 'PPV CR JV Line Record Can not created in FINS_GL_JV_LINES - '||set_jv_headers.jv_name||SQLERRM;
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
                              END   IF;    ---  PPV Value Check
                        END   IF;     ----  STANDARD/AVERAGE Check
                        commit;
----                    Write Back Lines
                        begin
                                    update  imr_receipt_lines
                                    set     delivery_eligible_to_accounting =  'N',
                                            delivery_accounted_flag         =  'Y',
                                            delivery_accounting_date        =  set_jv_headers.jv_effective_Date,
                                            delivery_accounting_event_id    =  v_jv_header_id,
                                            delivery_accounting_header_id   =  v_jv_header_id,
                                            delivery_accounting_line_id     =  v_jv_line_id,
                                            last_update_date                =  sysdate,
                                            last_updated_by                 =  p_user_id
                                    where   1                               =  1
                                    and     receipt_line_id                 =  set_jv_line.receipt_line_id
                                    and     receipt_header_id               =  set_jv_line.receipt_header_id
                                    and     client_id                       =  set_jv_line.client_id;
                                    commit;
                        exception
                        when        others
                        then        p_return_code     :=  2;
                                    p_return_message  :=  p_return_message ||  ' - '  ||
                                                                      'IMR Receipt Headers not be Updated..';
                                    rollback;
                                    RAISE some_error;
                        end;
                  end   loop;         -----   end line    loop
----              Write Back Headers
                  begin
                              update  imr_receipt_headers
                              set     delivery_eligible_to_accounting =  'N',
                                      delivery_accounted_flag         =  'Y',
                                      delivery_accounting_date        =  set_jv_headers.jv_effective_Date,
                                      delivery_accounting_event_id    =  v_jv_header_id,
                                      delivery_accounting_header_id   =  v_jv_header_id,
                                      delivery_accounting_line_id     =  null,
                                      last_update_date                =  sysdate,
                                      last_updated_by                 =  p_user_id
                              where   1                               =  1
                              and     receipt_header_id               =  set_jv_headers.receipt_header_id
                              and     client_id                       =  set_jv_headers.client_id;
                              commit;
                  exception
                  when        others
                  then        p_return_code     :=  2;
                              p_return_message  :=  p_return_message ||  ' - '  ||
                                                                'IMR Receipt Headers not be Updated..';
                              rollback;
                              RAISE some_error;
                  end;
            end   loop;         -----   end header  loop
            commit;

            p_return_code     :=  0;
            p_return_message  :=  'GRR DELIVERY Accounting for Transaction/s '||p_receipt_header_id||' Generated Successfully...';
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
END         fins_inventory_grr_delivery_accounting_api;
---------------------------------------------------------------------------------------------------------------------------------
