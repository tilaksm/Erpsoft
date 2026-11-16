--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Convert Leads to Enquiries
--- -     Written by    : Manali Modak - Kulkarni
-----     Date Written  : 17th April 2021 
-----     Modified V1   : Modified to change the Header ID Criterion\
-----     V1 Modified on: 26th November 2022
---------------------------------------------------------------------------------------------------------------------------------
----      API to Convert Enquiries to Offers
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE CONVERT_CRM_LEAD_TO_ENQUIRY_API
    (   p_return_code           OUT     VARCHAR2,
        p_return_message        OUT     VARCHAR2,
        p_user_id               IN      NUMBER,
        p_client_id             IN      NUMBER, 
        p_lead_id               IN      NUMBER,
        p_requirement_id        IN OUT  NUMBER,
        p_requirement_number    OUT     VARCHAR2
    )
    AS

---     Declare Variables and Cursors required for generation
        err_message                             varchar2(200)   :=      null;
        exists_flag                             varchar2(01)    :=      null;
        dummy_flag                              varchar2(01)    :=      null;
        recs_added                              number          :=      0;

        Some_Error                              EXCEPTION;

-----   Define Header API Fields
        v_return_code                           VARCHAR2(01)    :=      null;
        v_return_message                        VARCHAR2(4000)  :=      null;
        v_action                                VARCHAR2(01)    :=      'I';
        v_user_id                               NUMBER          :=      null;
        v_start_date                            DATE            :=      sysdate;
        v_end_date                              DATE            :=      null;
        v_notification_id                       NUMBER          :=      null;
----    CRM Requirements Identification Information
        v_requirement_id                        NUMBER          :=      null;
        v_application_id                        NUMBER          :=      null;
        v_client_id                             NUMBER          :=      null;
        v_parent_requirement_id                 NUMBER          :=      null;
        v_requirement_number                    VARCHAR2(100)   :=      null;
        v_received_date                         DATE            :=      null;
        v_expiration_date                       DATE            :=      null;
        v_version_number                        NUMBER          :=      1;
        v_current_version_flag                  VARCHAR2(1)     :=      'Y';
----    CRM Requirements Classification
        v_req_created_by_party_id               NUMBER          :=      null;
        v_associated_call_id                    NUMBER          :=      null;
        v_associated_lead_id                    NUMBER          :=      null;
        v_associated_enquiry_id                 NUMBER          :=      null;
        v_associated_offer_id                   NUMBER          :=      null;
        v_req_type_set_id                       NUMBER          :=      null;
        v_req_type_code_id                      NUMBER          :=      null;
        v_req_class_set_id                      NUMBER          :=      null;
        v_req_class_code_id                     NUMBER          :=      null;
        v_ms_category_id                        NUMBER          :=      null;
        v_ms_sub_category_id                    NUMBER          :=      null;
        v_as_category_id                        NUMBER          :=      null;
        v_as_sub_category_id                    NUMBER          :=      null;
        v_transaction_type_id                   NUMBER          :=      null;
        v_plan_header_id                        NUMBER          :=      null;
        v_plan_detail_id                        NUMBER          :=      null;
        v_budget_id                             NUMBER          :=      null;
        v_budget_line_id                        NUMBER          :=      null;
        v_project_id                            NUMBER          :=      null;
        v_project_task_id                       NUMBER          :=      null;
----    CRM Requirements Organization Details
        v_organization_id                       NUMBER          :=      null;
        v_LOB_id                                NUMBER          :=      null;
        v_profit_centre_id                      NUMBER          :=      null;
        v_region_id                             NUMBER          :=      null;
        v_branch_id                             NUMBER          :=      null;
        v_salesrep_id                           NUMBER          :=      null;
