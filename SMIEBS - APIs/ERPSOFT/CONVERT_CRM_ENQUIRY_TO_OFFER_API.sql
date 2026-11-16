--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Convert Enquiries to Offers
--- -     Written by    : Manali Modak - Kulkarni
-----     Date Written  : 17th April 2021 
-----     Modified V1   : Modified to change the Header ID Criterion
-----     V1 Modified on: 26th November 2022
-----     Modified V2   : Modified to Resolve Problem of Incorrect Quotation Number Generation
-----     V2 Modified on: 03rd April 2023
-----     Modified V3   : Modified to Accomodate New Pricing and Discounting Structures
-----     V3 Modified on: 08th October 2023
---------------------------------------------------------------------------------------------------------------------------------
----      API to Convert Enquiries to Offers
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE CONVERT_CRM_ENQUIRY_TO_OFFER_API 
    (   p_return_code                        OUT  VARCHAR2,
        p_return_message                     OUT  VARCHAR2,
        p_offer_number                       OUT  VARCHAR2,
        p_offer_id                        IN OUT  NUMBER,
        p_user_id                             IN  NUMBER,
        p_client_id                           IN  NUMBER, 
        p_enquiry_id                          IN  NUMBER
    )
    AS
----    Declare Cursor for Enquiry Lines Data
        CURSOR GET_ENQUIRY_LINES (s_enquiry_id number, s_client_id number)  IS
                SELECT  creation_date,
                        created_by,
                        last_update_date,
                        last_updated_by,
                        start_date,
                        end_date,
                        client_id,
                        requirement_line_id,
                        requirement_id,
                        row_number() over(order by crl.line_number)                 as line_number,
                        line_type_set_id,
                        line_type_code_id,
                        inventory_item_id,
                        item_details,
                        uom_code_id,
                        hsn_sac_code_id,
                        required_by_date,
                        request_date,
                        order_quantity,
                        pricing_date,
                        price_list_id,
                        unit_list_price,
                        line_amount,
                        total_amount,
                        payment_term_id,
                        invoice_currency_code,
                        payment_currency_code,
                        conversion_rate,
                        conversion_date,
                        status_id,
                        status_date,
                        services_required,
                        services_offered,
                        service_duration_days,
                        service_start_date,
                        service_end_date
                FROM    crm_requirement_lines           crl
                WHERE   1                       =       1
                AND     requirement_id          =       s_enquiry_id
                AND     exists
                        (
                          select  'c'
                          from    cmn_status_master     csm
                          where   1             =       1
                          and     upper(trim(status_code)) = 'OPEN'
                          and     csm.status_id     =   crl.status_id
                          and     csm.client_id     =   crl.client_id
                        )
                AND     client_id               =       s_client_id
                ORDER BY  crl.line_number;

---     Declare Variables and Cursors required for generation
        err_message                           varchar2(200)   :=  null;
        exists_flag                           varchar2(01)    :=  null;
        dummy_flag                            varchar2(01)    :=  null;
        recs_added                            number          :=  0;

        Some_Error                            EXCEPTION;

-----   Define Header API Fields
        v_return_code                         VARCHAR2(01)    :=  null;
        v_return_message                      VARCHAR2(4000)  :=  null;
        v_action                              VARCHAR2(01)    :=  'I';
        v_user_id                             NUMBER          :=  p_user_id;
        v_start_date                          DATE            :=  sysdate;
        v_end_date                            DATE            :=  null;
        v_client_id                           NUMBER          :=  p_client_id; 
        v_notification_id                     NUMBER          :=  0;
        v_requirement_id                      NUMBER          :=  null;         ----    This is offer id 
        v_parent_requirement_id               NUMBER          :=  null;
        v_requirement_number                  VARCHAR2(100)   :=  null;
        v_received_date                       DATE            :=  null;
        v_expiration_date                     DATE            :=  null;
        v_version_number                      NUMBER          :=  null;
        v_current_version_flag                VARCHAR2(01)    :=  null;
        v_req_created_by_party_id             NUMBER          :=  null;
        v_associated_enquiry_id               NUMBER          :=  null;
        v_req_type_set_id                     NUMBER          :=  null;
        v_req_type_code_id                    NUMBER          :=  null;
        v_req_class_set_id                    NUMBER          :=  null;
        v_req_class_code_id                   NUMBER          :=  null;
        v_ms_category_id                      NUMBER          :=  null;
        v_ms_sub_category_id                  NUMBER          :=  null;
        v_as_category_id                      NUMBER          :=  null;
        v_as_sub_category_id                  NUMBER          :=  null;
        v_transaction_type_id                 NUMBER          :=  null;
        v_plan_header_id                      NUMBER          :=  null;
        v_plan_detail_id                      NUMBER          :=  null;
        v_budget_id                           NUMBER          :=  null;
        v_budget_line_id                      NUMBER          :=  null;
        v_project_id                          NUMBER          :=  null;
        v_project_task_id                     NUMBER          :=  null;
        v_organization_id                     NUMBER          :=  null;
        v_lob_id                              NUMBER          :=  null;
        v_profit_centre_id                    NUMBER          :=  null;
        v_region_id                           NUMBER          :=  null;
        v_branch_id                           NUMBER          :=  null;
        v_salesrep_id                         NUMBER          :=  null;
        v_requirement_subject                 VARCHAR2(4000)   :=  null;
        v_requirement_details                 VARCHAR2(4000)  :=  null;
        v_req_by_party_id                     NUMBER          :=  null;
        v_req_by_contact_id                   NUMBER          :=  null;
        v_req_by_bill_to_id                   NUMBER          :=  null;
        v_req_by_ship_to_id                   NUMBER          :=  null;
        v_source_type_set_id                  NUMBER          :=  null;
        v_source_type_code_id                 NUMBER          :=  null;
        v_source_document_number              VARCHAR2(100)   :=  null;
        v_source_document_date                DATE            :=  null;
        v_required_by_date                    DATE            :=  null;
        v_shipment_priority_id                NUMBER          :=  null;
        v_shipment_method_set_id              NUMBER          :=  null;
        v_shipment_method_code_id             NUMBER          :=  null;
        v_freight_carrier_set_id              NUMBER          :=  null;
        v_freight_carrier_code_id             NUMBER          :=  null;
        v_payment_term_id                     NUMBER          :=  null;
        v_conversion_rate                     NUMBER          :=  null;
        v_conversion_date                     DATE            :=  null;
        v_status_id                           NUMBER          :=  null;
        v_status_date                         DATE            :=  null;
        v_application_id                      NUMBER          :=  null;
        v_reference_number_1                  VARCHAR2(256)   :=  null;
        v_reference_date_1                    DATE            :=  null;
        v_reference_number_2                  VARCHAR2(256)   :=  null;
        v_reference_date_2                    DATE            :=  null;
        v_valid_till_date                     DATE            :=  null;
        v_validity_days                       NUMBER          :=  null;
        v_delivery_terms_set_id               NUMBER          :=  null;
        v_delivery_terms_code_id              NUMBER          :=  null;
        v_fob_terms_set_id                    NUMBER          :=  null;
        v_fob_terms_code_id                   NUMBER          :=  null;
        v_other_terms_set_id_1                NUMBER          :=  null;
        v_other_terms_code_id_1               NUMBER          :=  null;
        v_warranty_terms_set_id               NUMBER          :=  null;
        v_warranty_terms_code_id              NUMBER          :=  null;
        v_probability_set_id                  NUMBER          :=  null;
        v_probability_code_id                 NUMBER          :=  null;
        v_customer_budget_amount              NUMBER          :=  null;

