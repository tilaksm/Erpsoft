--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Populate Business Results
--- -     Written by    : Shriniwas Tilak
-----     Date Written  : 9th January 2024
-----     Modified V1   : 
-----     V1 Modified on: 
---------------------------------------------------------------------------------------------------------------------------------
----      This API Populates the Business Results on Variious Activities on weekly basis in the tem table for Reporting FOR items, vendors, customers, calls, leads, offers, orders, invoices.
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE    CMN_POPULATE_BUSINESS_RESULTS_API 
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

----    Declare Cusrsor
        CURSOR  get_pc
        IS
                SELECT  profit_centre_id,
                        profit_centre_name,
                        lob_id,
                        lob_name,
                        organization_id,
                        organization_name,
                        client_id,
                        client_name
                FROM    cmn_profit_centre_master_v
                WHERE   1               =   1
                AND     client_id       =   p_client_id;

----    Declare and Define a Mandatory Parameters to define Virtual Record for a Call
        v_client_id                               varchar2(10)  := p_client_id;
        v_user_id                                 number        := nvl(p_user_id,1);

----    Declare and Define a Virtual Record for a Call
        v_start_date                              date          :=  sysdate;
        v_end_date                                date          :=  null;
        v_fiscal_year                             varchar2(10)  :=  null;
        v_fiscal_year_start_date                  date          :=  null;
        v_fiscal_year_end_date                    date          :=  null;
        v_quarter_start_date                      date          :=  null;
        v_Quarter_end_Date                        date          :=  null;
        v_month_start_date                        date          :=  null;
        v_month_end_date                          date          :=  null;
        v_week_start_date                         date          :=  null;
        v_week_end_date                           date          :=  null;

----    Data Related Information
        v_salesrep_id                             number        :=  null;
        v_profit_centre_id                        number        :=  null;
        v_transaction_id                          number        :=  null;
        v_activity_description                    varchar2(100) :=  null;
        v_activity_sub_description                varchar2(100) :=  null;
        v_ytd_target_count                        number        :=  null;
        v_ytd_target_value                        number        :=  null;
        v_ytd_actual_count                        number        :=  null;
        v_ytd_actual_value                        number        :=  null;
        v_ytd_open_count                          number        :=  null;
        v_ytd_open_value                          number        :=  null;
        v_ytd_closed_count                        number        :=  null;
        v_ytd_closed_value                        number        :=  null;
        v_ytd_cancel_count                        number        :=  null;
        v_ytd_cancel_value                        number        :=  null;
        v_ytd_lost_count                          number        :=  null;
        v_ytd_lost_value                          number        :=  null;
        v_qtd_target_count                        number        :=  null;
        v_qtd_target_value                        number        :=  null;
        v_qtd_actual_count                        number        :=  null;
        v_qtd_actual_value                        number        :=  null;
        v_qtd_open_count                          number        :=  null;
        v_qtd_open_value                          number        :=  null;
        v_qtd_closed_count                        number        :=  null;
        v_qtd_closed_value                        number        :=  null;
        v_qtd_cancel_count                        number        :=  null;
        v_qtd_cancel_value                        number        :=  null;
        v_qtd_lost_count                          number        :=  null;
        v_qtd_lost_value                          number        :=  null;
        v_mtd_target_count                        number        :=  null;
        v_mtd_target_value                        number        :=  null;
        v_mtd_actual_count                        number        :=  null;
        v_mtd_actual_value                        number        :=  null;
        v_mtd_open_count                          number        :=  null;
        v_mtd_open_value                          number        :=  null;
        v_mtd_closed_count                        number        :=  null;
        v_mtd_closed_value                        number        :=  null;
        v_mtd_cancel_count                        number        :=  null;
        v_mtd_cancel_value                        number        :=  null;
        v_mtd_lost_count                          number        :=  null;
        v_mtd_lost_value                          number        :=  null;
        v_wtd_target_count                        number        :=  null;
        v_wtd_target_value                        number        :=  null;
        v_wtd_actual_count                        number        :=  null;
        v_wtd_actual_value                        number        :=  null;
        v_wtd_open_count                          number        :=  null;
        v_wtd_open_value                          number        :=  null;
        v_wtd_closed_count                        number        :=  null;
        v_wtd_closed_value                        number        :=  null;
        v_wtd_cancel_count                        number        :=  null;
        v_wtd_cancel_value                        number        :=  null;
        v_wtd_lost_count                          number        :=  null;
        v_wtd_lost_value                          number        :=  null;
        v_reach_percentage_count                  number        :=  null;
        v_reach_percentage_value                  number        :=  null;
        v_conversion_percentage_count             number        :=  null;
        v_conversion_percentage_value             number        :=  null;
----    Define Exceptions
        Some_Error            EXCEPTION;

BEGIN
        p_return_code   :=  0;
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started for Populating Business Results ');
        p_return_message := 'Execution Started for Populating Business Results ';
        dbms_output.put_line(p_return_message);

