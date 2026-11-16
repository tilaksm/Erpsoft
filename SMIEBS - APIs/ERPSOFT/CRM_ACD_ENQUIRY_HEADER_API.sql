--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Create Enquiry Headers
--- -     Written by    : Manali Modak - Kulkarni
-----     Date Written  : 17th April 2021 
-----     Modified V1   : Modified to change the Header ID Criterion
-----     V1 Modified on: 26th November 2022
---------------------------------------------------------------------------------------------------------------------------------
----    Lead Header API
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE CRM_ACD_ENQUIRY_HEADER_API
    (       p_return_code                           OUT  VARCHAR2,
            p_return_message                        OUT  VARCHAR2,
            p_action                                IN   VARCHAR2,
            p_user_id                               IN   NUMBER,
            p_start_date                            IN   DATE,
            p_end_date                              IN   DATE,
            p_client_id                             IN   NUMBER, 
            p_requirement_id                        IN  OUT NUMBER,
            p_parent_requirement_id                 IN   NUMBER,
            p_requirement_number                    IN  OUT VARCHAR2,
            p_received_date                         IN   DATE,
            p_expiration_date                       IN   DATE,
            p_version_number                        IN   NUMBER,
            p_current_version_flag                  IN   VARCHAR2,
            p_req_created_by_party_id               IN   NUMBER,
            p_associated_call_id                    IN   NUMBER,
            p_associated_lead_id                    IN   NUMBER,
            p_req_type_set_id                       IN   NUMBER,
            p_req_type_code_id                      IN   NUMBER,
            p_req_class_set_id                      IN   NUMBER,
            p_req_class_code_id                     IN   NUMBER,
            p_ms_category_id                        IN   NUMBER,
            p_ms_sub_category_id                    IN   NUMBER,
            p_as_category_id                        IN   NUMBER,
            p_as_sub_category_id                    IN   NUMBER,
            p_plan_header_id                        IN   NUMBER,
            p_plan_detail_id                        IN   NUMBER,
            p_budget_id                             IN   NUMBER,
            p_budget_line_id                        IN   NUMBER,
            p_project_id                            IN   NUMBER,
            p_project_task_id                       IN   NUMBER,
            p_organization_id                       IN   NUMBER,
            p_lob_id                                IN   NUMBER,
            p_profit_centre_id                      IN   NUMBER,
            p_region_id                             IN   NUMBER,
            p_branch_id                             IN   NUMBER,
            p_salesrep_id                           IN   NUMBER,
            p_requirement_subject                   IN   VARCHAR2,
            p_requirement_details                   IN   VARCHAR2,
            p_req_by_party_id                       IN   NUMBER,
            p_req_by_contact_id                     IN   NUMBER,
            p_req_by_bill_to_id                     IN   NUMBER,
            p_req_by_ship_to_id                     IN   NUMBER,
            p_source_type_set_id                    IN   NUMBER,
            p_source_type_code_id                   IN   NUMBER,
            p_source_document_number                IN   VARCHAR2,
            p_source_document_date                  IN   DATE,
            p_reference_number_1                    IN   VARCHAR2,
            p_reference_date_1                      IN   DATE,
            p_reference_number_2                    IN   VARCHAR2,
            p_reference_date_2                      IN   DATE,
            p_required_by_date                      IN   DATE,
            p_shipment_priority_id                  IN   NUMBER,
            p_shipment_method_set_id                IN   NUMBER,
            p_shipment_method_code_id               IN   NUMBER,
            p_freight_carrier_set_id                IN   NUMBER,
            p_freight_carrier_code_id               IN   NUMBER,
            p_status_id                             IN   NUMBER,
            p_status_date                           IN   DATE,
            p_application_id                        IN   NUMBER,
            p_transaction_type_id                   IN   NUMBER,
            p_payment_term_id                       IN   NUMBER,
            p_conversion_rate                       IN   NUMBER,
            p_conversion_date                       IN   DATE,
            p_reason_set_id                         IN   NUMBER,
            p_reason_code_id                        IN   NUMBER,
            p_reason_note                           IN   CLOB,
            p_customer_budget_amount                IN   NUMBER
    )

    AS

----    Declare Variables and Cursors required for generation
        err_message                     varchar2(200)    :=  null;
        exists_flag                     varchar2(01)     :=  null;
        dummy_flag                      varchar2(01)     :=  null;
        recs_added                      number           :=  0;
        v_sr_no                         number           :=  null;
        v_fiscal_yr                     varchar2(10)     :=  null;
        v_transaction_type_code         varchar2(50)     :=  null;
        v_prefix                        varchar2(10)     :=  null;
        v_suffix                        varchar2(50)     :=  null;
        fiscal_year_start_date          date             :=  null;
        fiscal_year_end_date            date             :=  null;
        v_action_id                     number           :=  null;
        v_application_id                number           :=  null;
        v_customer_party_combination_id number           :=  null;
        v_user_party_id                 number           :=  null;
        v_crm_action_set_id             number           :=  null;
        v_crm_action_code_id            number           :=  null;

        Some_Error            EXCEPTION;
BEGIN
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started for Maintaining CRM Enquiry Headers');
        DBMS_OUTPUT.put_line ('Execution Started for Maintaining CRM Enquiry Headers');

----    Start of Maintaining CRM Enquiry Header
        p_return_code          := 0;            ----  Successful Execution
        p_return_message       := null; 

