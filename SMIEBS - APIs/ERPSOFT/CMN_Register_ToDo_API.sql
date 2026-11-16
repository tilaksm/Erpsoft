--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Create Coruses- Calendar   
--- -     Written by    : Shriniwas Tilak
-----     Date Written  : 17th April 2021 
-----     Modified V1   : 02-DEC-2023
-----     V1 Modified on: Change cmn_party_master to respective view
---------------------------------------------------------------------------------------------------------------------------------
----      Registering To Do API
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE CMN_REGISTER_TODO_API 
    (       p_return_code                  OUT  VARCHAR2,
            p_return_message               OUT  VARCHAR2,
            p_action                        IN  VARCHAR2,
            p_user_id                       IN  NUMBER,
            p_start_date                    IN  DATE,
            p_end_date                      IN  DATE,
            p_client_id                     IN  NUMBER,
            p_todo_id                   IN OUT  NUMBER,
            p_parent_todo_id                IN  NUMBER,
            p_todo_number                   IN  VARCHAR2,
            p_todo_creation_date            IN  DATE,
            p_todo_subject                  IN  VARCHAR2,
            p_todo_details                  IN  VARCHAR2,
            p_source_transaction_type_id    IN  NUMBER,
            p_source_transaction_number     IN  VARCHAR2,
            p_source_transaction_date       IN  DATE,
            p_source_table_name             IN  VARCHAR2,
            p_source_table_pk_id            IN  NUMBER,
            p_todo_creation_party_id        IN  NUMBER,
            p_todo_owner_party_id           IN  NUMBER,
            p_todo_assigned_to_party_id     IN  NuMBER,
            p_todo_actioned_by_party_id     IN  NUMBER,
            p_todo_closed_by_party_id       IN  NUMBER,
            p_todo_for_customer_party_id    IN  NUMBER,
            p_todo_for_vendor_party_id      IN  NUMBER,
            p_plan_start_date               IN  DATE,
            p_plan_completion_date          IN  DATE,
            p_required_by_date              IN  DATE,
            p_due_date                      IN  DATE,
            p_planned_activity              IN  VARCHAR2,
            p_planned_efforts_days          IN  NUMBER,
            p_planned_efforts_hours         IN  NUMBER,
            p_planned_material_expenses     IN  NUMBER,
            p_planned_labour_expenses       IN  NUMBER,
            p_planned_other_expenses        IN  NUMBER,
            p_actual_start_date             IN  DATE,
            p_actual_completion_date        IN  DATE,
            p_actual_activity               IN  VARCHAR2,
            p_actual_efforts_days           IN  NUMBER,
            p_actual_efforts_hours          IN  NUMBER,
            p_actual_material_expenses      IN  NUMBER,
            p_actual_labour_expenses        IN  NUMBER,
            p_actual_other_expenses         IN  NUMBER,
            p_organization_id               IN  NUMBER,
            p_lob_id                        IN  NUMBER,
            p_profit_centre_id              IN  NUMBER,
            p_department_id                 IN  NUMBER,
            p_region_id                     IN  NUMBER,
            p_branch_id                     IN  NUMBER,
            p_plan_header_id                IN  NUMBER,
            p_plan_detail_id                IN  NUMBER,
            p_budget_id                     IN  NUMBER,
            p_budget_line_id                IN  NUMBER,
            p_project_id                    IN  NUMBER,
            p_project_task_id               IN  NUMBER,
            p_todo_type_set_id              IN  NUMBER,
            p_todo_type_code_id             IN  NUMBER,
            p_value_linkage_set_id          IN  NUMBER,
            p_value_linkage_code_id         IN  NUMBER,
            p_MIR_Linkage_set_id            IN  NUMBER,
            p_MIR_Linkage_code_id           IN  NUMBER,
            p_PQDSE_Linkage_set_id          IN  NUMBER,
            p_PQDSE_Linkage_Code_id         IN  NUMBER,
            p_TQM_linkage_set_id            IN  NUMBER,
            p_TQM_Linkage_code_id           IN  NUMBER,
            p_status_id                     IN  NUMBER,
            p_status_date                   IN  DATE
    )   

    AS