----    Start Validating Input Data
----    Validate Client (Installation)
        IF    (p_client_id  is  null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid Client / Installation  ';
        END   IF;

        exists_flag  :=  null;
        BEGIN  
                SELECT  'Y'
                INTO    exists_flag
                FROM    cmn_client_master 
                WHERE   1  =  1
                AND     client_id          =  p_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    v_user_id         := 1;
                        p_return_code     := 2;
                        p_return_message  := p_return_message || ' - ' ||
                                             'Invalid Client ID ';
                WHEN    OTHERS
                THEN    v_user_id         := null;
                        p_return_code     := 2;
                        p_return_message  := p_return_message || ' - ' ||
                                             'Invalid Client ID ';
        END;
        p_return_message  := p_return_message ||  ' - '  ||' Client/Instalation Validated ';
        dbms_output.put_line(p_return_message);
        v_client_id             := p_client_id;

----    Validate User
        IF    (nvl(p_user_id,1) is null)
        THEN  p_return_code     := 2;
              p_return_message  := p_return_message ||  ' - '  ||
                                   'Invalid User ';
        END   IF;

        exists_flag  :=  null;
        BEGIN  
                SELECT  'Y',
                        user_id
                INTO    exists_flag,
                        v_user_id
                FROM    cmn_user_master 
                WHERE   1  =  1
                AND     client_id        =  p_client_id
                AND     user_id          =  p_user_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    v_user_id         := 1;
                        p_return_code     := 2;
                        p_return_message  := p_return_message || ' - ' ||
                                             'Invalid User ID ';
                WHEN    OTHERS
                THEN    v_user_id         := null;
                        p_return_code     := 2;
                        p_return_message  := p_return_message || ' - ' ||
                                             'Invalid User ID ';
        END;
        p_return_message  := p_return_message ||  ' - '  ||' User Validated ';
        dbms_output.put_line(p_return_message);
        v_user_id   :=  p_user_id;
---     Now first Populate the Year,Quarter and Month Start and End Dates based on sysdate
        SELECT  TRUNC(sysdate, 'iw'),
                (TRUNC(sysdate, 'iw') + 7 - 1/86400),
                cop.month_start_date,
                cop.month_end_date,
                cop.quarter_start_date,
                cop.quarter_end_date,
                cop.year_start_date,
                cop.year_end_date
        INTO    v_week_start_date,
                v_week_end_date,
                v_month_start_date,
                v_month_end_date,
                v_Quarter_Start_Date,
                v_Quarter_end_date,
                v_fiscal_year_start_date,
                v_fiscal_year_end_date
        FROM    cmn_operating_periods   cop
        WHERE   sysdate between cop.period_start_date and cop.period_end_date
        AND     cop.client_id         = p_client_id;

        v_fiscal_year  :=  to_char(v_fiscal_year_start_date,'YYYY')||'-'||to_char(v_fiscal_year_end_date,'YYYY');

        DBMS_OUTPUT.put_line ('Week Start  Date : '||v_week_start_date);
        DBMS_OUTPUT.put_line ('Week End    Date : '||v_week_end_date);
        DBMS_OUTPUT.put_line ('Month Start Date : '||v_month_start_date);
        DBMS_OUTPUT.put_line ('Month End   Date : '||v_month_end_date);
        DBMS_OUTPUT.put_line ('QTR   Start Date : '||v_Quarter_Start_Date);
        DBMS_OUTPUT.put_line ('QTR   End   Date : '||v_Quarter_end_Date);
        DBMS_OUTPUT.put_line ('Year  Start Date : '||v_fiscal_year_start_date);
        DBMS_OUTPUT.put_line ('Year  End   Date : '||v_fiscal_year_end_date);
        DBMS_OUTPUT.put_line ('Fiscal Year : '||v_fiscal_year);


----    First Purge All Existing Data
        BEGIN
                  DELETE  FROM  cmn_business_results
                  WHERE   1           = 1
                  AND     fiscal_year = v_fiscal_year
                  AND     client_id =   p_client_id;
        EXCEPTION WHEN  OTHERS
                  THEN  null;
        END;
        COMMIT;

----    Now Profit Centre Loop Starts to Populate the Data
        for   Set_pc in  get_pc
        loop
----          Populate Items
              begin
                    INSERT  INTO  cmn_business_results
                            (     client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                            )
                    SELECT  set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '01. Items',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when     fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                THEN    fat.inventory_item_id
                            END),                                     ----  ytd_actual_count
                            0,                                        ----  ytd_actual_value,
                            COUNT(DISTINCT CASE
                                when      fat.end_date is null
                                then      fat.inventory_item_id
                            END),                                     ----  ytd_open_count
                            0,                                        ----  ytd_open_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007 and fat.end_date is not null
                                then      fat.inventory_item_id
                            END),                                     ----  ytd_closed_count
                            0,                                        ----  ytd_closed_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006 and fat.end_date is not null
                                then      fat.inventory_item_id
                            END),----  ytd_cancel_count
                            0,                                        ----  ytd_cancel_value,
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then      fat.inventory_item_id
                            END),----  qtd_actual_count
                            0,                                        ----  qtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.inventory_item_id
                                else      0
                            END),                                     ----  qtd_open_count
                            0,                                        ----  qtd_open_value,
                            COUNT(DISTINCT CASE
                                 when( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.inventory_item_id
                                else      0
                            END),                                      ----  qtd_closed_count
                            0,                                        ----  qtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then    fat.inventory_item_id
                                else      0
                            END),                                      ----  qtd_cancel_count
                            0,                                        ----  qtd_cancel_value,
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when    fat.creation_date
                                        between v_month_start_date
                                        and     v_month_end_date
                                then    fat.inventory_item_id
                                else    0
                            END),                                     ----  mtd_actual_count
                            0,                                        ----  mtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.inventory_item_id
                                else      0
                            END),                                     ----  mtd_open_count
                            0,                                        ----  mtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                            then      fat.inventory_item_id
                            else      0
                            END),                                     ----  mtd_closed_count
                            0,                                        ----  mtd_closed_value,
                            COUNT(DISTINCT CASE
                                when      ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then     fat.inventory_item_id
                                else      0
                            END),                                     ----  mtd_cancel_count
                            0,                                        ----  mtd_cancel_value,
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_week_start_date
                                        and     v_week_end_date
                                then      fat.inventory_item_id
                                else      0
                            END),                                     ----  wtd_actual_count
                            0,                                        ----  wtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                            then      fat.inventory_item_id
                            else      0
                            END),                                     ----  wtd_open_count
                            0,                                        ----  wtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.inventory_item_id
                                else      0
                            END),                                     ----  wtd_closed_count
                            0,                                        ----  wtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then      fat.inventory_item_id
                                else      0
                            END),                                      ----  wtd_cancel_count
                            0,                                        ----  wtd_cancel_value,
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                    FROM    cmn_item_master             fat
                    WHERE   1                       =   1
                    AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                    AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                            )
                    AND     fat.client_id           =   p_client_id
                    GROUP   BY  set_pc.client_id,
                                set_pc.profit_centre_id,
                                fat.created_by;
                    commit;
                    p_return_message  := p_return_message ||  ' - '  ||' Item Records Populated';
                    DBMS_OUTPUT.put_line (p_return_message);
              exception
              when        Others
              then        p_return_code   :=  2;
                          p_return_message  := p_return_message ||  ' - '  ||' Item Records Can not be Populated '||SQLERRM;
                          DBMS_OUTPUT.put_line (p_return_message);
                          null;
              end;