----    Actual Requirement Details
        v_requirement_subject                   VARCHAR2(4000)  :=      null;
        v_requirement_details                   VARCHAR2(4000)  :=      null;
        v_req_by_party_id                       NUMBER          :=      null;
        v_req_by_contact_id                     NUMBER          :=      null;
        v_req_by_bill_to_id                     NUMBER          :=      null;
        v_req_by_ship_to_id                     NUMBER          :=      null;
        v_source_type_set_id                    NUMBER          :=      null;
        v_source_type_code_id                   NUMBER          :=      null;
        v_source_document_number                VARCHAR2(100)   :=      null;
        v_source_document_date                  DATE            :=      null;
        v_reference_number_1                    VARCHAR2(100)   :=      null;
        v_reference_date_1                      DATE            :=      null;
        v_reference_number_2                    VARCHAR2(100)   :=      null;
        v_reference_date_2                      DATE            :=      null;
        v_required_by_date                      DATE            :=      null;
        v_valid_till_date                       DATE            :=      null;
        v_validity_days                         NUMBER          :=      null;
        v_shipment_priority_id                  NUMBER          :=      null;
        v_shipment_method_set_id                NUMBER          :=      null;
        v_shipment_method_code_id               NUMBER          :=      null;
        v_freight_carrier_set_id                NUMBER          :=      null;
        v_freight_carrier_code_id               NUMBER          :=      null;
        v_delivery_terms_set_id                 NUMBER          :=      null;
        v_delivery_terms_code_id                NUMBER          :=      null;
        v_fob_terms_set_id                      NUMBER          :=      null;
        v_fob_terms_code_id                     NUMBER          :=      null;
        v_other_terms_set_id_1                  NUMBER          :=      null;
        v_other_terms_code_id_1                 NUMBER          :=      null;
        v_warranty_terms_set_id                 NUMBER          :=      null;
        v_warranty_terms_code_id                NUMBER          :=      null;
----    Requirement Flags and Statuses
        v_cancelled_flag                        VARCHAR2(1)     :=      null;
        v_cancelled_date                        DATE            :=      null;
        v_booked_flag                           VARCHAR2(1)     :=      null;
        v_booked_date                           DATE            :=      null;
----    Accounting Information
        v_pricing_date                          DATE            :=      null;
        v_price_list_id                         NUMBER          :=      null;
        v_customer_budget_amount                NUMBER          :=      null;
        v_line_base_amount                      NUMBER          :=      null;
        v_discount_percent                      NUMBER          :=      null;
        v_discount_amount                       NUMBER          :=      null;
        v_margin_percent                        NUMBER          :=      null;
        v_margin_amount                         NUMBER          :=      null;
        v_Packing_amount                        NUMBER          :=      null;
        v_forwarding_amount                     NUMBER          :=      null;
        v_insurence_amount                      NUMBER          :=      null;
        v_freight_amount                        NUMBER          :=      null;
        v_other_charges_1                       NUMBER          :=      null;
        v_other_charges_2                       NUMBER          :=      null;
        v_other_charges_3                       NUMBER          :=      null;
        v_taxable_amount                        NUMBER          :=      null;
        v_cgst_amount                           NUMBER          :=      null;
        v_sgst_amount                           NUMBER          :=      null;
        v_igst_amount                           NUMBER          :=      null;
        v_gst_surcharge_amount                  NUMBER          :=      null;
        v_gst_tds_amount                        NUMBER          :=      null;
        v_gst_tcs_amount                        NUMBER          :=      null;
        v_total_amount                          NUMBER          :=      null;
        v_payment_term_id                       NUMBER          :=      null;
        v_invoice_currency_code                 VARCHAR2(100)   :=      null;
        v_payment_currency_code                 VARCHAR2(100)   :=      null;
        v_conversion_rate                       NUMBER          :=      null;
        v_conversion_date                       DATE            :=      null;
        v_accounting_flag                       VARCHAR2(1)     :=      null;
        v_accounting_event_id                   NUMBER          :=      null;
        v_accounting_date                       DATE            :=      null;
        v_sla_header_id                         NUMBER          :=      null;
        v_gl_transfer_flag                      VARCHAR(1)      :=      null;
        v_gl_date                               DATE            :=      null;
        v_jv_header_id                          NUMBER          :=      null;
