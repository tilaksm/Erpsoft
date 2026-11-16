--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Generate Accounting for Payables Transactions.
----      These include, Invoices, Credit Notes, Debit Notes, Supplier Payments and Its Applications.
--- -     Written by    : Shriniwas Tilak.
-----     Date Written  : 03rd April 2024
-----     Modified V1   : 
-----     V1 Modified on: 
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE FINS_PAYABLES_ACCOUNTING_PACKAGE_API
              ( s_return_code                 out varchar2,
                s_return_message              out varchar2,
                s_place_lattitude             in  varchar2  default null,
                s_place_longitude             in  varchar2  default null,
                s_place_ip_address            in  varchar2  default null,
                s_transaction_type_id         in  number    default null,
                s_transaction_application_id  in  number    default 303,
                s_transaction_process_id      in  number    default null,
                s_transaction_level_id        in  number    default null,
                s_trx_accounting              in  varchar2  default 'Y',
                s_payment_accounting          in  varchar2  default 'Y',
                s_appl_accounting             in  varchar2  default 'Y',
                s_user_id                     in  varchar2  default 0,
                s_client_id                   in  number,
                s_organization_id             in  number    default null,
                s_lob_id                      in  number    default null,
                s_profit_centre_id            in  number    default null,
                s_ap_trx_id                   in  number    default null,
                s_check_id                    in  number    default null,
                s_transaction_payment_id      in  number    default null
              )
    IS
-----   Accounting Engine Start Here 
----    Declare Variables and Cursors required for generation
        err_message                         varchar2(200)     :=  null;
        exists_flag                         varchar2(01)      :=  null;
        dummy_flag                          varchar2(01)      :=  null;
        events_created                      number            :=  null;
        headers_created                     number            :=  null;
        lines_created                       number            :=  null;
        v_sla_accounted_status              number            :=  null;
        v_gl_trasnfer_status                number            :=  null;
        v_from_email_id                     varchar2(100)     :=  'erpsoft@shrisoft.org';
        v_to_email_id                       varchar2(100)     :=  null;
        v_to_email_user_id                  number            :=  null;
        v_cc_email_id                       varchar2(100)     :=  null;
        v_bcc_email_id                      varchar2(100)     :=  null;


        Some_Error                          EXCEPTION;

BEGIN
----      Validate Client ID
          s_return_code   :=  null;
          s_return_message:=  null;
          exists_flag     :=  null;
          BEGIN
              SELECT    'Y'
              INTO      exists_flag
              FROM      CMN_CLIENT_MASTER
              WHERE     1                   =   1
              AND       CLIENT_ID           =   s_client_id;
              EXCEPTION
              WHEN      NO_DATA_FOUND
              THEN      s_return_code       :=  2;
                        s_return_message    :=  s_return_message||' - '||'No Data-Invalid Client ID';
              WHEN      OTHERS
              THEN      s_return_code       :=  2;
                        s_return_message    :=  s_return_message||' - '||'Others-Invalid Client ID';
          END;

----    Validate Organization ID
        IF    ( s_organization_id is not null)
        THEN  
              exists_flag  :=  null;
              BEGIN  
                      SELECT  'Y'
                      INTO    exists_flag
                      FROM    cmn_organization_master
                      WHERE   1                   =   1
                      AND     organization_id     =   s_organization_id
                      AND     client_id           =   s_client_id;
              EXCEPTION
                      WHEN    NO_DATA_FOUND
                      THEN    s_return_code       :=  2;
                              s_return_message    :=  s_return_message || ' - ' ||
                                                      'Invalid Organization ID Passed';
                      WHEN    OTHERS
                      THEN    s_return_code       :=  2;
                              s_return_message    :=  s_return_message || ' - ' ||
                                                      'Invalid Organization ID Passed';
              END;
        END IF;

----    Validate LOB ID
        exists_flag  :=  null;
        IF    ( s_lob_id is not null)
        THEN  
              BEGIN  
                      SELECT  'Y'
                      INTO    exists_flag
                      FROM    cmn_lob_master
                      WHERE   1                   =   1
                      AND     organization_id     =   s_organization_id
                      AND     lob_id              =   s_lob_id
                      AND     client_id           =   s_client_id;
              EXCEPTION
                      WHEN    NO_DATA_FOUND
                      THEN    s_return_code       :=   2;
                              s_return_message    :=   s_return_message || ' - ' ||
                                                      'Invalid LOB ID Passed';
                      WHEN    OTHERS
                      THEN    s_return_code       :=   2;
                              s_return_message    :=   s_return_message || ' - ' ||
                                                      'Invalid LOB ID Passed';
              END;
        END IF;