-----   Define Line API Fields

        v_pc_state                            varchar2(80)    :=  null;
        v_bill_to_state                       varchar2(80)    :=  null;
        v_igst_applicable                     VARCHAR2(01)    :=  null;
        v_requirement_line_id                 NUMBER          :=  null;
        v_line_number                         NUMBER          :=  null;
        v_line_type_set_id                    NUMBER          :=  null;
        v_line_type_code_id                   NUMBER          :=  null;
        v_inventory_item_id                   NUMBER          :=  null;
        v_item_details                        VARCHAR2(512)   :=  null;
        v_uom_code_id                         NUMBER          :=  null;
        v_hsn_sac_code                        VARCHAR2(512)   :=  null;
        v_hsn_sac_code_id                     NUMBER          :=  null;
        v_request_date                        DATE            :=  null;
        v_price_list_id                       NUMBER          :=  null;
        v_pricing_date                        DATE            :=  null;
        v_order_quantity                      NUMBER          :=  null;
        v_unit_list_price                     NUMBER          :=  null;

        v_disc_on_buy_price_percent           NUMBER          :=  null;
        v_disc_amount_on_buy_price            NUMBER          :=  null;
        v_our_net_buying_price                NUMBER          :=  null;
        v_unit_margin_percent                 NUMBER          :=  null;
        v_unit_margin_amount                  NUMBER          :=  null;
        v_price_offered_to_customer           NUMBER          :=  null;
        v_disc_to_customer_percent            NUMBER          :=  null;
        v_disc_amount_to_customer             NUMBER          :=  null;
        v_unit_selling_Price                  NUMBER          :=  null;
        v_line_amount                         NUMBER          :=  null;

        v_packing_amount                      NUMBER          :=  null;
        v_forwarding_amount                   NUMBER          :=  null;
        v_insurence_amount                    NUMBER          :=  null;
        v_freight_amount                      NUMBER          :=  null;
        v_other_charges_1                     NUMBER          :=  null;
        v_other_charges_2                     NUMBER          :=  null;
        v_other_charges_3                     NUMBER          :=  null;
        v_taxable_amount                      NUMBER          :=  null;
        v_tax_amount                          NUMBER          :=  null;
        v_total_amount                        NUMBER          :=  null;
        v_services_required                   VARCHAR2(4000)  :=  null;
        v_services_offered                    VARCHAR2(4000)  :=  null;
        v_service_duration_days               NUMBER          :=  null;
        v_service_start_date                  DATE            :=  null;
        v_service_end_date                    DATE            :=  null;
        v_cgst_rate                           NUMBER          :=  null;
        v_cgst_amount                         NUMBER          :=  null;
        v_sgst_rate                           NUMBER          :=  null;
        v_sgst_amount                         NUMBER          :=  null;
        v_igst_rate                           NUMBER          :=  null;
        v_igst_amount                         NUMBER          :=  null;
        v_gst_tds_rate                        NUMBER          :=  null;
        v_gst_tds_amount                      NUMBER          :=  null;
        v_gst_tcs_rate                        NUMBER          :=  null;
        v_gst_tcs_amount                      NUMBER          :=  null;
        v_gst_surcharge_rate                  NUMBER          :=  null;
        v_gst_surcharge_amount                NUMBER          :=  null;
        v_other_tax_rate                      NUMBER          :=  null;
        v_other_tax_amount                    Number          :=  null;
        v_user_party_id                       NUMBER          :=  null;

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