----    Requirement Conversion Information
        v_customer_po_number                    VARCHAR(100)    :=      null;
        v_customer_po_date                      DATE            :=      null;
        v_our_so_header_id                      NUMBER          :=      null;
        v_our_so_line_id                        NUMBER          :=      null;
        v_probability_set_id                    NUMBER          :=      null;
        v_probability_code_id                   NUMBER          :=      null;
        v_status_id                             NUMBER          :=      null;
        v_status_date                           DATE            :=      null;
        v_user_party_id                         NUMBER          :=      null;

BEGIN
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started for Converting an Enquiry into offer');
        DBMS_OUTPUT.put_line ('Execution Started for Converting an Enquiry into an Offer');

        p_return_code          := 0;            ----  Successful Execution
        p_return_message       := ' '; 

----    First populate data for Offer Header from the Associated Enquiry Id passed.
        BEGIN
----            Check  whether correct CLIENT ID has been Passed.
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating Client ID');
                DBMS_OUTPUT.put_line ('Validating Client ID');
                exists_flag     :=  'Y';
                BEGIN
                        SELECT  'Y'
                        INTO    exists_flag
                        FROM    cmn_client_master 
                        WHERE   1                           =   1
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Client ID Passed (Absent)';
                END;

----            Check  whether correct User ID has been Passed.
                exists_flag     :=  'Y';
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating User ID');
                DBMS_OUTPUT.put_line ('Validating User ID');
                BEGIN
                        SELECT  'c',
                                party_id
                        INTO    exists_flag,
                                v_user_party_id
                        FROM    cmn_user_master 
                        WHERE   1                           =   1
                        AND     user_id                     =   p_user_id
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect User ID Passed (Absent)';
                END;

----            Check  whether correct Lead ID has been Passed.
                exists_flag     :=  'Y';
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating Lead ID');
                DBMS_OUTPUT.put_line ('Validating Lead ID');
                BEGIN
                        SELECT  'c'
                        INTO    exists_flag
                        FROM    crm_requirement_headers_v 
                        WHERE   1                           =   1
                        AND     trim(upper(req_type_code))  =   'LEAD'
                        AND     requirement_id              =   p_lead_id
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Lead ID Passed (Absent)';
                END;

----            Populate Requirement Type Set Id for Offer
                BEGIN
                        SELECT  category_id
                        INTO    v_req_type_set_id
                        FROM    cmn_category_master_v 
                        WHERE   1                           =   1
                        AND     upper(trim(type_set_code))  =   'CRM_REQUIREMENT_SET'
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Type Set Passed (Absent)';
                END;

----            Populate Requirement Type Code Id for Offer
                BEGIN
                        SELECT  sub_category_id
                        INTO    v_req_type_Code_id
                        FROM    cmn_sub_category_master_v 
                        WHERE   1                           =   1
                        AND     trim(upper(sub_category_code))= 'ENQUIRY'
                        AND     category_id                 =   v_req_type_set_id
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Type Code Passed (Absent)';
                END;

----            Populate Probability Set Id
                BEGIN
                        SELECT  category_id
                        INTO    v_probability_set_id
                        FROM    cmn_category_master_v 
                        WHERE   1                           =   1
                        AND     upper(trim(type_set_code))  =   'PROBABILITY_TERMS_SET'
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Probability Set Passed (Absent)';
                END;

----            Populate Warranty Set Id
                BEGIN
                        SELECT  category_id
                        INTO    v_warranty_terms_set_id
                        FROM    cmn_category_master_v 
                        WHERE   1                           =   1
                        AND     upper(trim(type_set_code))  =   'WARRANTY_TERMS_SET'
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Warranty Set Passed (Absent)';
                END;

----            Populate Transaction Type Id
                BEGIN
                        SELECT  transaction_type_id
                        INTO    v_transaction_type_id
                        FROM    cmn_transaction_types_v 
                        WHERE   1                           =   1
                        AND     upper(trim(transaction_type_code))  =   'MANAGE_CRM_ENQUIRY'
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                     :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Transaction Type Passed (Absent)';
                END;

                IF    ( p_return_code <> 0)
                THEN  raise  Some_Error;
                END   IF;