----    Declare Variables and Cursors required for generation
        err_message           varchar2(200)  :=  null;
        exists_flag           varchar2(01)   :=  null;
        dummy_flag            varchar2(01)   :=  null;
        recs_added            number         :=  0;
        vtodo_seq             number         :=  0;
        vtodo_number          varchar2(50)   :=  null;
        v_source_table_name   varchar2(30)   :=  null;

----    Define Exceptions
        Some_Error            EXCEPTION;

BEGIN
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started for Maintaining todo Master');
        DBMS_OUTPUT.put_line ('Execution Started for Maintaining todo Master');

----    Start of Maintaining todo Master
        p_return_code          := 0;                    ----  Successful Execution
        p_return_message       := ' '; 

----    First check the mode of operations
        CASE  upper(p_action)
        WHEN  'I'   THEN  null;
        WHEN  'A'   THEN  null;
        WHEN  'C'   THEN  null;
        WHEN  'U'   THEN  null;
        ELSE  p_return_code     := 2;
              p_return_message  := 'Invalid Action Passed - '||p_action; 
        END   CASE;

----    Check the mode of operations and passed todo id
        IF    ( upper(p_action) in ('I','A','C') AND p_todo_id is not null) 
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Combination of action and todo ID';
        END   IF;

        IF    ( upper(p_action) in ('U') AND p_todo_id is null) 
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Combination of action and todo ID';
        END   IF;