----            Check  whether correct Enquiry ID has been Passed.
                exists_flag     :=  'Y';
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating Enquiry ID');
                DBMS_OUTPUT.put_line ('Validating Enquiry ID');
                BEGIN
                        SELECT  'c'
                        INTO    exists_flag
                        FROM    crm_requirement_headers_v 
                        WHERE   1                           =   1
                        AND     trim(upper(req_type_code))  =   'ENQUIRY'
                        AND     requirement_id              =   p_enquiry_id
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Enquiry ID Passed (Absent)';
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
                        AND     trim(upper(sub_category_code))= 'OFFER'
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
                        AND     upper(trim(transaction_type_code))  =   'MANAGE_CRM_OFFER'
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

-----           Now Populate the Offer Data from the Underlined Enquiry
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Reading Enquiry Data');
                DBMS_OUTPUT.put_line ('Reading Enquiry Data');
                BEGIN
                        SELECT  'I'                                 ,   ----    v_action
                                p_user_id                           ,   ----    v_user_id
                                nvl(start_date,sysdate)             ,   ----    v_start_date
                                null                                ,   ----    v_end_date
                                p_client_id                         ,   ----    v_client_id
                                null                                ,   ----    v_parent_requirement_id
                                requirement_number                  ,   ----    v_requirement_number
                                received_date                       ,   ----    v_received_date
                                expiration_date                     ,   ----    v_expiration_date
                                '1'                                 ,   ----    v_version_number
                                'Y'                                 ,   ----    v_current_version_flag
                                req_created_by_party_id             ,   ----    v_req_created_by_party_id
                                requirement_id                      ,   ----    v_associated_enquiry_id
                                req_class_set_id                    ,
                                req_class_code_id                   ,
                                ms_category_id                      ,
                                ms_sub_category_id                  ,
                                as_category_id                      ,
                                as_sub_category_id                  ,
                                plan_header_id                      ,
                                plan_detail_id                      ,
                                budget_id                           ,
                                budget_line_id                      ,
                                project_id                          ,
                                project_task_id                     ,
                                organization_id                     ,
                                lob_id                              ,
                                profit_centre_id                    ,
                                region_id                           ,
                                branch_id                           ,
                                salesrep_id                         ,
                                requirement_subject                 ,
                                requirement_details                 ,
                                req_by_party_id                     ,
                                req_by_contact_id                   ,
                                req_by_bill_to_id                   ,
                                req_by_ship_to_id                   ,
                                source_type_set_id                  ,
                                source_type_code_id                 ,
                                source_document_number              ,
                                source_document_date                ,
                                required_by_date                    ,
                                shipment_priority_id                ,
                                shipment_method_set_id              ,
                                shipment_method_code_id             ,
                                freight_carrier_set_id              ,
                                freight_carrier_code_id             ,
                                pricing_date                        ,
                                payment_term_id                     ,
                                conversion_rate                     ,
                                conversion_date                     ,
                                status_id                           ,
                                nvl(status_date,sysdate)            ,
                                application_id                      ,
                                reference_number_1                  ,
                                reference_date_1                    ,
                                reference_number_2                  ,
                                reference_date_2                    ,
                                valid_till_date                     ,
                                validity_days                       ,
                                delivery_terms_set_id               ,
                                delivery_terms_code_id              ,
                                fob_terms_set_id                    ,
                                fob_terms_code_id                   ,
                                other_terms_set_id_1                ,
                                other_terms_code_id_1               ,
                                warranty_terms_set_id               ,
                                warranty_terms_code_id              ,
                                probability_set_id                  ,
                                probability_code_id                 ,
                                customer_budget_amount              
                        INTO    v_action                            ,
                                v_user_id                           ,
                                v_start_date                        ,
                                v_end_date                          ,
                                v_client_id                         ,
                                v_parent_requirement_id             ,
                                v_requirement_number                ,
                                v_received_date                     ,
                                v_expiration_date                   ,
                                v_version_number                    ,
                                v_current_version_flag              ,
                                v_req_created_by_party_id           ,
                                v_associated_enquiry_id             ,
                                v_req_class_set_id                  ,
                                v_req_class_code_id                 ,
                                v_ms_category_id                    ,
                                v_ms_sub_category_id                ,
                                v_as_category_id                    ,
                                v_as_sub_category_id                ,
                                v_plan_header_id                    ,
                                v_plan_detail_id                    ,
                                v_budget_id                         ,
                                v_budget_line_id                    ,
                                v_project_id                        ,
                                v_project_task_id                   ,
                                v_organization_id                   ,
                                v_lob_id                            ,
                                v_profit_centre_id                  ,
                                v_region_id                         ,
                                v_branch_id                         ,
                                v_salesrep_id                       ,
                                v_requirement_subject               ,
                                v_requirement_details               ,
                                v_req_by_party_id                   ,
                                v_req_by_contact_id                 ,
                                v_req_by_bill_to_id                 ,
                                v_req_by_ship_to_id                 ,
                                v_source_type_set_id                ,
                                v_source_type_code_id               ,
                                v_source_document_number            ,
                                v_source_document_date              ,
                                v_required_by_date                  ,
                                v_shipment_priority_id              ,
                                v_shipment_method_set_id            ,
                                v_shipment_method_code_id           ,
                                v_freight_carrier_set_id            ,
                                v_freight_carrier_code_id           ,
                                v_pricing_date                      ,
                                v_payment_term_id                   ,
                                v_conversion_rate                   ,
                                v_conversion_date                   ,
                                v_status_id                         ,
                                v_status_date                       ,
                                v_application_id                    ,
                                v_reference_number_1                ,
                                v_reference_date_1                  ,
                                v_reference_number_2                ,
                                v_reference_date_2                  ,
                                v_valid_till_date                   ,
                                v_validity_days                     ,
                                v_delivery_terms_set_id             ,
                                v_delivery_terms_code_id            ,
                                v_fob_terms_set_id                  ,
                                v_fob_terms_code_id                 ,
                                v_other_terms_set_id_1              ,
                                v_other_terms_code_id_1             ,
                                v_warranty_terms_set_id             ,
                                v_warranty_terms_code_id            ,
                                v_probability_set_id                ,
                                v_probability_code_id               ,
                                v_customer_budget_amount
                        FROM    crm_requirement_headers
                        WHERE   1                   =    1
                        AND     requirement_id      =    p_enquiry_id
                        AND     client_id           =    p_client_id;
                EXCEPTION
                     WHEN       OTHERS
                     THEN       p_return_code       :=  2;
                                p_return_message    :=  p_return_message ||  ' - '  ||
                                                        ' Incorrect Enquiy ID Passed ... Can not Load Data ';
                END;