----            Populate Status Id
                BEGIN
                        SELECT  status_id
                        INTO    v_status_id
                        FROM    cmn_status_master_v
                        WHERE   1                           =   1
                        AND     upper(trim(status_code))    =   'OPEN'
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                     :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Status Passed (Absent)';
                END;

-----           Now Populate the Offer Data from the Underlined Enquiry
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Reading Enquiry Data');
                DBMS_OUTPUT.put_line ('Reading Enquiry Data');
                BEGIN
                        SELECT  'I'                                     ,   ----    v_action
                                p_user_id                               ,   ----    v_user_id
                                nvl(start_date,sysdate)                 ,   ----    v_start_date
                                end_date                                ,   ----    v_end_date
----                            CRM Requirements Identification Information
----                                requirement_id                          ,
                                application_id                          ,
                                client_id                               ,
                                parent_requirement_id                   ,
                                requirement_number                      ,
                                received_date                           ,
                                expiration_date                         ,
                                version_number                          ,
                                current_version_flag                    ,
----                            CRM Requirements Classification
                                req_created_by_party_id                 ,
                                associated_call_id                      ,
                                requirement_id                          ,   ----  Requirement id to be associated_lead_id  as  we are selecting the data from the Lead
                                associated_enquiry_id                   ,
                                associated_offer_id                     ,
----                                req_type_set_id                         ,   ----  50303 - CRM_REQUIREMENT_TYPE  -   From CAtegory Master
----                                req_type_code_id                        ,   ----  Lead or ENQUIRY or QUOTATION  -   From Sub Category Master
                                req_class_set_id                        ,
                                req_class_code_id                       ,
                                ms_category_id                          ,
                                ms_sub_category_id                      ,
                                as_category_id                          ,
                                as_sub_category_id                      ,
----                                transaction_type_id                     ,
                                plan_header_id                          ,
                                plan_detail_id                          ,
                                budget_id                               ,
                                budget_line_id                          ,
                                project_id                              ,
                                project_task_id                         ,
----                            CRM Requirements Organization Details
                                organization_id                         ,
                                LOB_id                                  ,
                                profit_centre_id                        ,
                                region_id                               ,
                                branch_id                               ,
                                salesrep_id                             ,
----                            Actual Requirement Details
                                requirement_subject                     ,
                                requirement_details                     ,
                                req_by_party_id                         ,
                                req_by_contact_id                       ,
                                req_by_bill_to_id                       ,
                                req_by_ship_to_id                       ,
                                source_type_set_id                      ,
                                source_type_code_id                     ,
                                source_document_number                  ,
                                source_document_date                    ,
                                reference_number_1                      ,
                                reference_date_1                        ,
                                reference_number_2                      ,
                                reference_date_2                        ,
                                required_by_date                        ,
                                valid_till_date                         ,
                                validity_days                           ,
                                shipment_priority_id                    ,
                                shipment_method_set_id                  ,      --- From Category 
                                shipment_method_code_id                 ,      --- From Subcategory
                                freight_carrier_set_id                  ,
                                freight_carrier_code_id                 ,
                                delivery_terms_set_id                   ,
                                delivery_terms_code_id                  ,
                                fob_terms_set_id                        ,
                                fob_terms_code_id                       ,
                                other_terms_set_id_1                    ,
                                other_terms_code_id_1                   ,
                                warranty_terms_set_id                   ,
                                warranty_terms_code_id                  ,
----                            Requirement Flags and Statuses
                                cancelled_flag                          ,
                                cancelled_date                          ,
                                booked_flag                             ,
                                booked_date                             ,