--            populate Orders
                begin
                        INSERT INTO cmn_business_results
                        (
                                  client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                        )
                        SELECT
                            set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '02. Orders',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                then      fat.order_header_id
                            END),                                      ----  ytd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.order_header_id
                            END),                                      ----  ytd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.order_header_id
                            END),                                      ----  ytd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.order_header_id
                            END),                                      ----  ytd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_canceL_value
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.order_header_id
                            END),                                      ----  qtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.order_header_id
                            END),                                      ----  qtd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_open_value
                            COUNT(DISTINCT CASE
                            when      fat.status_code = 'CLOSE'
                                  and fat.creation_date
                                  between v_quarter_start_date
                                  and     v_quarter_end_date
                            then       fat.order_header_id
                            END),                                      ----  qtd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.order_header_id
                            END),                                     ----  qtd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_canceL_value
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.order_header_id
                            END),                                      ----  mtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  mtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.order_header_id
                            END),                                      ----  mtd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  mtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.order_header_id
                            END),                                      ----  mtd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  mtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.order_header_id
                            END),                                      ----  mtd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                     ----  mtd_canceL_value
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.order_header_id
                            END),                                     ----  wtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  wtd_actual_value
                            COUNT(DISTINCT CASE
                            when      fat.status_code = 'OPEN'
                                  and fat.creation_date
                                  between v_week_start_date
                                  and     v_week_end_date
                            then      fat.order_header_id
                            END),                                     ----  wtd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  wtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.order_header_id
                            END),                                     ----  wtd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  wtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.order_header_id
                            END),                                     ----  wtd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                     ----  wtd_canceL_value
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                        
                        FROM    om_order_headers_v          fat
                        WHERE   1                       =   1
                        AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                        AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                                )
                        AND     fat.client_id           =   p_client_id
                        GROUP   BY  set_pc.client_id,
                                        set_pc.profit_centre_id,
                                        fat.created_by;
                        commit;
                        p_return_message  := p_return_message ||  ' - '  ||' Orders Records Populated';
                        DBMS_OUTPUT.put_line (p_return_message);
                exception
                when        Others
                then        p_return_code   :=  2;
                                p_return_message  := p_return_message ||  ' - '  ||' Orders Records Can not be Populated '||SQLERRM;
                                DBMS_OUTPUT.put_line (p_return_message);
                                null;
                end;