----            Get State Code of the Profit Centre for Tax Calculations
                v_pc_state  :=      null;
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Getting Home State');
                DBMS_OUTPUT.put_line ('Getting Home State');
                BEGIN
                        SELECT  state_code
                        INTO    v_pc_state
                        FROM    cmn_profit_centre_master_v      pcm
                        WHERE   1                       =       1
                        AND     pcm.profit_centre_id    =       v_profit_centre_id
                        AND     pcm.lob_id              =       v_lob_id
                        AND     pcm.organization_id     =       v_organization_id
                        AND     pcm.client_id           =       p_client_id;
                EXCEPTION
                     WHEN       OTHERS
                     THEN       v_pc_state      :=      null;
                END;

----            Get Status Code for the Offer creation
                v_status_id     :=      null;
                BEGIN
                        SELECT  status_id
                        INTO    v_status_id
                        FROM    cmn_status_master               pcm
                        WHERE   1                       =       1
                        AND     trim(upper(pcm.status_code))=   'OPEN'
                        AND     pcm.client_id           =       p_client_id;
                EXCEPTION
                     WHEN       OTHERS
                     THEN       v_status_id             :=      null;
                END;

---- offer expiration date 6 months from enquiry date
        v_expiration_date := to_date(v_received_date) + 180;

DBMS_OUTPUT.put_line (p_return_message);
                IF    ( p_return_code <> 0)
                THEN  raise  Some_Error;
                END   IF;

----        Now call a procedure to create new offer
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Calling Offer Header API');
                DBMS_OUTPUT.put_line ('Calling Offer Header API');
                BEGIN
                    CRM_ACD_OFFER_HEADER_API
                    (   p_return_code                      =>    v_return_code                      ,
                        p_return_message                   =>    v_return_message                   ,
                        p_action                           =>    v_action                           ,
                        p_user_id                          =>    v_user_id                          ,
                        p_start_date                       =>    v_start_date                       ,
                        p_end_date                         =>    v_end_date                         ,
                        p_client_id                        =>    v_client_id                        ,
                        p_requirement_id                   =>    v_requirement_id                   ,
                        p_parent_requirement_id            =>    v_parent_requirement_id            ,
                        p_requirement_number               =>    v_requirement_number               ,
                        p_received_date                    =>    v_received_date                    ,
                        p_required_by_date                 =>    v_required_by_date                 ,
                        p_expiration_date                  =>    v_expiration_date                  ,
                        p_version_number                   =>    v_version_number                   ,
                        p_current_version_flag             =>    v_current_version_flag             ,
                        p_req_created_by_party_id          =>    v_user_party_id                    ,
                        p_associated_enquiry_id            =>    v_associated_enquiry_id            ,
                        p_req_type_set_id                  =>    v_req_type_set_id                  ,
                        p_req_type_code_id                 =>    v_req_type_code_id                 ,
                        p_req_class_set_id                 =>    v_req_class_set_id                 ,
                        p_req_class_code_id                =>    v_req_class_code_id                ,
                        p_ms_category_id                   =>    v_ms_category_id                   ,
                        p_ms_sub_category_id               =>    v_ms_sub_category_id               ,
                        p_as_category_id                   =>    v_as_category_id                   ,
                        p_as_sub_category_id               =>    v_as_sub_category_id               ,
                        p_transaction_type_id              =>    v_transaction_type_id              ,
                        p_plan_header_id                   =>    v_plan_header_id                   ,
                        p_plan_detail_id                   =>    v_plan_detail_id                   ,
                        p_budget_id                        =>    v_budget_id                        ,
                        p_budget_line_id                   =>    v_budget_line_id                   ,
                        p_project_id                       =>    v_project_id                       ,
                        p_project_task_id                  =>    v_project_task_id                  ,
                        p_organization_id                  =>    v_organization_id                  ,
                        p_lob_id                           =>    v_lob_id                           ,
                        p_profit_centre_id                 =>    v_profit_centre_id                 ,
                        p_region_id                        =>    v_region_id                        ,
                        p_branch_id                        =>    v_branch_id                        ,
                        p_salesrep_id                      =>    v_salesrep_id                      ,
                        p_requirement_subject              =>    v_requirement_subject              ,
                        p_requirement_details              =>    v_requirement_details              ,
                        p_req_by_party_id                  =>    v_req_by_party_id                  ,
                        p_req_by_contact_id                =>    v_req_by_contact_id                ,
                        p_req_by_bill_to_id                =>    v_req_by_bill_to_id                ,
                        p_req_by_ship_to_id                =>    v_req_by_ship_to_id                ,
                        p_source_type_set_id               =>    v_source_type_set_id               ,
                        p_source_type_code_id              =>    v_source_type_code_id              ,
                        p_source_document_number           =>    v_source_document_number           ,
                        p_source_document_date             =>    v_source_document_date             ,
                        p_shipment_priority_id             =>    v_shipment_priority_id             ,
                        p_shipment_method_set_id           =>    v_shipment_method_set_id           ,
                        p_shipment_method_code_id          =>    v_shipment_method_code_id          ,
                        p_freight_carrier_set_id           =>    v_freight_carrier_set_id           ,
                        p_freight_carrier_code_id          =>    v_freight_carrier_code_id          ,
                        p_pricing_date                     =>    v_pricing_date                     ,
                        p_payment_term_id                  =>    v_payment_term_id                  ,
                        p_conversion_rate                  =>    v_conversion_rate                  ,
                        p_conversion_date                  =>    v_conversion_date                  ,
                        p_status_id                        =>    v_status_id                        ,
                        p_status_date                      =>    v_status_date                      ,
                        p_application_id                   =>    v_application_id                   ,
                        p_reference_number_1               =>    v_reference_number_1               ,
                        p_reference_date_1                 =>    v_reference_date_1                 ,
                        p_reference_number_2               =>    v_reference_number_2               ,
                        p_reference_date_2                 =>    v_reference_date_2                 ,
                        p_valid_till_date                  =>    v_valid_till_date                  ,
                        p_validity_days                    =>    v_validity_days                    ,
                        p_delivery_terms_set_id            =>    v_delivery_terms_set_id            ,
                        p_delivery_terms_code_id           =>    v_delivery_terms_code_id           ,
                        p_fob_terms_set_id                 =>    v_fob_terms_set_id                 ,
                        p_fob_terms_code_id                =>    v_fob_terms_code_id                ,
                        p_other_terms_set_id_1             =>    v_other_terms_set_id_1             ,
                        p_other_terms_code_id_1            =>    v_other_terms_code_id_1            ,
                        p_warranty_terms_set_id            =>    v_warranty_terms_set_id            ,
                        p_warranty_terms_code_id           =>    v_warranty_terms_code_id           ,
                        p_probability_set_id               =>    v_probability_set_id               ,
                        p_probability_code_id              =>    v_probability_code_id              ,
                        p_reason_set_id                    =>    null,
                        p_reason_code_id                   =>    null,
                        p_reason_note                      =>    null,
                        p_customer_budget_amount           =>    v_customer_budget_amount            
                    );
                    commit;
                EXCEPTION
                     WHEN    OTHERS
                     THEN    p_return_code       :=  2;
                             p_return_message    :=  p_return_message  ||  ' - '  ||
                                                    ' Some Error in Creating Offer Header... ';
                END;
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Offer Header created ' || p_return_code || ' - '||p_return_message);
                DBMS_OUTPUT.put_line ('Offer Header Created '|| p_return_code || ' - '||p_return_message || ' - ' || v_requirement_id || ' - '|| v_requirement_number);
        END;

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