----                            Accounting Information
                                pricing_date                            ,
                                price_list_id                           ,
                                customer_budget_amount                  ,
                                line_base_amount                        ,
                                discount_percent                        ,
                                discount_amount                         ,
                                margin_percent                          ,
                                margin_amount                           ,
                                Packing_amount                          ,
                                forwarding_amount                       ,
                                insurence_amount                        ,
                                freight_amount                          ,
                                other_charges_1                         ,
                                other_charges_2                         ,
                                other_charges_3                         ,
                                taxable_amount                          ,
                                cgst_amount                             ,
                                sgst_amount                             ,
                                igst_amount                             ,
                                gst_surcharge_amount                    ,
                                gst_tds_amount                          ,
                                gst_tcs_amount                          ,
                                total_amount                            ,
                                payment_term_id                         ,
                                invoice_currency_code                   ,
                                payment_currency_code                   ,
                                conversion_rate                         ,
                                conversion_date                         ,
                                accounting_flag                         ,
                                accounting_event_id                     ,
                                accounting_date                         ,
                                sla_header_id                           ,
                                gl_transfer_flag                        ,
                                gl_date                                 ,
                                jv_header_id                            ,
----                            Requirement Conversion Information
                                customer_po_number                      ,
                                customer_po_date                        ,
                                our_so_header_id                        ,
                                our_so_line_id                          ,
                                probability_set_id                      ,   ---  Probability of Winning
                                probability_code_id                     
                        INTO    v_action                                ,
                                v_user_id                               ,
                                v_start_date                            ,
                                v_end_date                              ,
----                            CRM Requirements Identification Information
----                                v_requirement_id                        ,
                                v_application_id                        ,
                                v_client_id                             ,
                                v_parent_requirement_id                 ,
                                v_requirement_number                    ,
                                v_received_date                         ,
                                v_expiration_date                       ,
                                v_version_number                        ,
                                v_current_version_flag                  ,
----                            CRM Requirements Classification
                                v_req_created_by_party_id               ,
                                v_associated_call_id                    ,
                                v_associated_lead_id                    ,
                                v_associated_enquiry_id                 ,
                                v_associated_offer_id                   ,
----                                v_req_type_set_id                       ,   ----  50303 - CRM_REQUIREMENT_TYPE  -   From CAtegory Master
----                                v_req_type_code_id                      ,   ----  Lead or ENQUIRY or QUOTATION  -   From Sub Category Master
                                v_req_class_set_id                      ,
                                v_req_class_code_id                     ,
                                v_ms_category_id                        ,
                                v_ms_sub_category_id                    ,
                                v_as_category_id                        ,
                                v_as_sub_category_id                    ,
----                                v_transaction_type_id                   ,
                                v_plan_header_id                        ,
                                v_plan_detail_id                        ,
                                v_budget_id                             ,
                                v_budget_line_id                        ,
                                v_project_id                            ,
                                v_project_task_id                       ,
----                            CRM Requirements Organization Details
                                v_organization_id                       ,
                                v_LOB_id                                ,
                                v_profit_centre_id                      ,
                                v_region_id                             ,
                                v_branch_id                             ,
                                v_salesrep_id                           ,
----                            Actual Requirement Details
                                v_requirement_subject                   ,
                                v_requirement_details                   ,
                                v_req_by_party_id                       ,
                                v_req_by_contact_id                     ,
                                v_req_by_bill_to_id                     ,
                                v_req_by_ship_to_id                     ,
                                v_source_type_set_id                    ,
                                v_source_type_code_id                   ,
                                v_source_document_number                ,
                                v_source_document_date                  ,
                                v_reference_number_1                    ,
                                v_reference_date_1                      ,
                                v_reference_number_2                    ,
                                v_reference_date_2                      ,
                                v_required_by_date                      ,
                                v_valid_till_date                       ,
                                v_validity_days                         ,
                                v_shipment_priority_id                  ,
                                v_shipment_method_set_id                ,      --- From Category 
                                v_shipment_method_code_id               ,      --- From Subcategory
                                v_freight_carrier_set_id                ,
                                v_freight_carrier_code_id               ,
                                v_delivery_terms_set_id                 ,
                                v_delivery_terms_code_id                ,
                                v_fob_terms_set_id                      ,
                                v_fob_terms_code_id                     ,
                                v_other_terms_set_id_1                  ,
                                v_other_terms_code_id_1                 ,
                                v_warranty_terms_set_id                 ,
                                v_warranty_terms_code_id                ,