----    Validate Start and End Date
        IF    (p_start_date is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Start Date...Start Date must be Entered';
        END   IF;

----    Validate Start and End Date
        IF    ((p_end_date is not null)  and  (p_end_date < p_start_date))
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'End Date must be greater or equal to Start Date';
        END   IF;

----    Validate Client ID
        BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    cmn_client_master
                WHERE   client_id            =  p_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       := 2;
                        p_return_message    := p_return_message || ' - ' ||
                                                'Invalid Client ID Passed';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                               'Invalid Client ID Passed';
        END;

----    Validate Parent todo ID
        IF (p_parent_todo_id is not null)
        THEN
                BEGIN  
                        SELECT  'Y'
                        INTO    exists_flag
                        FROM    cmn_manage_todos
                        WHERE   todo_id              =  p_parent_todo_id                                          
                        AND     client_id            =  p_client_id;
                EXCEPTION
                        WHEN    NO_DATA_FOUND
                        THEN    p_return_code       :=  2;
                                p_return_message    :=  p_return_message || ' - ' ||
                                                        'Invalid Parent todo ID Passed';
                        WHEN    OTHERS
                        THEN    p_return_code       :=  2;
                                p_return_message    :=  p_return_message || ' - ' ||
                                                       'Invalid Parent todo ID Passed';
                END;
        END IF;

----    Validate to Do Subject
        IF    (p_todo_subject is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid To Do Number...';
        END   IF;

----    Validate source transaction type id
        IF    (p_source_transaction_type_id is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Source Transaction Type...';
        END   IF;

----    Validate source transaction type id
        IF(p_source_transaction_type_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y',
                            upper(transaction_table_name)
                    INTO    exists_flag,
                            v_source_table_name
                    FROM    cmn_transaction_types
                    WHERE   transaction_type_id  =  p_source_transaction_type_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Owner Party ID No Data';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Owner Party ID Others';
            END;
        END IF; 
/*
----    Validate Source Table Name
        IF(p_source_transaction_type_id is not null)
        THEN
             BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    all_tables
                WHERE   upper(table_name)    =  trim(upper(v_source_table_name))
                AND     upper(owner)         =  upper('ERPSOFT');
             EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Source Table Name ... No Data';
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message || ' - ' ||
                                                'Invalid Source Table Name ... Others';
             END;
        END  IF;
*/
----    Validate Source transaction Date
        IF    (p_source_transaction_date is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Source Transaction Date...';
        END   IF;


----    Validate Source Transaction Number
        IF    (p_source_transaction_number is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Source Transaction Number...';
        END   IF;

----    Validate todo Creation Party ID
        IF(p_todo_creation_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_employee_master_v
                    WHERE   party_id             =  p_todo_creation_party_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Creation Party ID No Data';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Creation Party ID Others';
            END;
        END IF; 

----    Validate todo Owner Party ID
        IF(p_todo_owner_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_employee_master_v
                    WHERE   party_id             =  p_todo_owner_party_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Owner Party ID No Data';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Owner Party ID Others';
            END;
        END IF; 

----    Validate todo Assigned Party ID
        IF(p_todo_assigned_to_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_employee_master_v
                    WHERE   party_id             =  p_todo_assigned_to_party_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Assigned Party ID No Data';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Assigned Party ID Others';
            END;
        END IF; 

----    Validate todo Actioned Party ID
        IF(p_todo_actioned_by_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_employee_master_v
                    WHERE   party_id             =  p_todo_actioned_by_party_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Actioned Party ID No Data';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Actioned Party ID Others';
            END;
        END IF; 

----    Validate todo Closed Party ID
        IF(p_todo_closed_by_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_employee_master_v
                    WHERE   party_id             =  p_todo_closed_by_party_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Closed By Party ID No Data';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo Closed By Party ID Others';
            END;
        END IF; 

----    Validate todo For Customer ID
        IF(p_todo_for_customer_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_party_combinations
                    WHERE   party_id             =  p_todo_for_customer_party_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo For Customer ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo For Customer ID Passed';
            END;
        END IF; 

----    Validate todo For Vendor ID
        IF(p_todo_for_vendor_party_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_vendor_master_vu
                    WHERE   party_id             =  p_todo_for_vendor_party_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo For Vendor ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid todo For Vendor ID Passed';
            END;
        END IF; 
/*
----    Validate Plan Start Date
        IF    (p_plan_start_date is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Plan Start Date should not be null';
        END   IF;

----    Validate Plan Completion Date
        IF    (p_plan_completion_date is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Plan Completion Date should not be null';
        END   IF;

----    Validate Planned Start and End Date
        IF    ((p_plan_completion_date is not null)  and  (p_plan_completion_date < p_plan_start_date))
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Plan End Date must be greater or equal to Plan Start Date';
        END   IF;
*/
----    Validate Plan Required By Date
        IF    (p_required_by_date is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Plan Required By Date should not be null';
        END   IF;

----    Validate Planned Activity
/*        IF    (p_planned_activity is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Planned Activity should not be null';
        END   IF;*/

----    Validate Organization ID
        IF(p_organization_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_organization_master
                    WHERE   organization_id      =  p_organization_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Organization ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Organization ID Passed';
            END;
        END IF;

----    Validate LOB ID
        IF(p_lob_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_lob_master
                    WHERE   lob_id               =  p_lob_id
                    AND     organization_id      =  p_organization_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid LOB ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid LOB ID Passed';
            END;
        END IF;

----    Validate Profit Centre ID
        IF(p_profit_centre_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_profit_centre_master
                    WHERE   profit_centre_id     =  p_profit_centre_id
                    AND     lob_id               =  p_lob_id
                    AND     organization_id      =  p_organization_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Profit Centre ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Profit Centre ID Passed';
            END;
        END IF;

----    Validate Department ID
        IF(p_department_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_department_name_master_v
                    WHERE   department_id        =  p_department_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Department ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Department ID Passed';
            END;
        END IF;

----    Validate Region ID
        IF(p_region_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_region_master
                    WHERE   region_id            =  p_region_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Region ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Region ID Passed';
            END;
        END IF;

----    Validate Branch ID
        IF(p_branch_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_branch_master
                    WHERE   branch_id            =  p_branch_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Branch ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Branch ID Passed';
            END;
        END IF;

----    Validate Plan Header ID
        IF(p_plan_header_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    epb_plan_headers
                    WHERE   plan_header_id       =  p_plan_header_id                                          
                    AND     client_id            =  p_client_id;
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
        IF(p_plan_detail_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    epb_plan_details
                    WHERE   plan_detail_id       =  p_plan_detail_id
                    AND     plan_header_id       =  p_plan_header_id                                          
                    AND     client_id            =  p_client_id;
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
        IF(p_budget_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    fins_gl_budgets
                    WHERE   budget_id            =  p_budget_id                                          
                    AND     client_id            =  p_client_id;
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

----    Validate Budget Line ID
        IF(p_budget_line_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    fins_gl_budget_lines
                    WHERE   budget_line_id       =  p_budget_line_id
                    AND     budget_id            =  p_budget_id                                          
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Buget Line ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Budget Line ID Passed';
            END;
        END IF;  

----    Validate Project ID
        IF(p_project_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    pam_projects_all
                    WHERE   project_id           =  p_project_id                                          
                    AND     client_id            =  p_client_id;
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
        IF(p_project_task_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    pam_project_tasks
                    WHERE   project_task_id      =  p_project_task_id
                    AND     project_id           =  p_project_id                                          
                    AND     client_id            =  p_client_id;
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

----    Validate todo Type Set ID
        BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   1                        =  1
                    AND     category_id              =  p_todo_type_set_id
                    AND     client_id                =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code           :=  2;
                            p_return_message        :=  p_return_message || ' - ' ||
                                                        'Invalid TODO Type Set ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code           :=  2;
                            p_return_message        :=  p_return_message || ' - ' ||
                                                        'Invalid TODO Type Set ID Passed';
            END;

----    Validate todo Type Code ID
        BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    cmn_sub_category_master
                WHERE   category_id              =  p_todo_type_set_id   
                AND     sub_category_id          =  p_todo_type_code_id
                AND     client_id                =  p_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    p_return_code           :=  2;
                        p_return_message        :=  p_return_message || ' - ' ||
                                                    'Invalid TODO Type Code ID Passed';
                WHEN    OTHERS
                THEN    p_return_code           :=  2;
                        p_return_message        :=  p_return_message || ' - ' ||
                                                    'Invalid TODO Type Code ID Passed';
        END;

----    Validate Value Linkage ID
        IF(p_value_linkage_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id          =  p_value_linkage_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       := 2;
                            p_return_message    := p_return_message || ' - ' ||
                                                    'Invalid Value Linkage Set Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Value Linkage Set ID Passed';
            END;
        END IF;

----    Validate Value Linkage Code ID
        IF(p_value_linkage_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   sub_category_id      =  p_value_linkage_code_id
                    AND     category_id          =  p_value_linkage_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Value Linkage Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Value Linkage Code ID Passed';
            END;
        END IF;

----    Validate MIR Linkage ID
        IF(p_MIR_linkage_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id          =  p_MIR_linkage_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       := 2;
                            p_return_message    := p_return_message || ' - ' ||
                                                    'Invalid MIR Linkage Set Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid MIR Linkage Set ID Passed';
            END;
        END IF;

----    Validate MIR Linkage Code ID
        IF(p_MIR_linkage_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   sub_category_id      =  p_MIR_linkage_code_id
                    AND     category_id          =  p_MIR_linkage_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid MIR Linkage Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid MIR Linkage Code ID Passed';
            END;
        END IF;

----    Validate PQDSE Linkage ID
        IF(p_pqdse_linkage_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id         =  p_pqdse_linkage_set_id
                    AND     client_id           =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       := 2;
                            p_return_message    := p_return_message || ' - ' ||
                                                    'Invalid PQDSE Linkage Set Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid PQDSE Linkage Set ID Passed';
            END;
        END IF;

----    Validate PQDSE Linkage Code ID
        IF(p_PQDSE_linkage_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   sub_category_id      =  p_PQDSE_linkage_code_id
                    AND     category_id          =  p_PQDSE_linkage_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid PQDSE Linkage Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid PQDSE Linkage Code ID Passed';
            END;
        END IF;

----    Validate TQM Linkage ID
        IF(p_TQM_linkage_set_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_category_master
                    WHERE   category_id          =  p_TQM_linkage_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       := 2;
                            p_return_message    := p_return_message || ' - ' ||
                                                    'Invalid TQM Linkage Set Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid TQM Linkage Set ID Passed';
            END;
        END IF;

----    Validate TQM Linkage Code ID
        IF(p_TQM_linkage_code_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_sub_category_master
                    WHERE   sub_category_id      =  p_TQM_linkage_code_id
                    AND     category_id          =  p_TQM_linkage_set_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid TQM Linkage Code ID Passed';
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid TQM Linkage Code ID Passed';
            END;
        END IF;

----    Validate Status ID
        IF(p_status_id is not null)
        THEN
            BEGIN  
                    SELECT  'Y'
                    INTO    exists_flag
                    FROM    cmn_status_master
                    WHERE   status_id            =  p_status_id
                    AND     client_id            =  p_client_id;
            EXCEPTION
                    WHEN    NO_DATA_FOUND
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Status ID Passed - No Data Found'||P_STATUS_ID;
                    WHEN    OTHERS
                    THEN    p_return_code       :=  2;
                            p_return_message    :=  p_return_message || ' - ' ||
                                                    'Invalid Status ID Passed - Others '||P_STATUS_ID;
            END;
        END IF;

----    Validate Status Date
        IF    (p_status_date is null)
        THEN  p_return_code     :=  2;
              p_return_message  :=  p_return_message ||  ' - '  ||
                                    'Status Date should not be null';
        END   IF; 

----    Verify if thre is an error, if yes then raise exception and exit out
        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

----    Take Action according to p_action variable
        IF    ( upper(p_action) in ('I','A','C')) 
        THEN
---     Generate todo Sequence and Number
              vtodo_seq       :=   cmn_todo_seq.nextval;
              vtodo_number    :=   'TODO - ' || vtodo_seq;
              p_todo_id       :=   vtodo_seq;

              BEGIN
                     INSERT INTO cmn_manage_todos
                     (  CREATION_DATE,
                        CREATED_BY,
                        LAST_UPDATE_DATE,
                        LAST_UPDATED_BY,
                        START_DATE,
                        END_DATE,
                        CLIENT_ID,
                        todo_ID,
                        PARENT_todo_ID,
                        TODO_NUMBER,
                        TODO_CREATION_DATE,
                        todo_SUBJECT,
                        todo_DETAILS,
                        source_transaction_type_id,
                        source_transaction_number,
                        source_transaction_date,
                        SOURCE_TABLE_NAME,
                        SOURCE_TABLE_PK_ID,
                        todo_CREATION_PARTY_ID,
                        todo_OWNER_PARTY_ID,
                        todo_assigned_to_party_id,
                        todo_actioned_by_party_id,
                        todo_closed_by_party_id,
                        todo_FOR_CUSTOMER_PARTY_ID,
                        todo_FOR_VENDOR_PARTY_ID,
                        PLAN_START_DATE,
                        PLAN_COMPLETION_DATE,
                        REQUIRED_BY_DATE,
                        DUE_DATE,
                        PLANNED_ACTIVITY,
                        PLANNED_EFFORTS_DAYS,
                        PLANNED_EFFORTS_HOURS,
                        PLANNED_MATERIAL_EXPENSES,
                        PLANNED_LABOUR_EXPENSES,
                        PLANNED_OTHER_EXPENSES,
                        ACTUAL_START_DATE,
                        ACTUAL_COMPLETION_DATE,
                        ACTUAL_ACTIVITY,
                        ACTUAL_EFFORTS_DAYS,
                        ACTUAL_EFFORTS_HOURS,
                        ACTUAL_MATERIAL_EXPENSES,
                        ACTUAL_LABOUR_EXPENSES,
                        ACTUAL_OTHER_EXPENSES,
                        ORGANIZATION_ID,
                        LOB_ID,
                        PROFIT_CENTRE_ID,
                        DEPARTMENT_ID,
                        REGION_ID,
                        BRANCH_ID,
                        PLAN_HEADER_ID,
                        PLAN_DETAIL_ID,
                        BUDGET_ID,
                        BUDGET_LINE_ID,
                        PROJECT_ID,
                        PROJECT_TASK_ID,
                        TODO_TYPE_SET_ID,
                        TODO_TYPE_CODE_ID,
                        VALUE_LINKAGE_SET_ID,
                        VALUE_LINKAGE_CODE_ID,
                        MIR_LINKAGE_SET_ID,
                        MIR_LINKAGE_CODE_ID,
                        PQDSE_LINKAGE_SET_ID,
                        PQDSE_LINKAGE_CODE_ID,
                        TQM_LINKAGE_SET_ID,
                        TQM_LINKAGE_CODE_ID,
                        STATUS_ID,
                        STATUS_DATE
                     )
                     VALUES
                     (  sysdate,
                        p_user_id,
                        sysdate,
                        p_user_id,
                        sysdate,
                        null,
                        p_client_id,
                        vtodo_seq,
                        p_parent_todo_id,
                        vtodo_number,
                        p_todo_creation_date,
                        p_todo_subject,
                        p_todo_details,
                        p_source_transaction_type_id,
                        p_source_transaction_number,
                        p_source_transaction_date,
                        v_source_table_name,
                        p_source_table_pk_id,
                        p_todo_creation_party_id,
                        p_todo_owner_party_id,
                        p_todo_assigned_to_party_id,
                        p_todo_actioned_by_party_id,
                        p_todo_closed_by_party_id,
                        p_todo_for_customer_party_id,
                        p_todo_for_vendor_party_id,
                        p_plan_start_date,
                        p_plan_completion_date,
                        p_required_by_date,
                        p_due_date,
                        p_planned_activity,
                        p_planned_efforts_days,
                        p_planned_efforts_hours,
                        p_planned_material_expenses,
                        p_planned_labour_expenses,
                        p_planned_other_expenses,
                        p_actual_start_date,
                        p_actual_completion_date,
                        p_actual_activity,
                        p_actual_efforts_days,
                        p_actual_efforts_hours,
                        p_actual_material_expenses,
                        p_actual_labour_expenses,
                        p_actual_other_expenses,
                        p_organization_id,
                        p_lob_id,
                        p_profit_centre_id,
                        p_department_id,
                        p_region_id,
                        p_branch_id,
                        p_plan_header_id,
                        p_plan_detail_id,
                        p_budget_id,
                        p_budget_line_id,
                        p_project_id,
                        p_project_task_id,
                        p_todo_type_set_id,
                        p_todo_type_code_id,
                        p_value_linkage_set_id,
                        p_value_linkage_code_id,
                        p_MIR_linkage_set_id,
                        p_MIR_linkage_code_id,
                        p_pqdse_linkage_set_id,
                        p_pqdse_linkage_code_id,
                        p_tqm_linkage_set_id,
                        p_tqm_linkage_code_id,
                        p_status_id,
                        p_status_date
                     );
                     commit;
            EXCEPTION  
                WHEN    OTHERS
                THEN    p_return_code      :=  2;
                        p_return_message   :=  p_return_message ||  ' - '  ||
                                               'Unable to create Record';
                        raise  Some_Error;
                        RETURN;
                END; 
        ELSE
            BEGIN
                UPDATE  cmn_manage_todos 
                SET     last_update_date              =  sysdate,
                        last_updated_by               =  p_user_id,
                        start_date                    =  p_start_date,
                        end_date                      =  p_end_date,
                        parent_todo_id                =  p_parent_todo_id,
                        todo_number                   =  nvl(vtodo_number,p_todo_number),
                        todo_creation_date            =  p_todo_creation_date,
                        todo_subject                  =  p_todo_subject,
                        todo_details                  =  p_todo_details,
                        source_transaction_type_id    =  p_source_transaction_type_id,
                        source_transaction_number     =  p_source_transaction_number,
                        source_transaction_date       =  p_source_transaction_date,
                        source_table_name             =  v_source_table_name,
                        source_table_pk_id            =  p_source_table_pk_id,
                        todo_creation_party_id        =  p_todo_creation_party_id,
                        todo_owner_party_id           =  p_todo_owner_party_id,
                        todo_assigned_to_party_id     =  p_todo_assigned_to_party_id,
                        todo_actioned_by_party_id     =  p_todo_actioned_by_party_id,
                        todo_closed_by_party_id       =  p_todo_closed_by_party_id,
                        todo_for_customer_party_id    =  p_todo_for_customer_party_id,
                        todo_for_vendor_party_id      =  p_todo_for_vendor_party_id,
                        plan_start_date               =  p_plan_start_date,
                        plan_completion_date          =  p_plan_completion_date,
                        required_by_date              =  p_required_by_date,
                        due_date                      =  p_due_date,
                        planned_activity              =  p_planned_activity,
                        planned_efforts_days          =  p_planned_efforts_days,
                        planned_efforts_hours         =  p_planned_efforts_hours,
                        planned_material_expenses     =  p_planned_material_expenses,
                        planned_labour_expenses       =  p_planned_labour_expenses,
                        planned_other_expenses        =  p_planned_other_expenses,
                        actual_start_date             =  p_actual_start_date,
                        actual_completion_date        =  p_actual_completion_date,
                        actual_activity               =  p_actual_activity,
                        actual_efforts_days           =  p_actual_efforts_days,
                        actual_efforts_hours          =  p_actual_efforts_hours,
                        actual_material_expenses      =  p_actual_material_expenses,
                        actual_labour_expenses        =  p_actual_labour_expenses,
                        actual_other_expenses         =  p_actual_other_expenses,
                        organization_id               =  p_organization_id,
                        lob_id                        =  p_lob_id,
                        profit_centre_id              =  p_profit_centre_id,
                        department_id                 =  p_department_id,
                        region_id                     =  p_region_id,
                        branch_id                     =  p_branch_id,
                        plan_header_id                =  p_plan_header_id,
                        plan_detail_id                =  p_plan_detail_id,
                        budget_id                     =  p_budget_id,
                        budget_line_id                =  p_budget_line_id,
                        project_id                    =  p_project_id,
                        project_task_id               =  p_project_task_id,
                        todo_type_set_id              =  p_todo_type_set_id,
                        todo_type_code_id             =  p_todo_type_code_id,
                        value_linkage_set_id          =  p_value_linkage_set_id,
                        value_linkage_code_id         =  p_value_linkage_code_id,
                        MIR_linkage_set_id            =  p_MIR_linkage_set_id,
                        MIR_linkage_code_id           =  p_MIR_linkage_code_id,
                        pqdse_linkage_set_id          =  p_pqdse_linkage_set_id,
                        pqdse_linkage_code_id         =  p_pqdse_linkage_code_id,
                        tqm_linkage_set_id            =  p_tqm_linkage_set_id,
                        tqm_linkage_code_id           =  p_tqm_linkage_code_id,
                        status_id                     =  p_status_id,
                        status_date                   =  p_status_date
                WHERE   1                             =  1
                AND     todo_id                       =  p_todo_id
                AND     client_id                     =  p_client_id;
                commit;
        EXCEPTION
                WHEN    OTHERS
                THEN    p_return_code       :=  2;
                        p_return_message    :=  p_return_message ||  ' - '  ||
                                                'Unable to Update Record';
                        raise  Some_Error;
                        RETURN;
                END;  
        END  IF;

        p_return_code      :=  0;
        p_return_message   :=  'Updating TODO Master is Successful';
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Successful for Maintaining TODO Master');
        DBMS_OUTPUT.put_line ('Execution Successful for Maintaining TODO Master');

        RETURN;

    EXCEPTION
        WHEN    Some_Error
        THEN    p_return_code    :=  2;
                p_return_message :=  p_return_message || ' - ' ||
                                    'Some error Has Occurred...Existing...Unsuccessful Execution';
                RETURN; 

        WHEN    OTHERS
        THEN    DBMS_OUTPUT.put_line (p_return_message || ' - ' || SQLERRM);
                Apex_Util.Set_Session_State('RETURN_MESSAGE' , p_return_message || ' - ' || SQLERRM);
                APEX_ERROR.add_error ( p_error_code         => p_return_message || ' - ' || SQLERRM,
                                       p0                   => null,
                                       p_display_location   => apex_error.c_inline_with_field_and_notif,
                                       p_page_item_name     => null 
                                     );
                p_return_code    :=  2;
                p_return_message :=  p_return_message ||  ' - ' || SQLERRM;
                RETURN;
    END cmn_Register_ToDo_API;
-------------------------------------------------------------------------------------------------------------------------------