----    Now Populate enquiry lines data into offer lines if exists.

        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started for Offer Lines ' || p_return_code || ' - '||p_return_message);
        DBMS_OUTPUT.put_line ('Execution Started for Offer Lines '|| p_return_code || ' - '||p_return_message);
----    Populate Line Type Set Id for Offer
                BEGIN
                            SELECT  category_id
                            INTO    v_line_type_set_id
                            FROM    cmn_category_master_v 
                            WHERE   1                           =   1
                            AND     upper(trim(category_code))  =   'CRM_LINES'
                            AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Type Set Passed (Absent)';
                END;
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Line Type Set ID Populated ' || p_return_code || ' - '||p_return_message);
                DBMS_OUTPUT.put_line ('Line Type Set ID Populated '|| p_return_code || ' - '||p_return_message);

----            Populate Requirement Type Code Id for Offer
                BEGIN
                            SELECT  sub_category_id
                            INTO    v_line_type_code_id
                            FROM    cmn_sub_category_master_v 
                            WHERE   1                           =   1
                            AND     trim(upper(sub_category_code))= 'BASE_LINE'
                            AND     category_id                 =   v_line_type_set_id
                            AND     client_id                   =   p_client_id;
                EXCEPTION
                     WHEN   NO_DATA_FOUND
                     THEN   exists_flag                      :=  null;
                            p_return_code                   :=  2;
                            p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Type Code Passed (Absent)';
                END;
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Line Type Code ID Populated ' || p_return_code || ' - '||p_return_message);
                DBMS_OUTPUT.put_line ('Line Type Code ID Populated '|| p_return_code || ' - '||p_return_message);

----    Process for Converting Enquiry Lines to Offer Lines Starts here

        BEGIN
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Populating Enquiry Lines Data ' || p_enquiry_id);
                DBMS_OUTPUT.put_line ('Populating Enquiry Lines Data '||p_enquiry_id);

                IF    ( p_return_code <> 0)
                THEN  raise  Some_Error;
                END   IF;

                FOR     offer_Lines   in       GET_ENQUIRY_LINES (p_enquiry_id, p_client_id)
                LOOP