----                            Requirement Flags and Statuses
                                v_cancelled_flag                        ,
                                v_cancelled_date                        ,
                                v_booked_flag                           ,
                                v_booked_date                           ,
----                            Accounting Information
                                v_pricing_date                          ,
                                v_price_list_id                         ,
                                v_customer_budget_amount                ,
                                v_line_base_amount                      ,
                                v_discount_percent                      ,
                                v_discount_amount                       ,
                                v_margin_percent                        ,
                                v_margin_amount                         ,
                                v_Packing_amount                        ,
                                v_forwarding_amount                     ,
                                v_insurence_amount                      ,
                                v_freight_amount                        ,
                                v_other_charges_1                       ,
                                v_other_charges_2                       ,
                                v_other_charges_3                       ,
                                v_taxable_amount                        ,
                                v_cgst_amount                           ,
                                v_sgst_amount                           ,
                                v_igst_amount                           ,
                                v_gst_surcharge_amount                  ,
                                v_gst_tds_amount                        ,
                                v_gst_tcs_amount                        ,
                                v_total_amount                          ,
                                v_payment_term_id                       ,
                                v_invoice_currency_code                 ,
                                v_payment_currency_code                 ,
                                v_conversion_rate                       ,
                                v_conversion_date                       ,
                                v_accounting_flag                       ,
                                v_accounting_event_id                   ,
                                v_accounting_date                       ,
                                v_sla_header_id                         ,
                                v_gl_transfer_flag                      ,
                                v_gl_date                               ,
                                v_jv_header_id                          ,
----                            Requirement Conversion Information
                                v_customer_po_number                    ,
                                v_customer_po_date                      ,
                                v_our_so_header_id                      ,
                                v_our_so_line_id                        ,
                                v_probability_set_id                    ,   ---  Probability of Winning
                                v_probability_code_id                   
                       FROM    crm_requirement_headers
                        WHERE   1                   =    1
                        AND     requirement_id      =    p_Lead_id
                        AND     client_id           =    p_client_id;
                EXCEPTION
                     WHEN       OTHERS
                     THEN       p_return_code       :=  2;
                                p_return_message    :=  p_return_message ||  ' - '  ||
                                                        ' Incorrect Lead ID Passed ... Can not Load Data ';
                END;

                IF    ( p_return_code <> 0)
                THEN  raise  Some_Error;
                END   IF;

