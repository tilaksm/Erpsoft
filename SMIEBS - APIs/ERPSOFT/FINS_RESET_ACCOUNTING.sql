--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Reset Existing Accounting
--- -     Written by    : Shriniwas Tilak
-----     Date Written  : 15th July 2023 
-----     Modified V1   : Initial Version
-----     V1 Modified on: 15th July 2023
---------------------------------------------------------------------------------------------------------------------------------
----      API to Reset Accounting
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE FINS_RESET_ACCOUNTING 
    (   p_return_code             OUT     VARCHAR2,
        p_return_message          OUT     VARCHAR2,
        p_user_id                 IN      NUMBER,
        p_client_id               IN      NUMBER,
        p_organization_id         IN      NUMBER    DEFAULT null,
        p_lob_id                  IN      NUMBER    DEFAULT null,
        p_profit_centre_id        IN      NUMBER    DEFAULT null,
        p_all_PC                  IN      VARCHAR2  DEFAULT 'N'
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
        v_status_id                             NUMBER          :=      null;
        v_status_date                           DATE            :=      null;
        v_transaction_type_set_id               NUMBER          :=      null;
        v_transaction_type_code_id              NUMBER          :=      null;
        v_dr_account_id                         number          :=      null;
        v_cr_account_id                         number          :=      null;
        v_dr_ccid                               number          :=      null;
        v_cr_ccid                               number          :=      null;
        v_trx_type                              varchar2(25)    :=      null;
        v_dr_amount                             number          :=      null;
        v_cr_amount                             number          :=      null;
        v_fiscal_year_start_date                date            :=      null;
        v_fiscal_year_end_date                  date            :=      null;

BEGIN
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started for Reseting Accounting Entries');
        DBMS_OUTPUT.put_line ('Execution Started for Reseting Accounting Entries');

        p_return_code          := 0;            ----  Successful Execution
        p_return_message       := ' '; 

----    Check  whether correct CLIENT ID has been Passed.
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating Client ID');
        DBMS_OUTPUT.put_line ('Validating Client ID');
        exists_flag     :=  'Y';
        BEGIN
                SELECT  distinct 'Y'
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

----    Check  whether correct User ID has been Passed.
        exists_flag     :=  'Y';
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating User ID');
        DBMS_OUTPUT.put_line ('Validating User ID');
        BEGIN
                SELECT  distinct 'c'
                INTO    exists_flag
                FROM    cmn_user_master 
                WHERE   1                           =   1
                AND     user_id                     =   p_user_id
                AND     client_id                   =   p_client_id;
        EXCEPTION
             WHEN   NO_DATA_FOUND
             THEN   exists_flag                     :=  null;
                    p_return_code                   :=  2;
                    p_return_message                :=  p_return_message  ||  ' - '  ||
                                                        ' Incorrect User ID Passed (Absent)';
        END;

----    Check  whether correct Organization ID has been Passed.
        exists_flag     :=  'Y';
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating Organization ID');
        DBMS_OUTPUT.put_line ('Validating Organization ID');
        IF      (p_organization_id is not null)
        THEN
                BEGIN
                        SELECT  distinct 'c'
                        INTO    exists_flag
                        FROM    cmn_organization_master 
                        WHERE   1                           =   1
                        AND     organization_id             =   p_organization_id
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                WHEN   NO_DATA_FOUND
                THEN   exists_flag                      :=  null;
                        p_return_code                   :=  2;
                        p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Orgaization ID Passed (Absent)';
                END;
        END     IF;

----    Check  whether correct LOB ID has been Passed.
        exists_flag     :=  'Y';
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating LOB ID');
        DBMS_OUTPUT.put_line ('Validating LOB ID');
        IF      (p_lob_id is not null)
        THEN
                BEGIN
                        SELECT  distinct 'c'
                        INTO    exists_flag
                        FROM    cmn_lob_master 
                        WHERE   1                           =   1
                        AND     lob_id                      =   p_lob_id
                        AND     organization_id             =   p_organization_id
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                WHEN   NO_DATA_FOUND
                THEN   exists_flag                      :=  null;
                        p_return_code                   :=  2;
                        p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect LOB ID Passed (Absent)';
                END;
        END     IF;

----    Check  whether correct Profit Centre ID has been Passed.
        exists_flag     :=  'Y';
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Validating Profit Centre ID');
        DBMS_OUTPUT.put_line ('Validating LOB ID');
        IF      (p_profit_centre_id is not null)
        THEN
                BEGIN
                        SELECT  distinct 'c'
                        INTO    exists_flag
                        FROM    cmn_profit_centre_master 
                        WHERE   1                           =   1
                        AND     profit_centre_id            =   p_profit_centre_id
                        AND     lob_id                      =   p_lob_id
                        AND     organization_id             =   p_organization_id
                        AND     client_id                   =   p_client_id;
                EXCEPTION
                WHEN   NO_DATA_FOUND
                THEN   exists_flag                      :=  null;
                        p_return_code                   :=  2;
                        p_return_message                :=  p_return_message  ||  ' - '  ||
                                                                ' Incorrect Profit Centre ID Passed (Absent)';
                END;
        END     IF;

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

----    Populate Status Id
        BEGIN
                SELECT  status_id
                INTO    v_status_id
                FROM    cmn_status_master_v
                WHERE   1                           =   1
                AND     upper(trim(status_code))    =   'ELEGIBLE-TO-ACCOUNTING'
                AND     client_id                   =   p_client_id;
        EXCEPTION
             WHEN   NO_DATA_FOUND
             THEN   exists_flag                     :=  null;
                    p_return_code                   :=  2;
                    p_return_message                :=  p_return_message  ||  ' - '  ||
                                                        ' Incorrect Status Passed (Absent)';
        END;

----    Populate fiscal Year Dates
        BEGIN
                SELECT  year_start_date,
                        year_end_date
                INTO    v_fiscal_year_start_date,
                        v_fiscal_year_end_date
                FROM    cmn_operating_periods
                WHERE   1                           =   1
                AND     to_date(sysdate)           >=   to_date(period_start_date)
                AND     to_date(sysdate)           <=   to_date(period_end_date)
                AND     client_id                   =   p_client_id;
        EXCEPTION
             WHEN   NO_DATA_FOUND
             THEN   exists_flag                     :=  null;
                    p_return_code                   :=  2;
                    p_return_message                :=  p_return_message  ||  ' - '  ||
                                                        ' Incorrect Period Passed (Absent)';
        END;

----    Delete Accounting Entries First from all Acconting Tables
        BEGIN
                  begin
                            delete 
                            from    fins_gl_jv_headers
                            where   1                         =   1
                            and     profit_centre_id          =   decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                    =   decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id           =   decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                 =   p_client_id;
                  exception
                  when      others
                  then      p_return_code                     :=  1;
                            p_return_message                  :=  p_return_message  ||  ' - '  ||
                                                                  ' Can not Delete fins_gl_jv_headers.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            delete 
                            from    fins_gl_jv_lines              jvl
                            where   1                         =   1
                            and     not exists
                                    ( select  'c'
                                      from    fins_gl_jv_headers  jvh
                                      where   1               =   1
                                      and     jvh.jv_header_id=   jvl.jv_header_id
                                      and     jvh.client_id   =   jvl.client_id
                                    )
                            and     profit_centre_id          =   decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                    =   decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id           =   decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                 =   p_client_id;
                  exception
                  when      others
                  then      p_return_code                     :=  1;
                            p_return_message                  :=  p_return_message  ||  ' - '  ||
                                                                  ' Can not Delete fins_gl_jv_lines.. Some Error '||SQLERRM;
                  end;
                  commit;

----              Now Reset fins_accounting_balances table
                  begin 
                            update  fins_accounting_balances
                            set     period_begin_balance_dr       = null,
                                    period_begin_balance_cr       = null,
                                    period_net_dr                 = null,
                                    period_net_cr                 = null,
                                    year_begin_balance_dr         = null,
                                    year_begin_balance_cr         = null,
                                    year_net_dr                   = null,
                                    year_net_cr                   = null,
                                    TR_period_begin_balance_dr    = null,
                                    TR_period_begin_balance_cr    = null,
                                    TR_period_net_dr              = null,
                                    TR_period_net_cr              = null,
                                    TR_year_begin_balance_dr      = null,
                                    TR_year_begin_balance_cr      = null,
                                    TR_year_net_dr                = null,
                                    TR_year_net_cr                = null,
                                    AR_period_begin_balance_dr    = null,
                                    AR_period_begin_balance_cr    = null,
                                    AR_period_net_dr              = null,
                                    AR_period_net_cr              = null,
                                    AR_year_begin_balance_dr      = null,
                                    AR_year_begin_balance_cr      = null,
                                    AR_year_net_dr                = null,
                                    AR_year_net_cr                = null,
                                    SR_period_begin_balance_dr    = null,
                                    SR_period_begin_balance_cr    = null,
                                    SR_period_net_dr              = null,
                                    SR_period_net_cr              = null,
                                    SR_year_begin_balance_dr      = null,
                                    SR_year_begin_balance_cr      = null,
                                    SR_year_net_dr                = null,
                                    SR_year_net_cr                = null,
                                    last_posting_id               = null,
                                    last_posted_date              = null,
                                    status_id                     = v_status_id,
                                    status_date                   = sysdate,
                                    last_updated_by               = 0,
                                    last_update_date              = sysdate
                            where   1                             = 1
----                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
----                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
----                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                       :=  1;
                            p_return_message                    :=  p_return_message  ||  ' - '  ||
                                                                    ' Can not Reset fins_accounting_balances.. Some Error '||SQLERRM;
                  end;

----              Now Reset fins_party_accounting_balances table
                  begin 
                            update  fins_party_accounting_balances
                            set     period_begin_balance_dr       = null,
                                    period_begin_balance_cr       = null,
                                    period_net_dr                 = null,
                                    period_net_cr                 = null,
                                    year_begin_balance_dr         = null,
                                    year_begin_balance_cr         = null,
                                    year_net_dr                   = null,
                                    year_net_cr                   = null,
                                    TR_period_begin_balance_dr    = null,
                                    TR_period_begin_balance_cr    = null,
                                    TR_period_net_dr              = null,
                                    TR_period_net_cr              = null,
                                    TR_year_begin_balance_dr      = null,
                                    TR_year_begin_balance_cr      = null,
                                    TR_year_net_dr                = null,
                                    TR_year_net_cr                = null,
                                    AR_period_begin_balance_dr    = null,
                                    AR_period_begin_balance_cr    = null,
                                    AR_period_net_dr              = null,
                                    AR_period_net_cr              = null,
                                    AR_year_begin_balance_dr      = null,
                                    AR_year_begin_balance_cr      = null,
                                    AR_year_net_dr                = null,
                                    AR_year_net_cr                = null,
                                    SR_period_begin_balance_dr    = null,
                                    SR_period_begin_balance_cr    = null,
                                    SR_period_net_dr              = null,
                                    SR_period_net_cr              = null,
                                    SR_year_begin_balance_dr      = null,
                                    SR_year_begin_balance_cr      = null,
                                    SR_year_net_dr                = null,
                                    SR_year_net_cr                = null,
                                    status_id                     = v_status_id,
                                    status_date                   = sysdate,
                                    last_update_date              = sysdate,
                                    last_updated_by               = 0
                            where   1                             = 1
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                       :=  1;
                            p_return_message                    :=  p_return_message  ||  ' - '  ||
                                                                    ' Can not Reset fins_party_accounting_balances.. Some Error '||SQLERRM;
                  end;

----              Now Reset fins_item_accounting_balances table
                  begin 
                            update  fins_item_accounting_balances
                            set     period_begin_balance_dr       = null,
                                    period_begin_balance_cr       = null,
                                    period_net_dr                 = null,
                                    period_net_cr                 = null,
                                    year_begin_balance_dr         = null,
                                    year_begin_balance_cr         = null,
                                    year_net_dr                   = null,
                                    year_net_cr                   = null,
                                    TR_period_begin_balance_dr    = null,
                                    TR_period_begin_balance_cr    = null,
                                    TR_period_net_dr              = null,
                                    TR_period_net_cr              = null,
                                    TR_year_begin_balance_dr      = null,
                                    TR_year_begin_balance_cr      = null,
                                    TR_year_net_dr                = null,
                                    TR_year_net_cr                = null,
                                    AR_period_begin_balance_dr    = null,
                                    AR_period_begin_balance_cr    = null,
                                    AR_period_net_dr              = null,
                                    AR_period_net_cr              = null,
                                    AR_year_begin_balance_dr      = null,
                                    AR_year_begin_balance_cr      = null,
                                    AR_year_net_dr                = null,
                                    AR_year_net_cr                = null,
                                    SR_period_begin_balance_dr    = null,
                                    SR_period_begin_balance_cr    = null,
                                    SR_period_net_dr              = null,
                                    SR_period_net_cr              = null,
                                    SR_year_begin_balance_dr      = null,
                                    SR_year_begin_balance_cr      = null,
                                    SR_year_net_dr                = null,
                                    SR_year_net_cr                = null,
----                                Reset Quantity Balances
                                    period_begin_balance_dr_qty   = null,
                                    period_begin_balance_cr_qty   = null,
                                    period_net_dr_qty             = null,
                                    period_net_cr_qty             = null,
                                    year_begin_balance_dr_qty     = null,
                                    year_begin_balance_cr_qty     = null,
                                    year_net_dr_qty               = null,
                                    year_net_cr_qty               = null,
                                    last_posting_id               = null,
                                    last_posted_date              = null,
                                    status_id                     = v_status_id,
                                    status_date                   = sysdate,
                                    last_update_date              = sysdate,
                                    last_updated_by               = 0
                            where   1                             = 1
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                       :=  1;
                            p_return_message                    :=  p_return_message  ||  ' - '  ||
                                                                  ' Can not Reset fins_party_accounting_balances.. Some Error '||SQLERRM;
                  end;

---     Now Reset Base Tables

                  begin
                            UPDATE  imr_receipt_headers                   irh
                            SET     irh.receipt_accounted_flag          = null,
                                    irh.receipt_accounting_date         = null,
                                    irh.receipt_accounting_event_id     = null,
                                    irh.receipt_accounting_header_id    = null,
                                    irh.receipt_accounting_line_id      = null,
                                    irh.receipt_eligible_to_accounting  = 'Y',
                                    irh.delivery_accounted_flag         = null,
                                    irh.delivery_accounting_date        = null,
                                    irh.delivery_accounting_event_id    = null,
                                    irh.delivery_accounting_header_id   = null,
                                    irh.delivery_accounting_line_id     = null,
                                    irh.delivery_eligible_to_accounting = 'Y',
                                    irh.status_id             = v_status_id,
                                    irh.status_date           = sysdate,
                                    irh.last_update_date      = sysdate,
                                    irh.last_updated_by       = 0
                            WHERE   1                         = 1
                            AND     irh.status_id        not in (10006,10007)
                            AND     irh.profit_centre_id      = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            AND     irh.lob_id                = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            AND     irh.organization_id       = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            AND     irh.client_id             = p_client_id;
                  exception
                  when      others
                  then      p_return_code                     :=  1;
                            p_return_message                  :=  p_return_message  ||  ' - '  ||
                                                                  ' Can not Reset imr_receipt_headers.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            UPDATE  imr_receipt_lines           irl
                            SET     irl.receipt_accounted_flag          = null,
                                    irl.receipt_accounting_date         = null,
                                    irl.receipt_accounting_event_id     = null,
                                    irl.receipt_accounting_header_id    = null,
                                    irl.receipt_accounting_line_id      = null,
                                    irl.receipt_eligible_to_accounting  = 'Y',
                                    irl.delivery_accounted_flag         = null,
                                    irl.delivery_accounting_date        = null,
                                    irl.delivery_accounting_event_id    = null,
                                    irl.delivery_accounting_header_id   = null,
                                    irl.delivery_accounting_line_id     = null,
                                    irl.delivery_eligible_to_accounting = 'Y',
                                    irl.status_id             = v_status_id,
                                    irl.status_date           = sysdate,
                                    irl.last_update_date      = sysdate,
                                    irl.last_updated_by       = 0
                            WHERE   1                         = 1
                            AND     irl.status_id        not in (10006,10007)
                            AND     irl.profit_centre_id      = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            AND     irl.lob_id                = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            AND     irl.organization_id       = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            AND     irl.client_id             = p_client_id;
                            commit;
                  exception
                  when      others
                  then      p_return_code                     :=  1;
                            p_return_message                  :=  p_return_message  ||  ' - '  ||
                                                                  ' Can not Reset imr_receipt_lines.. Some Error '||SQLERRM;
                  end;

                  begin
                            UPDATE  inv_material_transactions       fatv
                            SET     fatv.accounting_period_id     = null,
                                    fatv.accounted_flag           = null,
                                    fatv.accounted_date           = null,
                                    fatv.accounted_transaction_id = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            WHERE   1                             = 1
                            AND     fatv.status_id         not in (10006,10007)
                            AND     fatv.profit_centre_id         = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            AND     fatv.lob_id                   = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            AND     fatv.organization_id          = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            AND     fatv.client_id                = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset inv_material_transactions.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            update  fins_ar_transactions            fatv
                            set     fatv.sla_jv_name              = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_header_id            = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id           not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                        :=  1;
                            p_return_message                     :=  p_return_message  ||  ' - '  ||
                                                                    ' Can not Reset fins_ar_transactions.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            update  fins_ar_transaction_lines       fatv
                            set     fatv.sla_line_id              = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_header_id            = null,
                                    fatv.sla_line_number          = null,
                                    fatv.sla_accounting_date      = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id           not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_ar_transaction_lines.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            update  fins_ar_money_receipts          fatv
                            set     fatv.sla_jv_name              = null,
                                    fatv.sla_header_id            = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_accounting_date      = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id        not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_ar_money_receipts.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            update  fins_ar_applications            fatv
                            set     fatv.sla_jv_name              = null,
                                    fatv.sla_header_id            = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_accounting_date      = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id        not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                     :=  1;
                            p_return_message                  :=  p_return_message  ||  ' - '  ||
                                                                  ' Can not Reset fins_ar_applications.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            update  fins_ap_payments                fatv
                            set     fatv.sla_jv_name              = null,
                                    fatv.sla_header_id            = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_accounting_date      = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id        not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_ap_payments.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            update  fins_ap_transaction_payments    fatv
                            set     fatv.sla_jv_name              = null,
                                    fatv.sla_header_id            = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_accounting_date      = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id        not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                            commit;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_ap_transaction_payments.. Some Error '||SQLERRM;
                  end;

                  begin
                            update  fins_ap_transaction_lines       fatv
                            set     fatv.sla_jv_name              = null,
                                    fatv.sla_header_id            = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_accounting_date      = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id        not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_ap_transaction_lines.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            update  fins_ap_transactions            fatv
                            set     fatv.sla_jv_name              = null,
                                    fatv.sla_header_id            = null,
                                    fatv.sla_accounting_flag      = null,
                                    fatv.sla_accounting_date      = null,
                                    fatv.eligible_to_accounting   = 'Y',
                                    fatv.status_id                = v_status_id,
                                    fatv.status_date              = sysdate,
                                    fatv.last_update_date         = sysdate,
                                    fatv.last_updated_by          = 0
                            where   1                             = 1
                            AND     fatv.status_id        not in (10006,10007)
                            and     profit_centre_id              = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            and     lob_id                        = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            and     organization_id               = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            and     client_id                     = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_ap_transactions.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            UPDATE  fins_manual_gl_jv_lines         irh
                            SET     irh.gl_sl_link_id             = null,
                                    irh.gl_sl_link_table          = null,
                                    irh.sla_event_id              = null,
                                    irh.sla_header_id             = null,
                                    irh.sla_line_id               = null,
                                    irh.posted_flag               = null,
                                    irh.posted_date               = null,
                                    irh.reference_1               = null,
                                    irh.reference_5               = null,
                                    irh.eligible_to_accounting    = 'Y',
                                    irh.status_id                 = v_status_id,
                                    irh.status_date               = sysdate,
                                    irh.last_update_date          = sysdate,
                                    irh.last_updated_by           = 0
                            WHERE   1                             = 1
                            AND     irh.status_id        not in (10006,10007)
                            AND     exists
                                    ( select  'c'
                                      from    fins_manual_gl_jv_headers  fmgjh
                                      where   1                   = 1
                                      and     fmgjh.jv_header_id  = irh.jv_header_id
                                      and     fmgjh.client_id     = irh.client_id
                                      and     irh.profit_centre_id= decode(nvl(p_all_pc,'N'),'Y',profit_centre_id,p_profit_centre_id)
                                      and     irh.lob_id          = decode(nvl(p_all_pc,'N'),'Y',lob_id,p_lob_id)
                                      and     irh.organization_id = decode(nvl(p_all_pc,'N'),'Y',organization_id,p_organization_id)
                                    )
                            AND     irh.client_id                 = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_manual_gl_jv_lines.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            UPDATE  fins_manual_gl_jv_headers       irh
                            SET     irh.gl_sl_link_id             = null,
                                    irh.gl_sl_link_table          = null,
                                    irh.sla_event_id              = null,
                                    irh.sla_header_id             = null,
                                    irh.posted_flag               = null,
                                    irh.posted_date               = null,
                                    irh.eligible_to_accounting    = 'Y',
                                    irh.status_id                 = v_status_id,
                                    irh.status_date               = sysdate,
                                    irh.last_update_date          = sysdate,
                                    irh.last_updated_by           = 0
                            WHERE   1                             = 1
                            AND     irh.status_id        not in (10006,10007)
                            AND     irh.profit_centre_id          = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            AND     irh.lob_id                    = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            AND     irh.organization_id           = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            AND     irh.client_id                 = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_manual_gl_jv_headers.. Some Error '||SQLERRM;
                  end;
                  commit;

                  begin
                            UPDATE  cmn_table_sequences             irh
                            SET     last_document_number          = initial_document_number,
                                    status_id                     = 10012,
                                    status_date                   = sysdate
                            WHERE   1                             = 1
                            AND     upper(trim(irh.table_name))  in   ( 'FINS_ACCOUNTING_BALANCES',
                                                                        'FINS_PARTY_ACCOUNTING_BALANCES',
                                                                        'FINS_ITEM_ACCOUNTING_BALANCES',
                                                                        'FINS_GL_JV_HEADERS',
                                                                        'FINS_GL_JV_LINES'
                                                                      )
                            AND     irh.start_date                = v_fiscal_year_start_date
                            AND     irh.end_date                  = v_fiscal_year_end_date
                            AND     irh.profit_centre_id          = decode(nvl(p_all_PC,'N'),'Y',profit_centre_id,p_profit_centre_id)
                            AND     irh.lob_id                    = decode(nvl(p_all_PC,'N'),'Y',lob_id,p_lob_id)
                            AND     irh.organization_id           = decode(nvl(p_all_PC,'N'),'Y',organization_id,p_organization_id)
                            AND     irh.client_id                 = p_client_id;
                  exception
                  when      others
                  then      p_return_code                         :=  1;
                            p_return_message                      :=  p_return_message  ||  ' - '  ||
                                                                      ' Can not Reset fins_manual_gl_jv_headers.. Some Error '||SQLERRM;
                  end;
                  commit;

/*                  CSP_Build_Account_Combinations_API
                  ( RETURN_CODE        => p_return_code,
                    RETURN_MESSAGE     => p_return_message,
                    p_user_id          => p_user_id,
                    p_client_id        => p_client_id,
                    p_organization_id  => null,
                    p_lob_id           => null,
                    p_profit_centre_id => null,
                    p_account_code_id  => null
                  );

                  CSP_Build_Accounting_Balances_API
                  ( RETURN_CODE                   => p_return_code,
                    RETURN_MESSAGE                => p_return_message,
                    p_place_lattitude             => '18.49926036387643',
                    p_place_longitude             => '73.80946714514282',
                    p_place_ip_address            => '58.84.61.64',
                    p_transaction_application_id  => 302,
                    p_transaction_type_id         => 30206,
                    p_user_id                     => p_user_id,
                    p_client_id                   => p_client_id,
                    p_code_combination_id         => null,
                    p_period_id                   => null 
                  );

                  CSP_Build_Item_Balances_API
                  ( RETURN_CODE                   => p_return_code,
                    RETURN_MESSAGE                => p_return_message,
                    p_place_lattitude             => '18.49926036387643',
                    p_place_longitude             => '73.80946714514282',
                    p_place_ip_address            => '58.84.61.64',
                    p_transaction_application_id  => 302,
                    p_transaction_type_id         => 30206,
                    p_user_id                     => p_user_id,
                    p_client_id                   => p_client_id,
                    p_Item_combination_id         => null,
                    p_Inventory_Item_id           => null,
                    p_period_id                   => null 
                  );

                  CSP_Build_Party_Balances_API
                  ( RETURN_CODE                   => p_return_code,
                    RETURN_MESSAGE                => p_return_message,
                    p_place_lattitude             => '18.49926036387643',
                    p_place_longitude             => '73.80946714514282',
                    p_place_ip_address            => '58.84.61.64',
                    p_transaction_application_id  => 302,
                    p_transaction_type_id         => 30206,
                    p_user_id                     => p_user_id,
                    p_client_id                   => p_client_id,
                    p_party_combination_id        => null,
                    p_party_id                    => null,
                    p_period_id                   => null 
                  );
*/
        EXCEPTION
        WHEN      OTHERS
        THEN      RAISE Some_Error;
                  RETURN;
        END;
        commit;

        IF    ( p_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

        p_return_code           :=      0;
        p_return_message        :=      ' Accounting Reset Successful';
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
END     FINS_RESET_ACCOUNTING;
---------------------------------------------------------------------------------------------------------------------------------