----                    Now Get the Pricing and Taxation Rates
                        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Getting Item Price and Tax Rates');
                        DBMS_OUTPUT.put_line ('Getting Item Price and Tax Rates');

                        v_unit_list_price             :=  0;
                        v_hsn_sac_code                :=  null;
                        v_hsn_sac_code_id             :=  0;
                        v_cgst_rate                   :=  0;
                        v_sgst_rate                   :=  0;
                        v_igst_rate                   :=  0;
                        v_igst_applicable             :=  'N';
                        v_requirement_line_id         :=  null;
                        v_disc_on_buy_price_percent   :=  0;
                        v_disc_amount_on_buy_price    :=  0;
                        v_our_net_buying_price        :=  0;
                        v_unit_margin_percent         :=  0;
                        v_unit_margin_amount          :=  0;
                        v_price_offered_to_customer   :=  0;
                        v_disc_to_customer_percent    :=  0;
                        v_disc_amount_to_customer     :=  0;
                        v_unit_selling_Price          :=  0;
                        v_line_amount                 :=  0;

                        BEGIN
                                SELECT  nvl(item_price,0),
                                        hsn_sac_code,
                                        hsn_sac_id
                                INTO    v_unit_list_price,
                                        v_hsn_sac_code,
                                        v_hsn_sac_code_id
                                FROM    cmn_price_list_lines_v  cpll
                                WHERE   1                       =       1
                                AND     upper(trim(price_list_type)) in   ('SALE','BOTH')
                                AND     cpll.price_list_id      =       offer_lines.price_list_id
                                AND     cpll.inventory_item_id  =       offer_lines.inventory_item_id
                                AND     cpll.profit_centre_id   =       v_profit_centre_id
                                AND     cpll.lob_id             =       v_lob_id
                                AND     cpll.organization_id    =       v_organization_id
                                AND     cpll.client_id          =       p_client_id;
                        EXCEPTION
                             WHEN       OTHERS
                             THEN       v_unit_list_price       :=      0;
                                        v_hsn_sac_code          :=      null;
                                        v_hsn_sac_code_id       :=      0;
                        END;

                        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Fetched Item Price and HSN' || v_unit_list_price || ' - '||v_hsn_sac_code);
                        DBMS_OUTPUT.put_line ('Fetched Item Price and HSN before Tax Rates ' || v_unit_list_price || ' - '||v_hsn_sac_code);

                        BEGIN
                                SELECT  to_number(nvl(base_cgst_rate,0)),
                                        to_number(nvl(base_sgst_rate,0)),
                                        to_number(nvl(base_igst_rate,0))
                                INTO    v_cgst_rate,
                                        v_sgst_rate,
                                        v_igst_rate
                                FROM    bt_hsn_sac_rate_master_v        bhsrm
                                WHERE   1                               =       1
                                AND     bhsrm.effective_from_date       <=      sysdate-1
                                AND     bhsrm.effective_to_date         >=      sysdate+1
                                AND     bhsrm.hsn_sac_id                =       v_hsn_sac_code_id
                                AND     bhsrm.hsn_sac_code              =       v_hsn_sac_code
                                AND     bhsrm.client_id                 =       p_client_id;
                        EXCEPTION
                             WHEN       NO_DATA_FOUND
                             THEN       v_hsn_sac_code          :=      null;
                                        v_hsn_sac_code_id       :=      0;
                                        v_cgst_rate             :=      0;
                                        v_sgst_rate             :=      0;
                                        v_igst_rate             :=      0;
                             WHEN       OTHERS
                             THEN       v_hsn_sac_code          :=      null;
                                        v_hsn_sac_code_id       :=      0;
                                        v_cgst_rate             :=      0;
                                        v_sgst_rate             :=      0;
                                        v_igst_rate             :=      0;
                        END;

                        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Fetched  GST Rates item price  ' || v_unit_list_price || ' - '||v_hsn_sac_code);
                        DBMS_OUTPUT.put_line ('Fetched GST Rates item price  ' || v_unit_list_price || ' - '||v_hsn_sac_code);

                        v_bill_to_state                         :=      null;
                        BEGIN
                                SELECT  req_by_bill_to_state
                                INTO    v_bill_to_state
                                FROM    crm_requirement_headers_v       crhv
                                WHERE   1                       =       1
                                AND     crhv.requirement_id     =       p_enquiry_id
                                AND     crhv.client_id          =       p_client_id;
                        EXCEPTION
                             WHEN       OTHERS
                             THEN       v_bill_to_state         :=      null;
                        END;

                        if      ( v_bill_to_state               <>      v_pc_state)
                        then    v_igst_applicable               :=      'Y';
                        else    v_igst_applicable               :=      'N';
                        end     if;