-- ----            populate Offers
                begin
                        INSERT INTO cmn_business_results
                        (
                                  client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                        )
                        SELECT
                            set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '03. Offers',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                then      fat.offer_id
                            END),                                      ----  ytd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.offer_id
                            END),                                      ----  ytd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.offer_id
                            END),                                      ----  ytd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.offer_id
                            END),                                      ----  ytd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_canceL_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.offer_id
                            END),                                      ----  ytd_lost_count
                            sum(case      
                            when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.offer_id
                            END),                                      ----  qtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.offer_id
                            END),                                      ----  qtd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_open_value
                            COUNT(DISTINCT CASE
                            when      fat.status_code = 'CLOSE'
                                  and fat.creation_date
                                  between v_quarter_start_date
                                  and     v_quarter_end_date
                            then       fat.offer_id
                            END),                                      ----  qtd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.offer_id
                            END),                                     ----  qtd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_canceL_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.offer_id
                            END),                                     ----  qtd_lost_count
                            sum(case      
                            when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  qtd_lost_value
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.offer_id
                            END),                                      ----  mtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  mtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.offer_id
                            END),                                      ----  mtd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  mtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.offer_id
                            END),                                      ----  mtd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  mtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.offer_id
                            END),                                      ----  mtd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                     ----  mtd_canceL_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.offer_id
                            END),                                      ----  mtd_lost_count
                            sum(case      
                            when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                     ----  mtd_lost_value
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.offer_id
                            END),                                     ----  wtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  wtd_actual_value
                            COUNT(DISTINCT CASE
                            when      fat.status_code = 'OPEN'
                                  and fat.creation_date
                                  between v_week_start_date
                                  and     v_week_end_date
                            then      fat.offer_id
                            END),                                     ----  wtd_open_count
                            sum(case      
                            when      fat.status_code = 'OPEN'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.offer_id
                            else      0
                            end),                                      ----  wtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.offer_id
                            END),                                     ----  wtd_close_count
                            sum(case      
                            when      fat.status_code = 'CLOSE'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                      ----  wtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.offer_id
                            END),                                     ----  wtd_cancel_count
                            sum(case      
                            when      fat.status_code = 'CANCEL'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                     ----  wtd_canceL_value
                            COUNT(DISTINCT CASE
                                when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.offer_id
                            END),                                     ----  wtd_lost_count
                            sum(case      
                            when      fat.status_code = 'LOST'
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.line_total_amount
                            else      0
                            end),                                     ----  wtd_lost_value
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                        
                        FROM    CRM_OFFER_HEADERS_V          fat
                        WHERE   1                       =   1
                        AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                        AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                                )
                        AND     fat.client_id           =   p_client_id
                        GROUP   BY  set_pc.client_id,
                                        set_pc.profit_centre_id,
                                        fat.created_by;
                        commit;
                        p_return_message  := p_return_message ||  ' - '  ||' Offers Records Populated';
                        DBMS_OUTPUT.put_line (p_return_message);
                exception
                when        Others
                then        p_return_code   :=  2;
                                p_return_message  := p_return_message ||  ' - '  ||' Offers Records Can not be Populated '||SQLERRM;
                                DBMS_OUTPUT.put_line (p_return_message);
                                null;
                end;

-- ----          Populate Leads
              begin
                    INSERT  INTO  cmn_business_results
                            (     client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                            )
                    SELECT  set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '04. Leads',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when     fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                THEN    fat.lead_id
                            END),                                     ----  ytd_actual_count
                            0,                                        ----  ytd_actual_value,
                            COUNT(DISTINCT CASE
                                when      fat.end_date is null
                                then      fat.lead_id
                            END),                                     ----  ytd_open_count
                            0,                                        ----  ytd_open_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007 and fat.end_date is not null
                                then      fat.lead_id
                            END),                                     ----  ytd_closed_count
                            0,                                        ----  ytd_closed_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006 and fat.end_date is not null
                                then      fat.lead_id
                            END),                                       ----  ytd_cancel_count
                            0,                                        ----  ytd_cancel_value,
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then      fat.lead_id
                            END),                                       ----  qtd_actual_count
                            0,                                        ----  qtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.lead_id
                                else      0
                            END),                                     ----  qtd_open_count
                            0,                                        ----  qtd_open_value,
                            COUNT(DISTINCT CASE
                                 when( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.lead_id
                                else      0
                            END),                                      ----  qtd_closed_count
                            0,                                        ----  qtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then    fat.lead_id
                                else      0
                            END),                                      ----  qtd_cancel_count
                            0,                                        ----  qtd_cancel_value,
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when    fat.creation_date
                                        between v_month_start_date
                                        and     v_month_end_date
                                then    fat.lead_id
                                else    0
                            END),                                     ----  mtd_actual_count
                            0,                                        ----  mtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.lead_id
                                else      0
                            END),                                     ----  mtd_open_count
                            0,                                        ----  mtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                            then      fat.lead_id
                            else      0
                            END),                                     ----  mtd_closed_count
                            0,                                        ----  mtd_closed_value,
                            COUNT(DISTINCT CASE
                                when      ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then     fat.lead_id
                                else      0
                            END),                                     ----  mtd_cancel_count
                            0,                                        ----  mtd_cancel_value,
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_week_start_date
                                        and     v_week_end_date
                                then      fat.lead_id
                                else      0
                            END),                                     ----  wtd_actual_count
                            0,                                        ----  wtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                            then      fat.lead_id
                            else      0
                            END),                                     ----  wtd_open_count
                            0,                                        ----  wtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.lead_id
                                else      0
                            END),                                     ----  wtd_closed_count
                            0,                                        ----  wtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then      fat.lead_id
                                else      0
                            END),                                      ----  wtd_cancel_count
                            0,                                        ----  wtd_cancel_value,
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                    FROM    CRM_LEAD_HEADERS_V             fat
                    WHERE   1                       =   1
                    AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                    AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                            )
                    AND     fat.client_id           =   p_client_id
                    GROUP   BY  set_pc.client_id,
                                set_pc.profit_centre_id,
                                fat.created_by;
                    commit;
                    p_return_message  := p_return_message ||  ' - '  ||' Leads Records Populated';
                    DBMS_OUTPUT.put_line (p_return_message);
              exception
              when        Others
              then        p_return_code   :=  2;
                          p_return_message  := p_return_message ||  ' - '  ||' Leads Records Can not be Populated '||SQLERRM;
                          DBMS_OUTPUT.put_line (p_return_message);
                          null;
              end;