----        Now call a procedure to create new offer
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Calling Offer Header API');
                DBMS_OUTPUT.put_line ('Calling Offer Header API');
                BEGIN
                        CRM_ACD_ENQUIRY_HEADER_API
                        (       p_return_code                           =>  v_return_code                          , 
                                p_return_message                        =>  v_return_message                       , 
                                p_action                                =>  v_action                               , 
                                p_user_id                               =>  v_user_id                              , 
                                p_start_date                            =>  v_start_date                           , 
                                p_end_date                              =>  v_end_date                             , 
                                p_client_id                             =>  v_client_id                            , 
                                p_requirement_id                        =>  v_requirement_id                       , 
                                p_parent_requirement_id                 =>  v_parent_requirement_id                , 
                                p_requirement_number                    =>  v_requirement_number                   , 
                                p_received_date                         =>  v_received_date                        , 
                                p_expiration_date                       =>  v_expiration_date                      , 
                                p_version_number                        =>  nvl(v_version_number,1)                , 
                                p_current_version_flag                  =>  v_current_version_flag                 , 
                                p_req_created_by_party_id               =>  v_user_party_id                        , 
                                p_associated_call_id                    =>  v_associated_call_id                   , 
                                p_associated_lead_id                    =>  p_lead_id                              , 
                                p_req_type_set_id                       =>  v_req_type_set_id                      , 
                                p_req_type_code_id                      =>  v_req_type_code_id                     , 
                                p_req_class_set_id                      =>  v_req_class_set_id                     , 
                                p_req_class_code_id                     =>  v_req_class_code_id                    , 
                                p_ms_category_id                        =>  v_ms_category_id                       , 
                                p_ms_sub_category_id                    =>  v_ms_sub_category_id                   , 
                                p_as_category_id                        =>  v_as_category_id                       , 
                                p_as_sub_category_id                    =>  v_as_sub_category_id                   , 
                                p_plan_header_id                        =>  v_plan_header_id                       , 
                                p_plan_detail_id                        =>  v_plan_detail_id                       , 
                                p_budget_id                             =>  v_budget_id                            , 
                                p_budget_line_id                        =>  v_budget_line_id                       , 
                                p_project_id                            =>  v_project_id                           , 
                                p_project_task_id                       =>  v_project_task_id                      , 
                                p_organization_id                       =>  v_organization_id                      , 
                                p_lob_id                                =>  v_lob_id                               , 
                                p_profit_centre_id                      =>  v_profit_centre_id                     , 
                                p_region_id                             =>  v_region_id                            , 
                                p_branch_id                             =>  v_branch_id                            , 
                                p_salesrep_id                           =>  v_salesrep_id                          , 
                                p_requirement_subject                   =>  v_requirement_subject                  , 
                                p_requirement_details                   =>  v_requirement_details                  , 
                                p_req_by_party_id                       =>  v_req_by_party_id                      , 
                                p_req_by_contact_id                     =>  v_req_by_contact_id                    , 
                                p_req_by_bill_to_id                     =>  v_req_by_bill_to_id                    , 
                                p_req_by_ship_to_id                     =>  v_req_by_ship_to_id                    , 
                                p_source_type_set_id                    =>  v_source_type_set_id                   , 
                                p_source_type_code_id                   =>  v_source_type_code_id                  , 
                                p_source_document_number                =>  v_source_document_number               , 
                                p_source_document_date                  =>  v_source_document_date                 ,
                                p_reference_number_1                    =>  v_reference_number_1                   ,
                                p_reference_date_1                      =>  v_reference_date_1                     ,
                                p_reference_number_2                    =>  v_reference_number_2                   ,
                                p_reference_date_2                      =>  v_reference_date_2                     ,
                                p_required_by_date                      =>  v_required_by_date                     , 
                                p_shipment_priority_id                  =>  v_shipment_priority_id                 , 
                                p_shipment_method_set_id                =>  v_shipment_method_set_id               , 
                                p_shipment_method_code_id               =>  v_shipment_method_code_id              , 
                                p_freight_carrier_set_id                =>  v_freight_carrier_set_id               , 
                                p_freight_carrier_code_id               =>  v_freight_carrier_code_id              , 
                                p_status_id                             =>  v_status_id                            , 
                                p_status_date                           =>  v_status_date                          , 
                                p_application_id                        =>  v_application_id                       , 
                                p_transaction_type_id                   =>  v_transaction_type_id                  , 
                                p_payment_term_id                       =>  v_payment_term_id                      ,
                                p_conversion_date                       =>  v_conversion_date                      ,
                                p_conversion_rate                       =>  v_conversion_rate                      ,
                                p_reason_set_id                         =>  null,
                                p_reason_code_id                        =>  null,
                                p_reason_note                           =>  null,
                                p_customer_budget_amount                =>  v_customer_budget_amount
                        );
                    commit;
                    p_requirement_id            :=      v_requirement_id;
                    p_requirement_number        :=      v_requirement_number;
                EXCEPTION
                     WHEN    OTHERS
                     THEN    p_return_code       :=  2;
                             p_return_message    :=  p_return_message  ||  ' - '  ||
                                                    ' Some Error in Creating Offer Header... ';
                END;
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Enquiry Header created ' || p_return_code || ' - '||p_return_message);
                DBMS_OUTPUT.put_line ('Enquiry Header Created '|| p_return_code || ' - '||p_return_message);
        END;

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

        p_return_code           :=      0;
        p_return_message        :=      'Enquiry Header Created Successfully';