----    Validate Profit Centre ID
        exists_flag  :=  null;
        IF    ( s_profit_centre_id  is not null)
        THEN
              BEGIN  
                      SELECT  'Y'
                      INTO    exists_flag
                      FROM    cmn_profit_centre_master
                      WHERE   1                   =   1
                      AND     organization_id     =   s_organization_id
                      AND     lob_id              =   s_lob_id
                      AND     profit_centre_id    =   s_profit_centre_id
                      AND     client_id           =   s_client_id;
              EXCEPTION
                      WHEN    NO_DATA_FOUND
                      THEN    s_return_code       :=   2;
                              s_return_message    :=   s_return_message || ' - ' ||
                                                      'Invalid Profit Centre ID Passed';
                      WHEN    OTHERS
                      THEN    s_return_code       :=   2;
                              s_return_message    :=   s_return_message || ' - ' ||
                                                      'Invalid Profit Centre ID Passed';
              END;
        END IF;

----    Get Mail ID for the person
        v_to_email_id                   :=      null;
        v_to_email_user_id              :=      s_user_id;
        if     (s_user_id)   is      not null
        then    v_to_email_user_id      :=      s_user_id;
        end     if;
        BEGIN
                SELECT  nvl(u.email_id,cpm.primary_email_id),
                        'tilaksm@shrisoft.in'
                INTO    v_to_email_id,
                        v_cc_email_id
                FROM    cmn_employee_master_v   cpm,
                        cmn_user_master         u
                WHERE   1                       =       1
                AND     cpm.client_id           =       u.client_id
                AND     cpm.party_id            =       u.party_id
                AND     u.user_id               =       v_to_email_user_id
                AND     u.client_id             =       s_client_id;
        EXCEPTION
        WHEN            OTHERS
        THEN            v_to_email_id   :=      null;
        END;

----    Validate Transaction Accounting Flag
        IF    (s_trx_accounting not in ('Y','N'))
        THEN  s_return_code       :=  2;
              s_return_message    :=  s_return_message || ' - ' ||
                                                    'Invalid Transaction Accounting Flag Passed';
        END IF; 

----    Validate Payments Accounting Flag
        IF    (s_payment_accounting not in ('Y','N'))
        THEN  s_return_code       :=  2;
              s_return_message    :=  s_return_message || ' - ' ||
                                                    'Invalid Payment Accounting Flag Passed';
        END IF; 

----    Validate Payments Application Accounting Flag
        IF    (s_appl_accounting not in ('Y','N'))
        THEN  s_return_code       :=  2;
              s_return_message    :=  s_return_message || ' - ' ||
                                                    'Invalid Application Accounting Flag Passed';
        END IF; 

----    Get SLA_ACCOUNTED Status ID
        BEGIN  
                SELECT  csm.status_id
                INTO    v_sla_accounted_status
                FROM    cmn_status_master               csm
                WHERE   upper(trim(csm.status_code)) = 'SLA-ACCOUNTED'
                AND     client_id                     = s_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    s_return_code           :=  2;
                        s_return_message        :=  s_return_message || ' - ' ||
                                                    'Invalid SLA-ACCOUNTED Status ID Passed';
                WHEN    OTHERS
                THEN    s_return_code           :=  2;
                        s_return_message        :=  s_return_message || ' - ' ||
                                                    'Invalid SLA-ACCOUNTED Status ID Passed';
        END;

----    Get GL_TRANSFER Status ID
        BEGIN  
                SELECT  csm.status_id
                INTO    v_gl_trasnfer_status
                FROM    cmn_status_master               csm
                WHERE   upper(trim(csm.status_code)) = 'GL-TRANSFER'
                AND     client_id                     = s_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    s_return_code           :=  2;
                        s_return_message        :=  s_return_message || ' - ' ||
                                                    'Invalid GL-TRANSFER Status ID Passed';
                WHEN    OTHERS
                THEN    s_return_code           :=  2;
                        s_return_message        :=  s_return_message || ' - ' ||
                                                    'Invalid GL-TRANSFER Status ID Passed';
        END;