-- ----          Populate Calls
              begin
                    INSERT  INTO  cmn_business_results
                            (     client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                            )
                    SELECT  set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '05. Calls',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when     fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                THEN    fat.call_id
                            END),                                     ----  ytd_actual_count
                            0,                                        ----  ytd_actual_value,
                            COUNT(DISTINCT CASE
                                when      fat.end_date is null
                                then      fat.call_id
                            END),                                     ----  ytd_open_count
                            0,                                        ----  ytd_open_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007 and fat.end_date is not null
                                then      fat.call_id
                            END),                                     ----  ytd_closed_count
                            0,                                        ----  ytd_closed_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006 and fat.end_date is not null
                                then      fat.call_id
                            END),                                       ----  ytd_cancel_count
                            0,                                        ----  ytd_cancel_value,
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then      fat.call_id
                            END),                                       ----  qtd_actual_count
                            0,                                        ----  qtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.call_id
                                else      0
                            END),                                     ----  qtd_open_count
                            0,                                        ----  qtd_open_value,
                            COUNT(DISTINCT CASE
                                 when( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.call_id
                                else      0
                            END),                                      ----  qtd_closed_count
                            0,                                        ----  qtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then    fat.call_id
                                else      0
                            END),                                      ----  qtd_cancel_count
                            0,                                        ----  qtd_cancel_value,
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when    fat.creation_date
                                        between v_month_start_date
                                        and     v_month_end_date
                                then    fat.call_id
                                else    0
                            END),                                     ----  mtd_actual_count
                            0,                                        ----  mtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.call_id
                                else      0
                            END),                                     ----  mtd_open_count
                            0,                                        ----  mtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                            then      fat.call_id
                            else      0
                            END),                                     ----  mtd_closed_count
                            0,                                        ----  mtd_closed_value,
                            COUNT(DISTINCT CASE
                                when      ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then     fat.call_id
                                else      0
                            END),                                     ----  mtd_cancel_count
                            0,                                        ----  mtd_cancel_value,
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_week_start_date
                                        and     v_week_end_date
                                then      fat.call_id
                                else      0
                            END),                                     ----  wtd_actual_count
                            0,                                        ----  wtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                            then      fat.call_id
                            else      0
                            END),                                     ----  wtd_open_count
                            0,                                        ----  wtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.call_id
                                else      0
                            END),                                     ----  wtd_closed_count
                            0,                                        ----  wtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then      fat.call_id
                                else      0
                            END),                                      ----  wtd_cancel_count
                            0,                                        ----  wtd_cancel_value,
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                    FROM    crm_calls_v             fat
                    WHERE   1                       =   1
                    AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                    AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                            )
                    AND     fat.client_id           =   p_client_id
                    GROUP   BY  set_pc.client_id,
                                set_pc.profit_centre_id,
                                fat.created_by;
                    commit;
                    p_return_message  := p_return_message ||  ' - '  ||' Calls Records Populated';
                    DBMS_OUTPUT.put_line (p_return_message);
              exception
              when        Others
              then        p_return_code   :=  2;
                          p_return_message  := p_return_message ||  ' - '  ||' Calls Records Can not be Populated '||SQLERRM;
                          DBMS_OUTPUT.put_line (p_return_message);
                          null;
              end;