------  Now update enquiry status.
        BEGIN
                UPDATE  crm_requirement_headers
                SET     last_update_date         =   sysdate,
                        last_updated_by          =   p_user_id,
                        end_date                 =   sysdate,
                        status_id                =   (select    status_id
                                                      from      cmn_status_master_v
                                                      where     1                       =  1
                                                      and       upper(trim(status_code))=  'ENQUIRY-CREATED'
                                                      and       client_id               =  p_client_id
                                                     ),
                        status_date              =   sysdate
                WHERE   1                        =   1
                AND     requirement_id           =   p_lead_id
                AND     client_id                =   p_client_id;
                commit;
        EXCEPTION
                WHEN    OTHERS
                THEN    p_return_code           :=  2;
                        p_return_message        :=  p_return_message ||  ' - '  ||
                                                    'Unable to Update Lead Status ' || SQLERRM;
        END;

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

-----  If offer and offer lines succesfully created from enquiry then
-----   Create a Record in the Notifications table. 
        CMN_Register_Notifications_API
        (   p_return_code                       =>  p_return_code,
            p_return_message                    =>  p_return_message,
            P_notification_id                   =>  v_notification_id,
            p_action                            =>  'I',
            p_user_id                           =>  p_user_id,
            P_client_id                         =>  p_client_id,
            p_notification_number               =>  'ENQUIRY-'||v_REQUIREMENT_NUMBER,
            p_notification_date                 =>  sysdate,
            p_subject                           =>  'Your Enquiry Number - '||v_REQUIREMENT_NUMBER||' has been Created.',
            p_details                           =>  V_REQUIREMENT_SUBJECT,
            p_due_date                          =>  sysdate,
            p_expiry_date                       =>  V_EXPIRATION_DATE,
            p_document_process_set_id           =>  null,
            p_document_process_code_id          =>  null,
            p_approval_type_set_id              =>  null,
            p_approval_type_code_id             =>  null,
            p_document_table                    =>  'CRM_REQUIREMENT_HEADERS',
            p_document_key_id                   =>  V_REQUIREMENT_ID,
            p_organization_id                   =>  v_organization_id,
            p_lob_id                            =>  v_lob_id,
            p_profit_centre_id                  =>  v_PROFIT_CENTRE_ID,
            p_department_id                     =>  null,
            p_region_id                         =>  v_REGION_ID,
            p_branch_id                         =>  v_BRANCH_ID,
            p_from_user_id                      =>  p_user_id,
            p_to_user_id                        =>  null,
            p_document_code                     =>  null,
            p_document_name                     =>  null,
            p_document_description              =>  null,
            p_document_category_id              =>  null,
            p_document_sub_category_id          =>  null,
            p_link_application_id               =>  '503',
            p_link_page_id                      =>  1410,
            p_link_field_name                   =>  'p1410_requirement_id'
        );

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

        p_requirement_id        :=  v_requirement_id;
        p_requirement_number    :=  v_requirement_number;
        p_return_code           :=  0;
        p_return_message        :=  'Requirement Creation is Successful. Requirement Number is '
                                || v_REQUIREMENT_NUMBER;
EXCEPTION
     WHEN       Some_Error
     THEN       p_return_code    :=  2;
                p_return_message :=  p_return_message || ' - ' ||
                                    'Some error Has Occurred...Existing...Unsuccessful Execution';
                RETURN; 

     WHEN       OTHERS
     THEN       DBMS_OUTPUT.put_line (p_return_message || ' - ' || SQLERRM);
                Apex_Util.Set_Session_State('LOGIN_MESSAGE' ,p_return_message || ' - ' || SQLERRM);
                APEX_ERROR.add_error ( p_error_code       => p_return_message || ' - ' || SQLERRM,
                                       p0                 => null,
                                       p_display_location => apex_error.c_inline_with_field_and_notif,
                                       p_page_item_name   => null 
                                     );
                p_return_code    :=  2;
                p_return_message :=  p_return_message ||  ' - ' || SQLERRM;
                RETURN;
END     CONVERT_CRM_LEAD_TO_ENQUIRY_API;
---------------------------------------------------------------------------------------------------------------------------------