---     Verify if thre is an error, if yes then raise exception and exit out
        IF    ( s_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;

----    PRocessing Starts here --- First We will call the procedure to build the Code_Combination_Id's
        CSP_Build_Account_Combinations_API
        ( RETURN_CODE          =>  s_return_code,
          RETURN_MESSAGE       =>  s_return_message,
          p_user_id            =>  s_user_id,
          p_client_id          =>  s_client_id,
          p_organization_id    =>  null, ---- s_organization_id,
          p_lob_id             =>  null, ---- s_lob_id,
          p_profit_centre_id   =>  null, ---- s_profit_centre_id,
          p_account_code_id    =>  null
        );

----    Now Send the Email to the Respective Person for informing the transaction
        IF      ((v_to_email_id IS NOT NULL) and (s_return_code = 0))
        THEN    apex_mail.send
                (       p_from      =>  v_from_email_id,
                        p_to        =>  v_to_email_id,
                        p_cc        =>  v_cc_email_id,
                        p_bcc       =>  v_bcc_email_id,
                        p_body      =>  'Account Combnation Building Dated - '||to_char('DD-MON-YYYY HH24:MIS:SS')||' Successful',
                        p_subj      =>  'Payables - Account Combination Building'
                );
                apex_mail.push_queue;
        END IF;

        IF      ( s_return_code <> 0)
        THEN    raise  Some_Error;
        END     IF;
        s_return_message    :=  s_return_message||' - '||'Account Combination Building Successful '||chr(10)||chr(30);
        dbms_output.put_line (s_return_message);

----    Processing Starts here --- If the Trx_acocunting flag is 'ON' then we will process transaction Accounting
        IF    (s_trx_accounting = 'Y')
        THEN
              fins_payables_transaction_accounting_api
              ( p_return_code                 =>  s_return_code,
                p_return_message              =>  s_return_message,
                p_place_lattitude             =>  s_place_lattitude,
                p_place_longitude             =>  s_place_longitude,
                p_place_ip_address            =>  s_place_ip_address,
                p_transaction_type_id         =>  s_transaction_type_id,
                p_transaction_application_id  =>  s_transaction_application_id,
                p_transaction_process_id      =>  s_transaction_process_id,
                p_transaction_level_id        =>  s_transaction_level_id,
                p_user_id                     =>  s_user_id,
                p_client_id                   =>  s_client_id,
                p_organization_id             =>  s_organization_id,
                p_lob_id                      =>  s_lob_id,
                p_profit_centre_id            =>  s_profit_centre_id,
                p_ap_trx_id                   =>  s_ap_trx_id
              );
              s_return_message    :=  s_return_message||' - '||'Transaction Accounting Successful '||chr(10)||chr(30);
              dbms_output.put_line (s_return_message);

              IF      ((v_to_email_id IS NOT NULL) and (s_return_code = 0))
              THEN    apex_mail.send
                      (       p_from      =>  v_from_email_id,
                              p_to        =>  v_to_email_id,
                              p_cc        =>  v_cc_email_id,
                              p_bcc       =>  v_bcc_email_id,
                              p_body      =>  'Payables Transaction Accounting Dated - '||to_char('DD-MON-YYYY HH24:MIS:SS')||' Successful',
                              p_subj      =>  'Payables - Transactions Accounting'
                      );
                      apex_mail.push_queue;
                END   IF; 

              fins_payables_approval_accounting_api
              ( p_return_code                 =>  s_return_code,
                p_return_message              =>  s_return_message,
                p_place_lattitude             =>  s_place_lattitude,
                p_place_longitude             =>  s_place_longitude,
                p_place_ip_address            =>  s_place_ip_address,
                p_transaction_type_id         =>  s_transaction_type_id,
                p_transaction_application_id  =>  s_transaction_application_id,
                p_transaction_process_id      =>  s_transaction_process_id,
                p_transaction_level_id        =>  s_transaction_level_id,
                p_user_id                     =>  s_user_id,
                p_client_id                   =>  s_client_id,
                p_organization_id             =>  s_organization_id,
                p_lob_id                      =>  s_lob_id,
                p_profit_centre_id            =>  s_profit_centre_id,
                p_ap_trx_id                   =>  s_ap_trx_id
              );

              s_return_message    :=  s_return_message||' - '||'Transaction Approval Accounting Successful '||chr(10)||chr(30);
              dbms_output.put_line (s_return_message);

              IF      ((v_to_email_id IS NOT NULL) and (s_return_code = 0))
              THEN    apex_mail.send
                      (       p_from      =>  v_from_email_id,
                              p_to        =>  v_to_email_id,
                              p_cc        =>  v_cc_email_id,
                              p_bcc       =>  v_bcc_email_id,
                              p_body      =>  'Payables Transaction Accounting Dated - '||to_char('DD-MON-YYYY HH24:MIS:SS')||' Successful',
                              p_subj      =>  'Payables - Transactions Accounting'
                      );
                      apex_mail.push_queue;
                END   IF; 
        END     IF;

        IF      ( s_return_code <> 0)
        THEN    raise  Some_Error;
        END     IF;

----    Processing Starts here --- If the Receipt_accounting flag is 'ON' then we will process Receipt Accounting
        IF    (s_payment_accounting = 'Y')
        THEN
              fins_payables_payment_accounting_api
              ( p_return_code                 =>  s_return_code,
                p_return_message              =>  s_return_message,
                p_place_lattitude             =>  s_place_lattitude,
                p_place_longitude             =>  s_place_longitude,
                p_place_ip_address            =>  s_place_ip_address,
                p_transaction_type_id         =>  s_transaction_type_id,
                p_transaction_application_id  =>  s_transaction_application_id,
                p_transaction_process_id      =>  s_transaction_process_id,
                p_transaction_level_id        =>  s_transaction_level_id,
                p_user_id                     =>  s_user_id,
                p_client_id                   =>  s_client_id,
                p_organization_id             =>  s_organization_id,
                p_lob_id                      =>  s_lob_id,
                p_profit_centre_id            =>  s_profit_centre_id,
                p_check_id                    =>  s_check_id
              );

              IF      ((v_to_email_id IS NOT NULL) and (s_return_code = 0))
              THEN    apex_mail.send
                      (       p_from      =>  v_from_email_id,
                              p_to        =>  v_to_email_id,
                              p_cc        =>  v_cc_email_id,
                              p_bcc       =>  v_bcc_email_id,
                              p_body      =>  'Payables Payment Accounting Dated - '||to_char('DD-MON-YYYY HH24:MIS:SS')||' Successful',
                              p_subj      =>  'Payables - Payment Accounting '
                      );
                      apex_mail.push_queue;
                END   IF;
        END     IF;

        IF      ( s_return_code <> 0)
        THEN    raise  Some_Error;
        END     IF;

        s_return_message    :=  s_return_message||' - '||'Payment Accounting Successful '||chr(10)||chr(30);
        dbms_output.put_line (s_return_message);

----    Processing Starts here --- If the s_appl_accounting flag is 'ON' then we will process AR Applications Accounting
        IF    (s_appl_accounting = 'Y')
        THEN
              fins_payables_application_accounting_api
              ( p_return_code                 =>  s_return_code,
                p_return_message              =>  s_return_message,
                p_place_lattitude             =>  s_place_lattitude,
                p_place_longitude             =>  s_place_longitude,
                p_place_ip_address            =>  s_place_ip_address,
                p_transaction_type_id         =>  s_transaction_type_id,
                p_transaction_application_id  =>  s_transaction_application_id,
                p_transaction_process_id      =>  s_transaction_process_id,
                p_transaction_level_id        =>  s_transaction_level_id,
                p_user_id                     =>  s_user_id,
                p_client_id                   =>  s_client_id,
                p_organization_id             =>  s_organization_id,
                p_lob_id                      =>  s_lob_id,
                p_profit_centre_id            =>  s_profit_centre_id,
                p_transaction_payment_id      =>  s_transaction_payment_id
              );

              IF      ((v_to_email_id IS NOT NULL) and (s_return_code = 0))
              THEN    apex_mail.send
                      (       p_from      =>  v_from_email_id,
                              p_to        =>  v_to_email_id,
                              p_cc        =>  v_cc_email_id,
                              p_bcc       =>  v_bcc_email_id,
                              p_body      =>  'Payables Applications Accounting Dated - '||to_char('DD-MON-YYYY HH24:MIS:SS')||' Successful',
                              p_subj      =>  'Payables - Applications Accounting '
                      );
                      apex_mail.push_queue;
              END IF;
        END   IF;

        IF    ( s_return_code <> 0)
        THEN  raise  Some_Error;
        END   IF;
        s_return_message    :=  s_return_message||' - '||'Payment Application Accounting Successful '||chr(10)||chr(30);
        dbms_output.put_line (s_return_message);

        s_return_message    :=  s_return_message||' - '||'Transfer to GL Successful '||chr(10)||chr(30);
        dbms_output.put_line (s_return_message);

        s_return_code     :=  0;
        s_return_message  :=  'AP (Payables) Accounting Process Completed Succfully....';
        RETURN;

EXCEPTION
WHEN        some_error
THEN        DBMS_OUTPUT.put_line (s_return_message || ' - ' || SQLERRM);
            Apex_Util.Set_Session_State('RETURN_MESSAGE' ,s_return_message || ' - ' || SQLERRM);
            APEX_ERROR.add_error ( p_error_code         => s_return_message || ' - ' || SQLERRM,
                                   p0                   => null,
                                   p_display_location   => apex_error.c_inline_with_field_and_notif,
                                   p_page_item_name     => null 
                                );
            s_return_code     :=  2;
            s_return_message  :=  s_return_message || ' - ' || SQLERRM;
            RETURN;
END fins_payables_accounting_package_api;
---------------------------------------------------------------------------------------------------------------------------------