-- ----          Populate Vendors
              begin
                    INSERT  INTO  cmn_business_results
                            (     client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                            )
                    SELECT  set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '06. Vendors',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when     fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                THEN    fat.party_id
                            END),                                     ----  ytd_actual_count
                            0,                                        ----  ytd_actual_value,
                            COUNT(DISTINCT CASE
                                when      fat.end_date is null
                                then      fat.party_id
                            END),                                     ----  ytd_open_count
                            0,                                        ----  ytd_open_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007 and fat.end_date is not null
                                then      fat.party_id
                            END),                                     ----  ytd_closed_count
                            0,                                        ----  ytd_closed_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006 and fat.end_date is not null
                                then      fat.party_id
                            END),                                       ----  ytd_cancel_count
                            0,                                        ----  ytd_cancel_value,
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then      fat.party_id
                            END),                                       ----  qtd_actual_count
                            0,                                        ----  qtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                     ----  qtd_open_count
                            0,                                        ----  qtd_open_value,
                            COUNT(DISTINCT CASE
                                 when( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                      ----  qtd_closed_count
                            0,                                        ----  qtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                      ----  qtd_cancel_count
                            0,                                        ----  qtd_cancel_value,
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when    fat.creation_date
                                        between v_month_start_date
                                        and     v_month_end_date
                                then    fat.party_id
                                else    0
                            END),                                     ----  mtd_actual_count
                            0,                                        ----  mtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                     ----  mtd_open_count
                            0,                                        ----  mtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                            then      fat.party_id
                            else      0
                            END),                                     ----  mtd_closed_count
                            0,                                        ----  mtd_closed_value,
                            COUNT(DISTINCT CASE
                                when      ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then     fat.party_id
                                else      0
                            END),                                     ----  mtd_cancel_count
                            0,                                        ----  mtd_cancel_value,
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_week_start_date
                                        and     v_week_end_date
                                then      fat.party_id
                                else      0
                            END),                                     ----  wtd_actual_count
                            0,                                        ----  wtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                            then      fat.party_id
                            else      0
                            END),                                     ----  wtd_open_count
                            0,                                        ----  wtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                     ----  wtd_closed_count
                            0,                                        ----  wtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then      fat.party_id
                                else      0
                            END),                                      ----  wtd_cancel_count
                            0,                                        ----  wtd_cancel_value,
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                    FROM    CMN_PARTY_MASTER        fat
                    WHERE   1                       =   1
                    AND     fat.vendor_combination_id is not null
                --     AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                    AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                            )
                    AND     fat.client_id           =   p_client_id
                    GROUP   BY  set_pc.client_id,
                                set_pc.profit_centre_id,
                                fat.created_by;
                    commit;
                    p_return_message  := p_return_message ||  ' - '  ||' Vendors Records Populated';
                    DBMS_OUTPUT.put_line (p_return_message);
              exception
              when        Others
              then        p_return_code   :=  2;
                          p_return_message  := p_return_message ||  ' - '  ||' Vendors Records Can not be Populated '||SQLERRM;
                          DBMS_OUTPUT.put_line (p_return_message);
                          null;
              end;


-- ----          Populate customers
              begin
                    INSERT  INTO  cmn_business_results
                            (     client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                            )
                    SELECT  set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '07. Customers',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when     fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                THEN    fat.party_id
                            END),                                     ----  ytd_actual_count
                            0,                                        ----  ytd_actual_value,
                            COUNT(DISTINCT CASE
                                when      fat.end_date is null
                                then      fat.party_id
                            END),                                     ----  ytd_open_count
                            0,                                        ----  ytd_open_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007 and fat.end_date is not null
                                then      fat.party_id
                            END),                                     ----  ytd_closed_count
                            0,                                        ----  ytd_closed_value,
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006 and fat.end_date is not null
                                then      fat.party_id
                            END),                                       ----  ytd_cancel_count
                            0,                                        ----  ytd_cancel_value,
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then      fat.party_id
                            END),                                       ----  qtd_actual_count
                            0,                                        ----  qtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                     ----  qtd_open_count
                            0,                                        ----  qtd_open_value,
                            COUNT(DISTINCT CASE
                                 when( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                      ----  qtd_closed_count
                            0,                                        ----  qtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_quarter_start_date
                                          and     v_quarter_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                      ----  qtd_cancel_count
                            0,                                        ----  qtd_cancel_value,
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when    fat.creation_date
                                        between v_month_start_date
                                        and     v_month_end_date
                                then    fat.party_id
                                else    0
                            END),                                     ----  mtd_actual_count
                            0,                                        ----  mtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                     ----  mtd_open_count
                            0,                                        ----  mtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                            then      fat.party_id
                            else      0
                            END),                                     ----  mtd_closed_count
                            0,                                        ----  mtd_closed_value,
                            COUNT(DISTINCT CASE
                                when      ( ( fat.creation_date
                                          between v_month_start_date
                                          and     v_month_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then     fat.party_id
                                else      0
                            END),                                     ----  mtd_cancel_count
                            0,                                        ----  mtd_cancel_value,
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_week_start_date
                                        and     v_week_end_date
                                then      fat.party_id
                                else      0
                            END),                                     ----  wtd_actual_count
                            0,                                        ----  wtd_actual_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                      )
                            then      fat.party_id
                            else      0
                            END),                                     ----  wtd_open_count
                            0,                                        ----  wtd_open_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10007
                                        )
                                      )
                                then    fat.party_id
                                else      0
                            END),                                     ----  wtd_closed_count
                            0,                                        ----  wtd_closed_value,
                            COUNT(DISTINCT CASE
                                when  ( ( fat.creation_date
                                          between v_week_start_date
                                          and     v_week_end_date
                                        )
                                        and
                                        ( fat.end_date is null
                                        )
                                        and
                                        ( fat.status_id = 10006
                                        )
                                      )
                                then      fat.party_id
                                else      0
                            END),                                      ----  wtd_cancel_count
                            0,                                        ----  wtd_cancel_value,
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                    FROM    CMN_PARTY_MASTER        fat
                    WHERE   1                       =   1
                    AND     fat.customer_combination_id is not null
                --     AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                    AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                    OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                  and       v_fiscal_year_end_date
                              )
                            )
                    AND     fat.client_id           =   p_client_id
                    GROUP   BY  set_pc.client_id,
                                set_pc.profit_centre_id,
                                fat.created_by;
                    commit;
                    p_return_message  := p_return_message ||  ' - '  ||' Customer Records Populated';
                    DBMS_OUTPUT.put_line (p_return_message);
              exception
              when        Others
              then        p_return_code   :=  2;
                          p_return_message  := p_return_message ||  ' - '  ||' Customer Records Can not be Populated '||SQLERRM;
                          DBMS_OUTPUT.put_line (p_return_message);
                          null;
              end;

