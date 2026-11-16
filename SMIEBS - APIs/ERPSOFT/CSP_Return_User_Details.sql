--------------------------------------------------------------------------------------------------------------------------------------------------
----      Query Which will Return All User and Other Details Required to be Loaded once Logged in
--- -     Written by    : Manali Kulkarni
-----     Date Written  : 20th Februaryy 2021 
-----     Modified V1   : Shriniwas Tilak
-----     V1 Modified on: 1st March 2023
---------------------------------------------------------------------------------------------------------------------------------
----      User Details  
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE "CSP_RETURN_USER_DETAILS" 
          (   p_return_code                    OUT  VARCHAR2,
              p_return_message                 OUT  VARCHAR2,                                                       
              p_user_name                       IN  VARCHAR2,
              p_user_id                     IN OUT  NUMBER,
              p_client_id                       IN  NUMBER, 
              p_client_code                    OUT  VARCHAR2,
              p_client_name                    OUT  VARCHAR2,                                                     
              p_Description                    OUT  VARCHAR2,
              p_encrypted_password             OUT  VARCHAR2,
              p_mobile_number                  OUT  NUMBER,                                                       
              p_Mimei                          OUT  VARCHAR2,                                                 
              p_Eimei                          OUT  VARCHAR2,                                                 
              p_Msim_number                    OUT  VARCHAR2,                                                 
              p_Esim_number                    OUT  VARCHAR2,                                                 
              p_device_id                      OUT  VARCHAR2,                                                 
              p_email_id                       OUT  VARCHAR2,                                                
              p_role_id                        OUT  NUMBER, 
              p_role_code                      OUT  VARCHAR2,
              p_role_name                      OUT  VARCHAR2,  
              p_party_id                       OUT  NUMBER, 
              p_party_number                   OUT  VARCHAR2,
              p_party_name                     OUT  VARCHAR2,
              p_enable_help                    OUT  VARCHAR2,
              p_app_url                        OUT  VARCHAR2,
              p_message_centre_key             OUT  VARCHAR2,
              p_message_centre_url             OUT  VARCHAR2,
              p_aop_key                        OUT  VARCHAR2,
              p_aop_url                        OUT  VARCHAR2,
              p_object_storage_key             OUT  VARCHAR2,
              p_object_storage_url             OUT  VARCHAR2,
              p_setup_access                   OUT  VARCHAR2,
              p_approval_access                OUT  VARCHAR2,
              p_cancellation_access            OUT  VARCHAR2,
              p_closure_access                 OUT  VARCHAR2,
              p_deletion_access                OUT  VARCHAR2,
              p_download_access                OUT  VARCHAR2,
              p_transaction_access             OUT  VARCHAR2,
              p_super_user_access              OUT  VARCHAR2,
              p_maps_url                       OUT  VARCHAR2,
              p_maps_key                       OUT  VARCHAR2,
              p_cohere_url                     OUT  VARCHAR2,
              p_cohere_key                     OUT  VARCHAR2,
              p_open_ai_url                    OUT  VARCHAR2,
              p_open_ai_key                    OUT  VARCHAR2,
              p_my_home                        OUT  VARCHAR2,
              p_administrator_access           OUT  VARCHAR2,
              p_edit_auto_created_documents    OUT  VARCHAR2,
              p_send_mails                     OUT  VARCHAR2,
              p_send_sms                       OUT  VARCHAR2,
              p_send_notifications             OUT  VARCHAR2
          )
AS 

----   Declare Variables and Cursors required for generation
        err_message varchar2(200) := null;
        exists_flag varchar2(01)  := null;
        recs_added  number        := 0;

BEGIN
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Populating User Data....for '||P_USER_NAME);
        DBMS_OUTPUT.put_line ('Populating User Data....for '||P_USER_NAME);
        p_return_message    :=  ' ';
        p_return_code       :=  0;

----    Validate Input Parameters
        IF    (p_user_name is null)
        THEN  Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'User Id should not be null');
              DBMS_OUTPUT.put_line ('User Id should not be null');
        END   IF;