----    First check the mode of operations
        CASE  upper(p_action)
        WHEN  'I'   THEN  null;
        WHEN  'A'   THEN  null;
        WHEN  'C'   THEN  null;
        WHEN  'U'   THEN  null;
        ELSE  p_return_code     := 2;
              p_return_message  := 'Invalid Action Passed - '|| p_action; 
        END   CASE;

----    Check the mode of operations and passed requirement id
        IF    ( upper(p_action) in ('I','A','C') AND p_requirement_id is not null) 
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Combination of action and Enquiry ID';
        END   IF;

        IF    ( upper(p_action) in ('U') AND p_requirement_id is null) 
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Combination of action and Enquiry ID';
        END   IF;
        DBMS_OUTPUT.put_line ('Validating action and requirement ID '||p_return_code||' - '||p_return_message);

----    Validate user id
        exists_flag := null;
        BEGIN  
                SELECT  'Y',
                        party_id
                INTO    exists_flag,
                        v_user_party_id
                FROM    cmn_user_master
                WHERE   user_id             =  p_user_id
                AND     client_id           =  p_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       := 2;
                        p_return_message    := p_return_message ||' - '||'Invalid User ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message ||' - '||'Invalid User ID Passed';
        END;
        DBMS_OUTPUT.put_line ('User ID Validated');

----    Validate Parent Enquiry ID
        exists_flag  :=  null;
        IF (p_parent_requirement_id is not null)
        THEN
                BEGIN  
                        SELECT  'Y'
                        INTO    exists_flag
                        FROM    crm_requirement_headers 
                        WHERE   requirement_id       =  p_parent_requirement_id
                        AND     client_id            =  p_client_id;
                EXCEPTION
                        WHEN    NO_DATA_FOUND
                        THEN    p_return_code       :=  2;
                                p_return_message    :=  p_return_message || ' - ' ||
                                                       'Invalid Parent Enquiry ID Passed';
                        WHEN    OTHERS
                        THEN    p_return_code       :=  2;
                                p_return_message    :=  p_return_message || ' - ' ||
                                                       'Invalid Parent Enquiry ID Passed';
                END;
        END IF;