-----                   Now CAll Sales_Line_Calculations_API to Calculate offer Value and Create Offer Line
--                         CRM_Sales_Line_Calculation_API
--                         (       p_return_code                 =>      p_return_code,
--                                 p_return_message              =>      p_return_message,
--                                 p_line_id                     =>      v_requirement_line_id,
--                                 p_user_id                     =>      p_user_id,
--                                 p_client_id                   =>      p_client_id,
--                                 p_header_id                   =>      v_requirement_id,
--                                 p_line_number                 =>      offer_lines.line_number,
--                                 p_line_type                   =>      'OFFER',
--                                 p_line_type_set_id            =>      v_line_type_set_id,
--                                 p_line_type_code_id           =>      v_line_type_code_id,
--                                 p_pc_state_code               =>      v_pc_state,
--                                 p_bill_to_state_code          =>      v_bill_to_state,
--                                 p_item_id                     =>      offer_lines.inventory_item_id,
--                                 p_hsn_sac_code_id             =>      v_hsn_sac_code_id,
--                                 p_order_quantity              =>      offer_lines.order_quantity,
--                                 p_uom_code_id                 =>      offer_lines.uom_code_id,
--                                 p_services_required           =>      offer_lines.services_required,
--                                 p_service_start_date          =>      offer_lines.service_start_date,
--                                 p_service_end_date            =>      offer_lines.service_end_date,
--                                 p_required_by_date            =>      offer_lines.required_by_date,
--                                 p_request_date                =>      offer_lines.required_by_date,
--                                 p_pricing_date                =>      sysdate,
-- ----                            Pricing Parameters      
--                                 p_price_list_id               =>      offer_lines.price_list_id,
--                                 p_unit_list_price             =>      v_unit_list_price,
--                                 p_disc_on_buy_price_percent   =>      null,
--                                 p_disc_amount_on_buy_price    =>      null,
--                                 p_our_net_buying_price        =>      null,
--                                 p_unit_margin_percent         =>      null,
--                                 p_unit_margin_amount          =>      null,
--                                 p_price_offered_to_customer   =>      null,
--                                 p_disc_to_customer_percent    =>      null,
--                                 p_disc_amount_to_customer     =>      null,
--                                 p_unit_selling_Price          =>      null,
--                                 p_line_amount                 =>      null,
--                                 p_packing_amount              =>      null,
--                                 p_forwarding_amount           =>      null,
--                                 p_insurence_amount            =>      null,
--                                 p_freight_amount              =>      null,
--                                 p_other_charges_1             =>      null,
--                                 p_other_charges_2             =>      null,
--                                 p_other_charges_3             =>      null,
--                                 p_taxable_amount              =>      null,
--                                 p_cgst_rate                   =>      null,
--                                 p_cgst_amount                 =>      null,
--                                 p_sgst_rate                   =>      null,
--                                 p_sgst_amount                 =>      null,
--                                 p_igst_rate                   =>      null,
--                                 p_igst_amount                 =>      null,
--                                 p_gst_tds_rate                =>      null,
--                                 p_gst_tds_amount              =>      null,
--                                 p_gst_tcs_rate                =>      null,
--                                 p_gst_tcs_amount              =>      null,
--                                 p_gst_surcharge_rate          =>      null,
--                                 p_gst_surcharge_amount        =>      null,
--                                 p_other_tax_rate              =>      null,
--                                 p_other_tax_amount            =>      null,
--                                 p_tax_amount                  =>      null,
--                                 p_total_amount                =>      null
--                         );
                            CRM_ACD_OFFER_LINE_API 
                            (       p_return_code                     =>  p_return_code,
                                    p_return_message                  =>  p_return_message,
                                    p_action                          =>  'I',
                                    p_user_id                         =>  p_user_id,
                                    p_start_date                      =>  sysdate,
                                    p_end_date                        =>  null,
                                    p_client_id                       =>  p_client_id,
                                    p_requirement_line_id             =>  v_requirement_line_id,
                                    p_requirement_id                  =>  v_requirement_id,
                                    p_line_number                     =>  offer_lines.line_number,
                                    p_line_type_set_id                =>  v_line_type_set_id,
                                    p_line_type_code_id               =>  v_line_type_code_id,
                                    p_inventory_item_id               =>  offer_lines.inventory_item_id,
                                    p_item_details                    =>  null,
                                    p_uom_code_id                     =>  offer_lines.uom_code_id,
                                    p_hsn_sac_code_id                 =>  v_hsn_sac_code_id,
                                    p_required_by_date                =>  offer_lines.required_by_date,
                                    p_request_date                    =>  offer_lines.required_by_date,
                                    p_price_list_id                   =>  offer_lines.price_list_id,
                                    p_pricing_date                    =>  sysdate,
                                    p_order_quantity                  =>  offer_lines.order_quantity,
                                    p_unit_list_price                 =>  v_unit_list_price,
                                    p_disc_on_buy_price_percent       =>  v_disc_on_buy_price_percent,
                                    p_disc_amount_on_buy_price        =>  null,
                                    p_our_net_buying_price            =>  null,
                                    p_unit_margin_percent             =>  v_unit_margin_percent,
                                    p_unit_margin_amount              =>  null,
                                    p_price_offered_to_customer       =>  null,
                                    p_disc_to_customer_percent        =>  v_disc_to_customer_percent,
                                    p_disc_amount_to_customer         =>  null,
                                    p_unit_selling_price              =>  null,
                                    p_line_amount                     =>  null,
                                    p_packing_amount                  =>  null,
                                    p_forwarding_amount               =>  null,
                                    p_insurence_amount                =>  null,
                                    p_freight_amount                  =>  null,
                                    p_other_charges_1                 =>  null,
                                    p_other_charges_2                 =>  null,
                                    p_other_charges_3                 =>  null,
                                    p_taxable_amount                  =>  null,
                                    p_tax_amount                      =>  null,
                                    p_total_amount                    =>  null,
                                    p_status_id                       =>  v_status_id,
                                    p_status_date                     =>  sysdate,
                                    p_services_required               =>  offer_lines.services_required,
                                    p_services_offered                =>  null,
                                    p_service_duration_days           =>  null,
                                    p_service_start_date              =>  offer_lines.service_start_date,
                                    p_service_end_date                =>  offer_lines.service_end_date,
                                    p_conversion_rate                 =>  v_conversion_rate,
                                    p_conversion_date                 =>  v_conversion_date,
                                    p_payment_term_id                 =>  v_payment_term_id,
                                    p_header_discount_percent         =>  0,
                                    p_reason_set_id                   =>  null,
                                    p_reason_code_id                  =>  null,
                                    p_reason_note                     =>  null                              
                            );
                        commit;
                END     LOOP;
        END;
        DBMS_OUTPUT.put_line (p_return_message);
        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

        p_return_code           :=      0;
        p_return_message        :=      'Offer Header and Offer Lines Created Successfully';