----    Extract User Details
        BEGIN  
                SELECT  u.client_code,
                        (trim(u.client_name)),
                        u.user_id,
                        (trim(u.Description)),
                        u.encrypted_password,
                        u.mobile_number,                                                       
                        u.Mimei,                                                 
                        u.Eimei,                                                 
                        u.Msim_number,                                                 
                        u.Esim_number,                                                 
                        u.device_id,                                                 
                        u.email_id,                                                
                        u.role_id,  
                        u.role_code,
                        initcap(trim(u.role_name)),
                        u.party_id,
                        u.party_number,
                        initcap(trim(u.party_name)),
                        ( SELECT  enable_help
                          FROM    cmn_client_master c
                          WHERE   c.client_id = u.client_id),
                        ( SELECT  app_url
                          FROM    cmn_client_master c
                          WHERE   c.client_id = u.client_id),
                        ( SELECT  APP_KEY
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'MESSAGES'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_URL
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'MESSAGES'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_KEY
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'AOP'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_URL
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'AOP'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_KEY
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'ORACLE_CLOUD_STORAGE'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_URL
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'ORACLE_CLOUD_STORAGE'
                          and     c.client_id                     = u.client_id),
                        nvl(upper(trim(super_user_access)),'N'),
                        nvl(upper(trim(setup_access)),'N'),
                        nvl(upper(trim(approval_access)),'N'),
                        nvl(upper(trim(cancellation_access)),'N'),
                        nvl(upper(trim(closure_access)),'N'),
                        nvl(upper(trim(deletion_access)),'N'),
                        nvl(upper(trim(downloading_access)),'N'),
                        nvl(upper(trim(transaction_access)),'N'),
                        nvl(upper(trim(administrator_access)),'N'),
                        nvl(upper(trim(edit_auto_created_documents)),'N'),
                        nvl(upper(trim(send_mails)),'N'),
                        nvl(upper(trim(send_sms)),'N'),
                        nvl(upper(trim(send_notifications)),'N'),
                        ( SELECT  APP_URL
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'GOOGLE_MAPS'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_KEY
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'GOOGLE_MAPS'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_URL
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'COHERE_AI'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_KEY
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'COHERE_AI'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_URL
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'OPEN_AI'
                          and     c.client_id                     = u.client_id),
                        ( SELECT  APP_KEY
                          FROM    cmn_client_authentications_v      c
                          WHERE   1                               = 1
                          and     upper(ltrim(rtrim(c.app_code))) = 'OPEN_AI'
                          and     c.client_id                     = u.client_id),
                          apex_page.get_url 
                          ( p_application=> 101,
                            p_page=>101
                          )
                INTO    p_client_code,
                        p_client_name,
                        p_user_id,                   
                        p_Description,
                        p_encrypted_password,
                        p_mobile_number,
                        p_Mimei,
                        p_Eimei,
                        p_Msim_number,
                        p_Esim_number,
                        p_device_id,
                        p_email_id,
                        p_role_id,
                        p_role_code,
                        p_role_name,
                        p_party_id,
                        p_party_number,
                        p_party_name,
                        p_enable_help,
                        p_app_url,
                        p_message_centre_key,
                        p_message_centre_url,
                        p_aop_key,
                        p_aop_url,
                        p_object_storage_key,
                        p_object_storage_url,
                        p_super_user_access,
                        p_setup_access,
                        p_approval_access,
                        p_cancellation_access,
                        p_closure_access,
                        p_deletion_access,
                        p_download_access,
                        p_transaction_access,
                        p_administrator_access,
                        p_edit_auto_created_documents,
                        p_send_mails,
                        p_send_sms,
                        p_send_notifications,
                        p_maps_url,
                        p_maps_key,
                        p_cohere_url,
                        p_cohere_key,
                        p_open_ai_url,
                        p_open_ai_key,
                        p_my_home
                FROM    cmn_user_master_v       u
                WHERE   1 = 1
                AND     upper(u.user_name)          =  upper(P_USER_NAME)
                AND     u.client_id                 =  p_client_id;
        EXCEPTION  
                WHEN    NO_DATA_FOUND
                THEN    p_client_code              :=  null;
                        p_client_name              :=  null;
                        p_Description              :=  null;
                        p_encrypted_password       :=  null;
                        p_mobile_number            :=  null;
                        p_Mimei                    :=  null;
                        p_Eimei                    :=  null;
                        p_Msim_number              :=  null;
                        p_Esim_number              :=  null;
                        p_device_id                :=  null;
                        p_email_id                 :=  null;
                        p_role_id                  :=  null;
                        p_role_code                :=  null;
                        p_role_name                :=  null;
                        p_party_id                 :=  null;
                        p_party_number             :=  null;
                        p_party_name               :=  null;
                        p_enable_help              :=  null;
                        p_app_url                  :=  null;
                        p_message_centre_key       :=  null;
                        p_message_centre_url       :=  null;
                        p_aop_key                  :=  null;
                        p_aop_url                  :=  null;
                        p_object_storage_key       :=  null;
                        p_object_storage_url       :=  null; 
                        p_super_user_access        :=  'N';
                        p_setup_access             :=  'N';
                        p_approval_access          :=  'N';
                        p_cancellation_access      :=  'N';
                        p_closure_access           :=  'N';
                        p_deletion_access          :=  'N';
                        p_download_access          :=  'N';
                        p_transaction_access       :=  'N';
                        p_administrator_access     :=  'N';
                        p_edit_auto_created_documents:=  'N';
                        p_send_mails               :=  'N';
                        p_send_sms                 :=  'N';
                        p_send_notifications       :=  'N';
                        p_maps_url                 :=  null;
                        p_maps_key                 :=  null;
                        p_cohere_url               :=  null;
                        p_cohere_key               :=  null;
                        p_open_ai_url              :=  null;
                        p_open_ai_key              :=  null;
                        p_my_home                  :=  null;
                        p_return_code              :=  2;
                        p_return_message           :=  p_return_message || ' - ' || 
                                                       'No Data Found for User - '||P_USER_NAME;
                WHEN    OTHERS
                THEN    p_client_code              :=  null;
                        p_client_name              :=  null;
                        p_Description              :=  null;
                        p_encrypted_password       :=  null;
                        p_mobile_number            :=  null;
                        p_Mimei                    :=  null;
                        p_Eimei                    :=  null;
                        p_Msim_number              :=  null;
                        p_Esim_number              :=  null;
                        p_device_id                :=  null;
                        p_email_id                 :=  null;
                        p_role_id                  :=  null;
                        p_role_code                :=  null;
                        p_role_name                :=  null;
                        p_party_id                 :=  null;
                        p_party_number             :=  null;
                        p_party_name               :=  null;
                        p_enable_help              :=  null;
                        p_app_url                  :=  null;
                        p_message_centre_key       :=  null;
                        p_message_centre_url       :=  null;
                        p_aop_key                  :=  null;
                        p_aop_url                  :=  null;
                        p_object_storage_key       :=  null;
                        p_object_storage_url       :=  null;
                        p_super_user_access        :=  'N';
                        p_setup_access             :=  'N';
                        p_approval_access          :=  'N';
                        p_cancellation_access      :=  'N';
                        p_closure_access           :=  'N';
                        p_deletion_access          :=  'N';
                        p_download_access          :=  'N';
                        p_transaction_access       :=  'N';
                        p_administrator_access     :=  'N';
                        p_edit_auto_created_documents:=  'N';
                        p_send_mails               :=  'N';
                        p_send_sms                 :=  'N';
                        p_send_notifications       :=  'N';
                        p_maps_url                 :=  null;
                        p_maps_key                 :=  null;
                        p_cohere_url               :=  null;
                        p_cohere_key               :=  null;
                        p_open_ai_url              :=  null;
                        p_open_ai_key              :=  null;
                        p_my_home                  :=  null;
                        p_return_message           :=  p_return_message || ' - ' || 
                                                      'OTHERS - No Data Found for User - '  ||P_USER_NAME;                        
        END; 