----    Validate Received Date
        IF    (p_received_date is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Received Date should not be null';
        END   IF;
        DBMS_OUTPUT.put_line ('Validating Received Date '||p_return_code||' - '||p_return_message);

----    Validate Version Number
/*        IF    (p_version_number is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Version Number should not be null';
        END   IF;

----    Validate Current Version Flag
        IF    (p_current_version_flag is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Current Version Flag should not be null';
        END   IF;  */ 

----    Validate Enquiry Created By Party ID
        exists_flag  :=  null;
        BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    cmn_employee_master_v
                WHERE   party_id     =   p_req_created_by_party_id
                AND     client_id    =   p_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code     := 2;
                        p_return_message  := p_return_message || ' - ' ||
                                            'Invalid Created By Party ID Passed';
                WHEN    OTHERS
                THEN    p_return_code     := 2;
                        p_return_message  := p_return_message || ' - ' ||
                                            'Invalid Created By Party ID Passed';
        END;
        DBMS_OUTPUT.put_line ('Validating Created By '||p_return_code||' - '||p_return_message);

----    Validate Associated Call ID
        exists_flag  :=  null;
        IF (p_associated_call_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    crm_calls
                    WHERE   call_id     =   p_associated_call_id
                    AND     client_id   =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code     := 2;
                            p_return_message  := p_return_message || ' - ' ||
                                                'Invalid Call ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code     := 2;
                            p_return_message  := p_return_message || ' - ' ||
                                                'Invalid Call ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Associated Call '||p_return_code||' - '||p_return_message);

----    Validate Request Type Set ID
        exists_flag  :=  null;
        IF (p_req_type_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id        =   p_req_type_set_id
                    AND     client_id          =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code     := 2;
                            p_return_message  := p_return_message || ' - ' ||
                                                'Invalid Request Type Set ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code     := 2;
                            p_return_message  := p_return_message || ' - ' ||
                                                'Invalid Request Type Set ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Request Type Set '||p_return_code||' - '||p_return_message);

----    Validate Request Type Code ID
        exists_flag  :=  null;
        IF (p_req_type_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   category_id          =   p_req_type_set_id
                    AND     sub_category_id      =   p_req_type_code_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Request Type Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Request Type Code ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Request Type Code '||p_return_code||' - '||p_return_message);

----    Validate Req Class Set ID
        IF (p_req_class_set_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    cmn_category_master
                WHERE   category_id          =   p_req_class_set_id
                AND     client_id            =   p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=   2;
                        p_return_message    :=   p_return_message || ' - ' ||
                                                'Invalid Req Class Set ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Req Class Set ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating request Class Set '||p_return_code||' - '||p_return_message);

----    Validate Req Class Code ID
        IF (p_req_class_code_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    cmn_sub_category_master
                WHERE   category_id          =  p_req_class_set_id
                AND     sub_category_id      =  p_req_class_code_id
                AND     client_id            =  p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Req Class code ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Req class code ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating request Class Code '||p_return_code||' - '||p_return_message);

----    Validate Sales Representative ID
        exists_flag  :=  null;
        IF  (p_salesrep_id is not null)
        THEN
                BEGIN  
                        SELECT  'Y'
                        INTO    exists_flag
                        FROM    om_sales_persons       osp
                        WHERE   salesrep_id        =   p_salesrep_id
                        AND     client_id          =   p_client_id;
                EXCEPTION
                        WHEN    NO_DATA_FOUND
                        THEN    p_return_code       :=   2;
                                p_return_message    :=   p_return_message || ' - ' ||
                                                        'Invalid Sales Representative ID Passed';
                        WHEN    OTHERS
                        THEN    p_return_code       :=   2;
                                p_return_message    :=   p_return_message || ' - ' ||
                                                        'Invalid Sales Representative ID Passed';
                END;
        END IF;

----    Validate Market Segment Category ID
        exists_flag  :=  null;
        IF (p_ms_category_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id          =   p_ms_category_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Market Segment Category ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Market Segment Category ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating MS Category Set '||p_return_code||' - '||p_return_message);

----    Validate Market Segment Sub Category ID
        exists_flag  :=  null;
        IF (p_ms_sub_category_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   sub_category_id      =   p_ms_sub_category_id
                    AND     category_id          =   p_ms_category_id     
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Market Segment Sub Category ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Market Segment Sub Category ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating MS Category Code '||p_return_code||' - '||p_return_message);

----    Validate Application Segment Category ID
        exists_flag  :=  null;
        IF (p_as_category_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id          =   p_as_category_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Application Segment Category ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Application Segment Category ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating AS Category Set '||p_return_code||' - '||p_return_message);

----    Validate Application Segment Sub Category ID
        exists_flag  :=  null;
        IF (p_as_sub_category_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   sub_category_id      =   p_as_sub_category_id
                    AND     category_id          =   p_as_category_id     
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Application Segment Sub Category ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Application Segment Sub Category ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating AS Category Code '||p_return_code||' - '||p_return_message);

----    Validate Plan Header ID
        IF (p_plan_header_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    epb_plan_headers
                WHERE   plan_header_id       =   p_plan_header_id
                AND     client_id            =   p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Plan Header ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Plan Header ID Passed';
            END;
        END IF;

----    Validate Plan Detail ID
        IF (p_plan_detail_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    epb_plan_details
                WHERE   plan_detail_id       =   p_plan_detail_id
                AND     plan_header_id       =   p_plan_header_id
                AND     client_id            =   p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Plan Detail ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Plan Detail ID Passed';
            END;
        END IF;

----    Validate Budget ID
        IF (p_budget_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    fins_gl_budgets
                WHERE   budget_id            =   p_budget_id
                AND     client_id            =   p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Budget ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Budget ID Passed';
            END;
        END IF;

----    Validate Budget Line ID
        IF (p_budget_line_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    fins_gl_budget_lines
                WHERE   budget_line_id       =   p_budget_line_id
                AND     budget_id            =   p_budget_id
                AND     client_id            =   p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Budget Line ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Budget Line ID Passed';
            END;
        END IF;

----    Validate Project ID
        IF (p_project_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    pam_projects_all
                WHERE   project_id           =   p_project_id
                AND     client_id            =   p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Project ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Project ID Passed';
            END;
        END IF;

----    Validate Project Task ID
        IF (p_project_task_id is not null)
        THEN
            BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    pam_project_tasks
                WHERE   project_task_id      =   p_project_task_id
                AND     project_id           =   p_project_id
                AND     client_id            =   p_client_id;
            EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Project Task ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Project Task ID Passed';
            END;
        END IF;

----    Validate Organization ID
        exists_flag  :=  null;
        IF (p_organization_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_organization_master
                    WHERE   organization_id      =   p_organization_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Organization ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Organization ID Passed';
            END;
        END IF;

----    Validate LOB ID
        exists_flag  :=  null;
        IF (p_lob_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_lob_master
                    WHERE   lob_id               =   p_lob_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid LOB ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid LOB ID Passed';
            END;
        END IF;

----    Validate Profit Centre ID
        exists_flag  :=  null;
        IF (p_profit_centre_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_profit_centre_master
                    WHERE   profit_centre_id     =   p_profit_centre_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Profit Centre ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Profit Centre ID Passed';
            END;
        END IF;

----    Validate Region ID
        exists_flag  :=  null;
        IF (p_region_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_region_master
                    WHERE   region_id            =   p_region_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Region ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Region ID Passed';
            END;
        END IF;

----    Validate Branch ID
        exists_flag  :=  null;
        IF (p_branch_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_branch_master
                    WHERE   branch_id            =   p_branch_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Branch ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Branch ID Passed';
            END;
        END IF;

----    Validate Enquiry Subject
    /*    IF    (p_requirement_subject is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Enquiry Subject should not be null';
        END   IF; */

----    Validate Requirement By Party ID
        exists_flag  :=  null;
        IF (p_req_by_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y',
                            party_combination_id
                    INTO    exists_flag,
                            v_customer_party_combination_id
                    FROM    cmn_party_combinations_v
                    WHERE   party_id             =   p_req_by_party_id
                    and     upper(trim(party_type_code))   IN    ('PROSPECT', 'CUSTOMER')
                    and     (end_date  is null
                             or
                             end_date  >  sysdate+1
                            )
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                   'Invalid Requirement By Party ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Requirement By Party ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Required By PArty '||p_return_code||' - '||p_return_message);

----    Validate Requirement By Contact ID
        exists_flag  :=  null;
        IF (p_req_by_contact_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_party_contacts
                    WHERE   party_contact_id     =   p_req_by_contact_id
                    AND     party_id             =   p_req_by_party_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                   'Invalid Requirement By Contact ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Requirement By Contact ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating required By Contact '||p_return_code||' - '||p_return_message);

----    Validate Source Type Set ID
        exists_flag  :=  null;
        IF (p_source_type_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id        =   p_source_type_set_id
                    AND     client_id          =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code     := 2;
                            p_return_message  := p_return_message || ' - ' ||
                                                'Invalid Source Type Set ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code     := 2;
                            p_return_message  := p_return_message || ' - ' ||
                                                'Invalid Source Type Set ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Source Type Set '||p_return_code||' - '||p_return_message);

----    Validate Source Type Code ID
        exists_flag  :=  null;
        IF (p_source_type_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   category_id          =   p_source_type_set_id
                    AND     sub_category_id      =   p_source_type_code_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Source Type Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Source Type Code ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Source Type Code '||p_return_code||' - '||p_return_message);

----    Validate Shipment Method Set ID
        exists_flag  :=  null;
        IF (p_shipment_method_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id          =  p_shipment_method_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Shipment Method Set ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                   'Invalid Shipment Method Set ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Shipment Method Set '||p_return_code||' - '||p_return_message);

----    Validate Shipment Method Code ID
        exists_flag  :=  null;
        IF (p_shipment_method_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   category_id          =   p_shipment_method_set_id
                    AND     sub_category_id      =   p_shipment_method_code_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Shipment Method Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Shipment Method Code ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Shipment Method Code '||p_return_code||' - '||p_return_message);

----    Validate Freight Carrier Set ID
        exists_flag  :=  null;
        IF (p_freight_carrier_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id          =  p_freight_carrier_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                   'Invalid Freight Carrier Set ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                   'Invalid Freight Carrier Set ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Freight Method Set '||p_return_code||' - '||p_return_message);

----    Validate Freight Carrier Code ID
        exists_flag  :=  null;
        IF (p_freight_carrier_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   category_id          =   p_freight_carrier_set_id
                    AND     sub_category_id      =   p_freight_carrier_code_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Freight Carrier Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Freight Carrier Code ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Freight Method Code '||p_return_code||' - '||p_return_message);

----    Validate Shipment Priority ID
        exists_flag  :=  null;
        IF (p_shipment_priority_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_priority_master
                    WHERE   priority_id          =   p_shipment_priority_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Shipment Priority ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Shipment Priority ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Shipment Priority ID '||p_return_code||' - '||p_return_message);

----    Validate Requirement By 'Bill_To' ID
        exists_flag  :=  null;
        IF (p_req_by_bill_to_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_party_sites_master_v
                    WHERE   1    =    1
                    AND     party_site_id        =   p_req_by_bill_to_id
----                    AND     profit_centre_id     =   p_profit_centre_id
----                 AND     lob_id               =   p_lob_id
----                    AND     organization_id      =   p_organization_id
                    AND     party_id             =   p_req_by_party_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Bill_To ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Bill_To ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Bill To '||p_return_code||' - '||p_return_message);

----    Validate Requirement By 'Ship_To' ID
        exists_flag  :=  null;
        IF (p_req_by_ship_to_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_party_sites_master_v
                    WHERE   1    =   1
                    AND     party_site_id        =   p_req_by_ship_to_id
----                    AND     profit_centre_id     =   p_profit_centre_id
----                    AND     lob_id               =   p_lob_id
---                    AND     organization_id      =   p_organization_id
                    AND     party_id             =   p_req_by_party_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Ship_To ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Ship_To ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Ship To '||p_return_code||' - '||p_return_message);

----    Validate Application ID
        exists_flag  :=  null;
        IF (p_application_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_applications_master_v
                    WHERE   application_id       =   p_application_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Application ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Application ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Application ID '||p_return_code||' - '||p_return_message);

----    Validate Payment Term ID
        exists_flag  :=  null;
        IF (p_payment_term_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    fins_payment_terms
                    WHERE   payment_term_id      =   p_payment_term_id
                    AND     client_id            =   p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Payment Term ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=   2;
                            p_return_message    :=   p_return_message || ' - ' ||
                                                    'Invalid Payment Term ID Passed';
            END;
        END IF;
        DBMS_OUTPUT.put_line ('Validating Payment '||p_return_code||' - '||p_return_message);

----    Validate Status ID
        exists_flag  :=  null;
        BEGIN  
            SELECT  'Y'
            INTO    exists_flag
            FROM    cmn_status_master
            WHERE   status_id            =   p_status_id
            AND     client_id            =   p_client_id;
        EXCEPTION
            WHEN    NO_DATA_FOUND
            THEN    p_return_code       :=   2;
                    p_return_message    :=   p_return_message || ' - ' ||
                                            'Invalid Status ID Passed';
            WHEN    OTHERS
            THEN    p_return_code       :=   2;
                    p_return_message    :=   p_return_message || ' - ' ||
                                            'Invalid Status ID Passed';
        END;

---    validating transaction_type_code
        BEGIN
                SELECT  transaction_type_code,
                        application_id
                INTO    v_transaction_type_code,
                        v_application_id
                FROM    cmn_transaction_types           ctt
                WHERE   1                       =       1
                AND     ctt.transaction_type_id =      p_transaction_type_id
                AND     ctt.client_id           =      p_client_id;
        EXCEPTION
                WHEN   OTHERS
                THEN   v_transaction_type_code  := null;
        END;

---- crm action history set
        BEGIN  
            SELECT  category_id
            INTO    v_crm_action_set_id
            FROM    cmn_category_master_v
            WHERE   upper(trim(type_set_code))    =   'ACTION_HISTORY_SET'
            AND     upper(trim(category_code))    =   'CRM_ACTIONS_SET'
            AND     client_id            =  p_client_id;
        EXCEPTION
            WHEN    NO_DATA_FOUND
            THEN    p_return_code       :=  2;
                    p_return_message    :=  p_return_message || ' - ' ||
                                            'Invalid Action Set NO DATA FOUND';
            WHEN    OTHERS
            THEN    p_return_code       :=  2;
                    p_return_message    :=  p_return_message || ' - ' ||
                                            'Invalid Action Set OTHERS';
        END;



        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'All Validations done ... Getting Fiscal Year');
        DBMS_OUTPUT.put_line ('All Validations done ... getting Fiscal_year '||p_return_code||' - '||p_return_message);

----    Verify if thre is an error, if yes then raise exception and exit out
        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

----    Populate Fiscal Year
        BEGIN
            SELECT   fiscal_year
            INTO     v_fiscal_yr
            FROM     cmn_operating_periods
            WHERE    1                    =   1
            AND      period_start_date   <=   sysdate   
            AND      period_end_date     >=   sysdate 
            AND      client_id            =   p_client_id;
        EXCEPTION
            WHEN    NO_DATA_FOUND
            THEN    v_fiscal_yr     :=   null; 

            WHEN    OTHERS
            THEN    v_fiscal_yr     :=   null;         
        END;

        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'All Validations done ... Got Fiscal Year');
        DBMS_OUTPUT.put_line ('All Validations done ... Got Fiscal_year '||v_fiscal_yr||p_return_code||' - '||p_return_message);

----    Take Action according to p_action variable
        IF    ( upper(p_action) in ('I','A','C')) 
        THEN
/*            --  First generate sequence for requirement id.
              BEGIN
                SELECT  crm_requirement_headers_seq.nextval
                INTO    p_requirement_id
                FROM    dual;
              EXCEPTION
                WHEN    OTHERS
                THEN    p_requirement_id   :=   null;
              END;

              ----  Generate sequence for SR_NO
              BEGIN
               SELECT  crm_enquiry_headers_seq.nextval
               INTO    v_sr_no
               FROM    dual;
              EXCEPTION
                   WHEN    OTHERS
                   THEN    v_sr_no    :=  null; 
              END; 
*/

---------   call action code
                BEGIN  
                    SELECT  sub_category_id
                    INTO    v_crm_action_code_id
                    FROM    cmn_sub_category_master_v
                    WHERE   upper(trim(sub_category_code))    =   'ENQUIRY_CREATED'
                    AND     category_id          =  v_crm_action_set_id
                    AND     client_id            =  p_client_id;
                EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Action Code NO DATA';
                            RETURN;
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Action Code OTHERS ' ||SQLERRM;
                            RETURN;
                END;

----          Get Sequence for CRM Enquiry ID
              Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'All Validations done ... Generating Enquiry Key');
              DBMS_OUTPUT.put_line ('All Validations done ... Generating Enquiry Key');

              p_requirement_id  :=   Get_Sequence_ID 
                                        (   p_client_id, 
                                            p_organization_id,
                                            p_lob_id,
                                            p_profit_centre_id,
                                            upper('CRM_REQUIREMENT_HEADERS')
                                        );
              commit;

              IF      (p_requirement_id <  0)
              THEN    p_return_code     := 2;
                      p_return_message  := p_return_message ||  ' - '  ||
                      'CRM Enquiry (Requirement) ID Can not be Generated..';
              END     IF;
              Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'All Validations done ... Generated Enquiry Key');
              DBMS_OUTPUT.put_line ('All Validations done ... Generated Enquiry Key '||p_requirement_id);

----          Get Sequence for CRM Enquiry Number
              v_sr_no           :=   Get_Sequence_ID 
                                        (   p_client_id, 
                                            p_organization_id,
                                            p_lob_id,
                                            p_profit_centre_id,
                                        --     upper('CRM_ENQUIRY_HEADERS')
                                            upper(v_transaction_type_code)
                                        );
              commit;

              IF      (v_sr_no < 0)
              THEN    p_return_code     := 2;
                      p_return_message  := p_return_message ||  ' - '  ||
                      'CRM Enquiry (Requirement) Number Can not be Generated..';
              END     IF;

----      Calculate fiscal_year_start and fiscal_year_end_date
          BEGIN 
               SELECT    to_char(to_date('01-APR-'||EXTRACT (YEAR FROM ADD_MONTHS (sysdate, -3)),'DD-MON-YYYY'),'DD-MON-YYYY'),
                         to_char(to_date('31-MAR-'||EXTRACT (YEAR FROM ADD_MONTHS (sysdate,  9)),'DD-MON-YYYY'),'DD-MON-YYYY')
               INTO      fiscal_year_start_date,
                         fiscal_year_end_date
               FROM      DUAL;
          EXCEPTION
               WHEN      OTHERS
               THEN      fiscal_year_start_date  :=  null;
                         fiscal_year_end_date    :=  null;
          END;

----            getting prefix from cmn_transaction type
                BEGIN
                        SELECT    document_prefix,
                                  document_sufix
                        INTO      v_prefix,
                                  v_suffix
                        FROM      cmn_table_sequences
                        WHERE     1                     =       1
                        AND       upper(table_name)     =      upper(v_transaction_type_code)
                        AND      to_date(sysdate)   >=      to_date(nvl(start_date,fiscal_year_start_date))
                        AND      to_date(sysdate)   <=      to_date(nvl(end_date,fiscal_year_end_date))
                        AND       start_date               is not  null
                        AND       profit_centre_id      =      p_profit_centre_id
                        AND       lob_id                =      p_lob_id
                        AND       organization_id       =      p_organization_id
                        AND       client_id             =      p_client_id;
                EXCEPTION
                        WHEN    OTHERS
                        THEN    v_prefix        :=    null;
                                v_suffix        :=    null;
                END;

----          Create Enquiry Number
              BEGIN
                SELECT  v_prefix || v_sr_no || v_suffix
                INTO    p_requirement_number
                FROM    dual;
              EXCEPTION
                WHEN    OTHERS
                THEN    p_requirement_number   :=   null;  
              END;     

----          Now insert data into 'crm_requirement_headers'
              BEGIN
                INSERT INTO crm_requirement_headers
                 (      CREATION_DATE,
                        CREATED_BY,
                        LAST_UPDATE_DATE,
                        LAST_UPDATED_BY,
                        START_DATE,
                        END_DATE,
                        CLIENT_ID,
                        APPLICATION_ID,         
                        REQUIREMENT_ID,
                        PARENT_REQUIREMENT_ID,
                        REQUIREMENT_NUMBER,
                        RECEIVED_DATE,
                        EXPIRATION_DATE,
                        VERSION_NUMBER,
                        CURRENT_VERSION_FLAG,
                        REQ_CREATED_BY_PARTY_ID,
                        ASSOCIATED_CALL_ID,
                        ASSOCIATED_LEAD_ID,
                        REQ_TYPE_SET_ID,
                        REQ_TYPE_CODE_ID,
                        REQ_CLASS_SET_ID,
                        REQ_CLASS_CODE_ID,
                        MS_CATEGORY_ID,
                        MS_SUB_CATEGORY_ID,
                        AS_CATEGORY_ID,
                        AS_SUB_CATEGORY_ID,
                        TRANSACTION_TYPE_ID,
                        PAYMENT_TERM_ID,
                        CONVERSION_DATE,
                        CONVERSION_RATE,
                        PLAN_HEADER_ID,
                        PLAN_DETAIL_ID,
                        BUDGET_ID,
                        BUDGET_LINE_ID,
                        PROJECT_ID,
                        PROJECT_TASK_ID,
                        ORGANIZATION_ID,
                        LOB_ID,
                        PROFIT_CENTRE_ID,
                        REGION_ID,
                        BRANCH_ID,
                        SALESREP_ID,
                        REQUIREMENT_SUBJECT, 
                        REQUIREMENT_DETAILS,
                        REQ_BY_PARTY_ID,
                        REQ_BY_CONTACT_ID,
                        REQ_BY_BILL_TO_ID,
                        REQ_BY_SHIP_TO_ID,
                        SOURCE_TYPE_SET_ID,         
                        SOURCE_TYPE_CODE_ID,
                        SOURCE_DOCUMENT_NUMBER,
                        SOURCE_DOCUMENT_DATE,
                        REFERENCE_NUMBER_1,
                        REFERENCE_DATE_1,
                        REFERENCE_NUMBER_2,
                        REFERENCE_DATE_2,
                        REQUIRED_BY_DATE,
                        SHIPMENT_PRIORITY_ID,
                        SHIPMENT_METHOD_SET_ID,
                        SHIPMENT_METHOD_CODE_ID,
                        FREIGHT_CARRIER_SET_ID,
                        FREIGHT_CARRIER_CODE_ID,
                        CUSTOMER_BUDGET_AMOUNT,
                        STATUS_ID,
                        STATUS_DATE
                 )
                 VALUES
                 (      sysdate,
                        nvl(p_user_id, 0),
                        sysdate,
                        nvl(p_user_id, 0),
                        p_start_date,
                        p_end_date,
                        p_client_id,
                        p_application_id,
                        p_requirement_id,
                        p_parent_requirement_id,
                        p_requirement_number,
                        p_received_date,
                        p_expiration_date,
                        p_version_number,
                        p_current_version_flag,
                        p_req_created_by_party_id,
                        p_associated_call_id,
                        p_associated_lead_id,
                        p_req_type_set_id,
                        p_req_type_code_id,
                        p_req_class_set_id,
                        p_req_class_code_id,
                        p_ms_category_id,
                        p_ms_sub_category_id,
                        p_as_category_id,
                        p_as_sub_category_id,
                        p_transaction_type_id,
                        p_payment_term_id,
                        nvl(p_conversion_date,sysdate),
                        nvl(p_conversion_rate,1),
                        p_plan_header_id,
                        p_plan_detail_id,
                        p_budget_id,
                        p_budget_line_id,
                        p_project_id,
                        p_project_task_id,
                        p_organization_id,
                        p_lob_id,
                        p_profit_centre_id,
                        p_region_id,
                        p_branch_id,
                        p_salesrep_id,
                        p_requirement_subject,
                        p_requirement_details,
                        p_req_by_party_id,
                        p_req_by_contact_id,
                        p_req_by_bill_to_id,
                        p_req_by_ship_to_id,
                        p_source_type_set_id,
                        p_source_type_code_id,
                        p_source_document_number,
                        p_source_document_date,
                        p_reference_number_1,
                        p_reference_date_1,
                        p_reference_number_2,
                        p_reference_date_2,
                        p_required_by_date,
                        p_shipment_priority_id,
                        p_shipment_method_set_id,
                        p_shipment_method_code_id,
                        p_freight_carrier_set_id,
                        p_freight_carrier_code_id,
                        nvl(p_customer_budget_amount,0),
                        p_status_id,
                        p_status_date
                 );
                commit;

----          Set / UUpdate Sequence for CRM Lead (Requirement) ID
              IF      ( SET_Sequence_ID 
                        (  p_client_id,
                           p_organization_id,
                           p_lob_id,
                           p_profit_centre_id,
                           upper('CRM_REQUIREMENT_HEADERS'), 
                           p_requirement_id
                        )
                      )
              THEN    commit;
              ELSE    p_return_code     := 2;
                      p_return_message  := p_return_message ||  ' - '  ||
                                          'CRM Enquiry (Requirement) ID Sequence Can not be Updated..';
              END     IF;
----          Set / UUpdate Sequence for CRM Lead (Requirement) Number
              IF      ( SET_Sequence_ID 
                        (  p_client_id,
                           p_organization_id,
                           p_lob_id,
                           p_profit_centre_id,
                        --    upper('CRM_ENQUIRY_HEADERS'),
                           upper(v_transaction_type_code),
                           v_sr_no
                        )
                      )
              THEN    commit;
              ELSE    p_return_code     := 2;
                      p_return_message  := p_return_message ||  ' - '  ||
                                          'CRM Enquiry (Requirement) Number Sequence Can not be Updated..';
              END     IF;

              EXCEPTION
                   WHEN    OTHERS
                   THEN    p_return_code       :=  2;
                           p_return_message    :=  p_return_message ||  ' - '  ||
                                               'Unable to create Record ' || SQLERRM;
                           raise  Some_Error;
                           RETURN;
              END;

----      Calling CMN_ACTION_HISTROY_API to record this action in it
               BEGIN
                    CMN_MAINTAIN_ACTION_HISTORY_API
                    (       p_return_code                                  =>    p_return_code,
                            p_return_message                               =>    p_return_message,
                            p_action                                       =>    'I',
                            p_user_id                                      =>    p_user_id,
                            p_start_date                                   =>    sysdate,
                            p_end_date                                     =>    null,
                            p_place_lattitude                              =>    null,
                            p_place_longitude                              =>    null,
                            p_place_ip_address                             =>    null,
                            p_action_id                                    =>    v_action_id,
                            p_client_id                                    =>    p_client_id,
                            p_application_id                               =>    v_application_id,
                            p_organization_id                              =>    p_organization_id,
                            p_lob_id                                       =>    p_lob_id,
                            p_profit_centre_id                             =>    p_profit_centre_id,
                            p_department_id                                =>    null,
                            p_region_id                                    =>    null,
                            p_branch_id                                    =>    null,
                            p_application_process_seq                      =>    null,
                            p_source_transaction_type_id                   =>    p_transaction_type_id,
                            p_source_document_number                       =>    p_requirement_number,
                            p_source_document_date                         =>    p_received_date,
                            p_source_document_name                         =>    p_requirement_number,
                            p_source_document_description                  =>    null,
                            p_action_type_set_id                           =>    v_crm_action_set_id,
                            p_action_type_code_id                          =>    v_crm_action_code_id,
                            p_source_document_header_id                    =>    p_requirement_id,
                            p_source_document_line_id                      =>    null,
                            p_source_party_id                              =>    p_req_by_party_id,
                            p_source_party_combination_id                  =>    v_customer_party_combination_id,
                            p_action_requested_by_party_id                 =>    v_user_party_id,
                            p_action_by_party_id                           =>    v_user_party_id,
                            p_action_approved_by_party_id                  =>    null,
                            p_action_taken_date                            =>    sysdate,
                            p_action_note                                  =>    'Enquiry Header Created with Enquiry Number - '||p_requirement_number,
                            p_reason_set_id                                =>    p_reason_set_id,
                            p_reason_code_id                               =>    p_reason_code_id,
                            p_reason_note                                  =>    p_reason_note

                    );
                      commit;
               EXCEPTION
                    WHEN      OTHERS
                    THEN      p_return_code       :=   2;
                              p_return_message    :=   p_return_message||' - '||'Some Error in creating Action History for PO Header';
                              RETURN;
               END; ---- End of CMN_ACTION_HISTORY_API

          DBMS_OUTPUT.put_line ('Error - '||p_return_message);


        ELSE

---------   call action code
                BEGIN  
                    SELECT  sub_category_id
                    INTO    v_crm_action_code_id
                    FROM    cmn_sub_category_master_v
                    WHERE   upper(trim(sub_category_code))    =   'ENQUIRY_UPDATED'
                    AND     category_id          =  v_crm_action_set_id
                    AND     client_id            =  p_client_id;
                EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Action Code NO DATA';
                            RETURN;
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Action Code OTHERS ' ||SQLERRM;
                            RETURN;
                END;

            BEGIN
                UPDATE  crm_requirement_headers 
                SET     last_update_date              =   sysdate,
                        last_updated_by               =   nvl(p_user_id, 0),
                        start_date                    =   p_start_date,
                        end_date                      =   p_end_date,
                        parent_requirement_id         =   p_parent_requirement_id,
                        received_date                 =   p_received_date,
                        expiration_date               =   p_expiration_date,
                        version_number                =   p_version_number,
                        current_version_flag          =   p_current_version_flag,
                        associated_call_id            =   p_associated_call_id,
                        associated_lead_id            =   p_associated_lead_id,
                        req_class_code_id             =   p_req_class_code_id,
                        ms_category_id                =   p_ms_category_id,
                        ms_sub_category_id            =   p_ms_sub_category_id,
                        as_category_id                =   p_as_category_id,
                        as_sub_category_id            =   p_as_sub_category_id,
                        payment_term_id               =   p_payment_term_id,
                        conversion_date               =   nvl(p_conversion_date,sysdate),
                        conversion_rate               =   nvl(p_conversion_rate,1),
                        plan_header_id                =   p_plan_header_id,
                        plan_detail_id                =   p_plan_detail_id,
                        budget_id                     =   p_budget_id,
                        budget_line_id                =   p_budget_line_id,
                        project_id                    =   p_project_id,
                        project_task_id               =   p_project_task_id,
                        organization_id               =   p_organization_id,
                        lob_id                        =   p_lob_id,
                        profit_centre_id              =   p_profit_centre_id,
                        region_id                     =   p_region_id,
                        branch_id                     =   p_branch_id,
                        salesrep_id                   =   p_salesrep_id,
                        requirement_subject           =   p_requirement_subject,
                        requirement_details           =   p_requirement_details,
                        req_by_party_id               =   p_req_by_party_id,
                        req_by_contact_id             =   p_req_by_contact_id,
                        req_by_bill_to_id             =   p_req_by_bill_to_id,
                        req_by_ship_to_id             =   p_req_by_ship_to_id,
                        source_type_set_id            =   p_source_type_set_id,
                        source_type_code_id           =   p_source_type_code_id,
                        source_document_number        =   p_source_document_number,
                        source_document_date          =   p_source_document_date,
                        reference_number_1            =   p_reference_number_1,
                        reference_date_1              =   p_reference_date_1,
                        reference_number_2            =   p_reference_number_2,
                        reference_date_2              =   p_reference_date_2,
                        required_by_date              =   p_required_by_date,
                        shipment_priority_id          =   p_shipment_priority_id,
                        shipment_method_set_id        =   p_shipment_method_set_id,
                        shipment_method_code_id       =   p_shipment_method_code_id,
                        freight_carrier_set_id        =   p_freight_carrier_set_id,
                        freight_carrier_code_id       =   p_freight_carrier_code_id,
                        customer_budget_amount        =   p_customer_budget_amount,
                        status_id                     =   p_status_id,
                        status_date                   =   p_status_date
                WHERE   1                             =   1
                AND     requirement_id                =   p_requirement_id
                AND     client_id                     =   p_client_id;
                commit;  
            EXCEPTION 
                WHEN    OTHERS
                THEN    p_return_code       := 2;
                        p_return_message    := p_return_message ||  ' - '  ||
                                                'Unable to Update Record ' || SQLERRM;
                        raise  Some_Error;
                        RETURN;
            END; 

----      Calling CMN_ACTION_HISTROY_API to record this action in it
               BEGIN
                    CMN_MAINTAIN_ACTION_HISTORY_API
                    (       p_return_code                                  =>    p_return_code,
                            p_return_message                               =>    p_return_message,
                            p_action                                       =>    'I',
                            p_user_id                                      =>    p_user_id,
                            p_start_date                                   =>    sysdate,
                            p_end_date                                     =>    null,
                            p_place_lattitude                              =>    null,
                            p_place_longitude                              =>    null,
                            p_place_ip_address                             =>    null,
                            p_action_id                                    =>    v_action_id,
                            p_client_id                                    =>    p_client_id,
                            p_application_id                               =>    v_application_id,
                            p_organization_id                              =>    p_organization_id,
                            p_lob_id                                       =>    p_lob_id,
                            p_profit_centre_id                             =>    p_profit_centre_id,
                            p_department_id                                =>    null,
                            p_region_id                                    =>    null,
                            p_branch_id                                    =>    null,
                            p_application_process_seq                      =>    null,
                            p_source_transaction_type_id                   =>    p_transaction_type_id,
                            p_source_document_number                       =>    p_requirement_number,
                            p_source_document_date                         =>    p_received_date,
                            p_source_document_name                         =>    p_requirement_number,
                            p_source_document_description                  =>    null,
                            p_action_type_set_id                           =>    v_crm_action_set_id,
                            p_action_type_code_id                          =>    v_crm_action_code_id,
                            p_source_document_header_id                    =>    p_requirement_id,
                            p_source_document_line_id                      =>    null,
                            p_source_party_id                              =>    p_req_by_party_id,
                            p_source_party_combination_id                  =>    v_customer_party_combination_id,
                            p_action_requested_by_party_id                 =>    v_user_party_id,
                            p_action_by_party_id                           =>    v_user_party_id,
                            p_action_approved_by_party_id                  =>    null,
                            p_action_taken_date                            =>    sysdate,
                            p_action_note                                  =>    'Enquiry Header Updated with Enquiry Number - '||p_requirement_number,
                            p_reason_set_id                                =>    p_reason_set_id,
                            p_reason_code_id                               =>    p_reason_code_id,
                            p_reason_note                                  =>    p_reason_note

                    );
                      commit;
               EXCEPTION
                    WHEN      OTHERS
                    THEN      p_return_code       :=   2;
                              p_return_message    :=   p_return_message||' - '||'Some Error in creating Action History for PO Header';
                              RETURN;
               END; ---- End of CMN_ACTION_HISTORY_API

          DBMS_OUTPUT.put_line ('Error - '||p_return_message);
        END   IF;

        p_return_code      :=  0;
        p_return_message   :=  'Creation / Updation CRM Enquiry Headers is Successful '|| p_requirement_number;
        Apex_Util.Set_Session_State('LOGIN_MESSAGE' ,'Execution Successful for Maintaining CRM Enquiry Headers');
        DBMS_OUTPUT.put_line ('Execution Successful for Maintaining CRM Enquiry Headers');
        RETURN;

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
END     CRM_ACD_ENQUIRY_HEADER_API;
-----------------------------------------------------------------------------------------------------------------------------------------