--            populate Invoice
                begin
                        INSERT INTO cmn_business_results
                        (
                                  client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                        )
                        SELECT
                            set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '08. Invoices',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  ytd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  ytd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  ytd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  ytd_canceL_value
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  qtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  qtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  qtd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  qtd_open_value
                            COUNT(DISTINCT CASE
                            when      fat.status_id = 10007
                                  and fat.creation_date
                                  between v_quarter_start_date
                                  and     v_quarter_end_date
                            then       fat.ar_trx_id
                            END),                                      ----  qtd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  qtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  qtd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  qtd_canceL_value
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  mtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  mtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  mtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                     ----  mtd_canceL_value
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  wtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  wtd_actual_value
                            COUNT(DISTINCT CASE
                            when      fat.status_id = 10002
                                  and fat.creation_date
                                  between v_week_start_date
                                  and     v_week_end_date
                            then      fat.ar_trx_id
                            END),                                     ----  wtd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  wtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  wtd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                      ----  wtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  wtd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      fat.ar_trx_total_amount
                            else      0
                            end),                                     ----  wtd_canceL_value
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                        
                        FROM    FINS_AR_TRANSACTIONS          fat
                        WHERE   1                       =   1
                        AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                        AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                                )
                        AND     fat.client_id           =   p_client_id
                        GROUP   BY  set_pc.client_id,
                                        set_pc.profit_centre_id,
                                        fat.created_by;
                        commit;
                        p_return_message  := p_return_message ||  ' - '  ||' Invoice Records Populated';
                        DBMS_OUTPUT.put_line (p_return_message);
                exception
                when        Others
                then        p_return_code   :=  2;
                                p_return_message  := p_return_message ||  ' - '  ||' Invoice Records Can not be Populated '||SQLERRM;
                                DBMS_OUTPUT.put_line (p_return_message);
                                null;
                end;