----    Get Default Home Page
        BEGIN
                    SELECT  apex_page.get_url 
                            ( p_application=> 101,
                              p_page=>101
                            )
                    INTO    p_my_home
                    FROM    DUAL;
        EXCEPTION
        WHEN        OTHERS
        THEN        p_my_home         :=  null;
        END;

----    Get Default Home Page for role
        BEGIN
                    SELECT  apex_page.get_url 
                            ( p_application=> r.home_application_id,
                              p_page=>r.home_page_id
                            )
                    INTO    p_my_home
                    FROM    cmn_role_master_v       r
                    WHERE   1                     = 1
                    AND     r.role_id             = p_role_id
                    AND     r.client_id           = p_client_id;
        EXCEPTION
        WHEN        OTHERS
        THEN        null;
        END;

----    Get Default Home Page for User
        BEGIN
                    SELECT  apex_page.get_url 
                            ( p_application=> u.home_application_id,
                              p_page=>u.home_page_id
                            )
                    INTO    p_my_home
                    FROM    cmn_user_master        u
                    WHERE   1                     = 1
                    AND     u.user_id             = p_user_id
                    AND     u.client_id           = p_client_id;
        EXCEPTION
        WHEN        OTHERS
        THEN        null;
        END;

        Apex_Util.Set_Session_State('RETURN_MESSAGE' , 'Success - User Data Returnd');
        DBMS_OUTPUT.put_line ('Success - User Data Returnd');
        RETURN;
END;
---------------------------------------------------------------------------------------------------------------------------------