-- ------  Update Total line amount into crm_requirement_headers
--         BEGIN
--                 UPDATE  crm_requirement_headers   crh
--                 SET     (       crh.line_cgst_amount,
--                                 crh.line_sgst_amount,
--                                 crh.line_igst_amount,
--                                 crh.line_base_amount,
--                                 crh.line_tax_amount,
--                                 crh.line_total_amount,
--                                 crh.max_cgst_rate,
--                                 crh.max_sgst_rate,
--                                 crh.max_igst_rate,
--                                 crh.line_additional_amount
--                         )       
--                         =       (   select  sum(nvl(crl.cgst_amount,0)),
--                                             sum(nvl(crl.sgst_amount,0)),
--                                             sum(nvl(crl.igst_amount,0)),
--                                             sum(nvl(crl.line_amount,0)),
--                                             sum(nvl(crl.tax_amount,0)),
--                                             sum(nvl(crl.total_amount,0)),
--                                             max(nvl(crl.cgst_rate,0)),
--                                             max(nvl(crl.sgst_rate,0)),
--                                             max(nvl(crl.igst_rate,0)),
--                                             ( sum(nvl(crl.packing_amount,0))      +
--                                               sum(nvl(crl.forwarding_amount,0))   +
--                                               sum(nvl(crl.insurence_amount,0))    +
--                                               sum(nvl(crl.freight_amount,0))      +
--                                               sum(nvl(crl.other_charges_1,0))     +
--                                               sum(nvl(crl.other_charges_2,0))     +
--                                               sum(nvl(crl.other_charges_3,0))     
--                                             )
--                                     from    crm_requirement_lines crl
--                                     where   1               =   1
--                                     and     crl.client_id       =   crh.client_id
--                                     and     crl.requirement_id  =   crh.requirement_id
--                                 )
--                 WHERE   1   =   1
--                 AND     requirement_id      =   v_requirement_id
--                 AND     client_id           =   p_client_id;
--                 commit;
--         EXCEPTION
--                 WHEN    OTHERS
--                 THEN    p_return_code           :=  2;
--                         p_return_message        :=  p_return_message ||  ' - '  ||
--                                                 'Unable to Update Offer Header ' || SQLERRM;
--         END;

DBMS_OUTPUT.put_line (p_return_message);

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

        commit;

------  Now update enquiry status.
        BEGIN
                UPDATE  crm_requirement_headers
                SET     last_update_date         =   sysdate,
                        last_updated_by          =   p_user_id,
                        end_date                 =   sysdate,
                        status_id                =   (select    status_id
                                                      from      cmn_status_master_v
                                                      where     1               =       1
                                                      and       upper(trim(status_code))=  'OFFER-CREATED'
                                                      and       client_id       =       p_client_id
                                                     ),
                        status_date              =   sysdate
                WHERE   1                        =   1
                AND     requirement_id           =   p_enquiry_id
                AND     client_id                =   p_client_id;
                commit;
        EXCEPTION
                WHEN    OTHERS
                THEN    p_return_code           :=  2;
                        p_return_message        :=  p_return_message ||  ' - '  ||
                                                    'Unable to Update Enquiry Status ' || SQLERRM;
        END;

------  Now update enquiry status.
        BEGIN
                UPDATE  crm_requirement_lines       crl
                SET     last_update_date         =   sysdate,
                        last_updated_by          =   p_user_id,
                        end_date                 =   sysdate,
                        status_id                =   (select    status_id
                                                      from      cmn_status_master_v
                                                      where     1               =       1
                                                      and       upper(trim(status_code))=  'OFFER-CREATED'
                                                      and       client_id       =       p_client_id
                                                     ),
                        status_date              =   sysdate
                WHERE   1                        =   1
                AND     exists
                        (select    'c'
                         from      cmn_status_master_v
                         where     1               =       1
                         and       upper(trim(status_code))=  'OPEN'
                         and       status_id       =       crl.status_id
                         and       client_id       =       crl.client_id
                        )
                AND     crl.requirement_id           =   p_enquiry_id
                AND     crl.client_id                =   p_client_id;
                commit;
        EXCEPTION
                WHEN    OTHERS
                THEN    p_return_code           :=  2;
                        p_return_message        :=  p_return_message ||  ' - '  ||
                                                    'Unable to Update Enquiry Status ' || SQLERRM;
        END;

DBMS_OUTPUT.put_line (p_return_message);

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;


---     populate Offer TNC
                    BEGIN
                         CRM_POPULATE_OFFER_TNC_API
                         (
                                   p_return_message            => p_return_message,
                                   p_return_code               => p_return_code,
                                   p_action                    => 'I',
                                   p_user_id                   => p_user_id,
                                   p_client_id                 => p_client_id,
                                   p_lob_id                    => v_lob_id,
                                   p_organization_id           => v_organization_id,
                                   p_profit_centre_id          => v_profit_centre_id,
                                   p_place_lattitude           => null,
                                   p_place_longitude           => null,
                                   p_place_ip_address          => null,
                                   p_requirement_id            => v_requirement_id
                         );
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
            p_notification_number               =>  'OFFER-'||v_REQUIREMENT_NUMBER,
            p_notification_date                 =>  sysdate,
            p_subject                           =>  'Your Offer Number - '||v_REQUIREMENT_NUMBER||' has been Created.',
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
            p_link_page_id                      =>  1610,
            p_link_field_name                   =>  'p1610_requirement_id'
        );

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

        p_offer_id              :=  v_requirement_id;
        p_offer_number          :=  v_requirement_number;
        p_return_code           :=  0;
        p_return_message        :=  'Offer Creation is Successful. Offer Number is '
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
END     CONVERT_CRM_ENQUIRY_TO_OFFER_API;
---------------------------------------------------------------------------------------------------------------------------------