--            populate Invoice
                begin
                        INSERT INTO cmn_business_results
                        (
                                  client_id,
                                  profit_centre_id,
                                  salesrep_id,
                                  fiscal_year,
                                  as_of_date,
                                  activity_description,
                                  activity_sub_description,
                                  ytd_target_count,
                                  ytd_target_value,
                                  ytd_actual_count,
                                  ytd_actual_value,
                                  ytd_open_count,
                                  ytd_open_value,
                                  ytd_closed_count,
                                  ytd_closed_value,
                                  ytd_cancel_count,
                                  ytd_cancel_value,
                                  ytd_lost_count,
                                  ytd_lost_value,
                                  qtd_target_count,
                                  qtd_target_value,
                                  qtd_actual_count,
                                  qtd_actual_value,
                                  qtd_open_count,
                                  qtd_open_value,
                                  qtd_closed_count,
                                  qtd_closed_value,
                                  qtd_cancel_count,
                                  qtd_cancel_value,
                                  qtd_lost_count,
                                  qtd_lost_value,
                                  mtd_target_count,
                                  mtd_target_value,
                                  mtd_actual_count,
                                  mtd_actual_value,
                                  mtd_open_count,
                                  mtd_open_value,
                                  mtd_closed_count,
                                  mtd_closed_value,
                                  mtd_cancel_count,
                                  mtd_cancel_value,
                                  mtd_lost_count,
                                  mtd_lost_value,
                                  wtd_target_count,
                                  wtd_target_value,
                                  wtd_actual_count,
                                  wtd_actual_value,
                                  wtd_open_count,
                                  wtd_open_value,
                                  wtd_closed_count,
                                  wtd_closed_value,
                                  wtd_cancel_count,
                                  wtd_cancel_value,
                                  wtd_lost_count,
                                  wtd_lost_value,
                                  reach_percentage_count,
                                  reach_percentage_value,
                                  conversion_percentage_count,
                                  conversion_percentage_value
                        )
                        SELECT
                            set_pc.client_id,                         ----  client_id
                            set_pc.profit_centre_id,                  ----  pc_id
                            fat.created_by,                           ----  salrep_id
                            v_fiscal_year,                            ----  fiscal_year
                            sysdate,                                  ----  As of Date
                            '09. Debtors',                              ----  Activity Description
                            null,                                     ----  Activity Sub Description  
                            0,                                        ----  ytd_target_count,
                            0,                                        ----  ytd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                        between v_fiscal_year_start_date
                                        and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  ytd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  ytd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  ytd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  ytd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_fiscal_year_start_date
                                      and     v_fiscal_year_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  ytd_canceL_value
                            0,                                        ----  ytd_lost_count,
                            0,                                        ----  ytd_lost_value,
                            0,                                        ----  qtd_target_count,
                            0,                                        ----  qtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  qtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  qtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  qtd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  qtd_open_value
                            COUNT(DISTINCT CASE
                            when      fat.status_id = 10007
                                  and fat.creation_date
                                  between v_quarter_start_date
                                  and     v_quarter_end_date
                            then       fat.ar_trx_id
                            END),                                      ----  qtd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  qtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  qtd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_quarter_start_date
                                      and     v_quarter_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  qtd_canceL_value
                            0,                                        ----  qtd_lost_count,
                            0,                                        ----  qtd_lost_value,
                            0,                                        ----  mtd_target_count,
                            0,                                        ----  mtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  mtd_actual_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  mtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  mtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                                then      fat.ar_trx_id
                            END),                                      ----  mtd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_month_start_date
                                      and     v_month_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                     ----  mtd_canceL_value
                            0,                                        ----  mtd_lost_count,
                            0,                                        ----  mtd_lost_value,
                            0,                                        ----  wtd_target_count,
                            0,                                        ----  wtd_target_value,
                            COUNT(DISTINCT CASE
                                when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  wtd_actual_count
                            sum(case      
                            when      fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  wtd_actual_value
                            COUNT(DISTINCT CASE
                            when      fat.status_id = 10002
                                  and fat.creation_date
                                  between v_week_start_date
                                  and     v_week_end_date
                            then      fat.ar_trx_id
                            END),                                     ----  wtd_open_count
                            sum(case      
                            when      fat.status_id = 10002
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  wtd_open_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  wtd_close_count
                            sum(case      
                            when      fat.status_id = 10007
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                      ----  wtd_close_value
                            COUNT(DISTINCT CASE
                                when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                                then      fat.ar_trx_id
                            END),                                     ----  wtd_cancel_count
                            sum(case      
                            when      fat.status_id = 10006
                                      and fat.creation_date
                                      between v_week_start_date
                                      and     v_week_end_date
                            then      NVL(fat.ar_trx_total_amount, 0) - NVL(fat.ar_trx_amount_received, 0)
                            else      0
                            end),                                     ----  wtd_canceL_value
                            0,                                        ----  wtd_lost_count,
                            0,                                        ----  wtd_lost_value,
                            0,                                        ----  reach_percentage_count,
                            0,                                        ----  reach_percentage_value,
                            0,                                        ----  conversion_percentage_count,
                            0                                         ----  conversion_percentage_value
                        
                        FROM    FINS_AR_TRANSACTIONS          fat
                        WHERE   1                       =   1
                        AND     fat.profit_centre_id    =   set_pc.profit_centre_id
                        AND     ( ( fat.creation_date between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.end_date      between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                        OR        ( fat.status_date   between   v_fiscal_year_start_date
                                                        and       v_fiscal_year_end_date
                                )
                                )
                        AND     fat.client_id           =   p_client_id
                        GROUP   BY  set_pc.client_id,
                                        set_pc.profit_centre_id,
                                        fat.created_by;
                        commit;
                        p_return_message  := p_return_message ||  ' - '  ||' Debtors Records Populated';
                        DBMS_OUTPUT.put_line (p_return_message);
                exception
                when        Others
                then        p_return_code   :=  2;
                            p_return_message  := p_return_message ||  ' - '  ||' Debtors Records Can not be Populated '||SQLERRM;
                            DBMS_OUTPUT.put_line (p_return_message);
                end;

        end loop;

        if    (p_return_code   = 0)
        then  p_return_message   :=  'Populating Business Resultes Completed';
              Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Populating Business Resultes Completed');
              DBMS_OUTPUT.put_line ('Populating Business Resultes Completed');
        end   if;

        commit;
        RETURN;
EXCEPTION
     WHEN       Some_Error
     THEN       DBMS_OUTPUT.put_line (p_return_message || ' - ' || SQLERRM);
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,p_return_message || ' - ' || SQLERRM);
                APEX_ERROR.add_error ( p_error_code        => p_return_message || ' - ' || SQLERRM,
                                       p0                  => null,
                                       p_display_location  => apex_error.c_inline_with_field_and_notif,
                                       p_page_item_name    => null 
                                     );
                p_return_code    :=  2;
                p_return_message :=  p_return_message ||  ' - ' || SQLERRM;
                RETURN;
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
END     CMN_Populate_Business_Results_API;
----------------------------------------------------------------------------------------------------------------------------