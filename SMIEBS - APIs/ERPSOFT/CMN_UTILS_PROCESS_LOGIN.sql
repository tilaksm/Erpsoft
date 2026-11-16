--------------------------------------------------------------------------------------------------------------------------------------------------
----      Process Login
--- -     Written by    : Manali Kulkarni
-----     Date Written  : 6th March 2021 
-----     Modified V1   : 
-----     V1 Modified on: 
-------------------------------------------------------------------------------------------------------------------------------
----      Process Login
------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE CMN_UTILS_PROCESS_LOGIN 
                   (  RETURN_CODE          VARCHAR2,
                      RETURN_MESSAGE       VARCHAR2,
                      p_User_Name          VARCHAR2,
                      p_Password           VARCHAR2,
                      p_App_Id             NUMBER,
                      p_client_id          number
                   )  
As
                   v_Result               Boolean                                := False;
                   v_user_id              cmn_User_master.user_id%Type;
                   v_user_name            cmn_User_master.user_name%Type;
                   v_page                 varchar2(50)  :=  ':HOME';
                   v_app                  varchar2(10)  :=  '101';


BEGIN
----    Authenticate the User First
        Apex_Util.Set_Session_State('LOGIN_MESSAGE','Authenticating for - Client ID'||p_client_id || ' User - ' || p_user_name);

        BEGIN
                    select  min(':GET-LOCATION'),
                            min('101')
                    into    v_page,
                            v_app
                    from    cmn_client_master 
                    where   1             = 1
                    and     client_id     = p_client_id;
        EXCEPTION
        WHEN        OTHERS
        THEN        v_page  :=  ':HOME';
                    v_app   :=  '101';
        END;

        v_Result := CMN_UTILS_Authenticate_User(p_User_Name,p_Password);----,nvl(p_client_id,1));

        IF    (v_Result = True)  
        THEN  
----    Redirect to Page 1 (Home Page).
              Wwv_Flow_Custom_Auth_Std.Post_Login
              (  P_UNAME       => p_User_Name,       -- p_User_Name       
                 P_PASSWORD    => p_Password,        -- p_Password
                 P_SESSION_ID  => v('APP_SESSION'),  -- p_Session_Id
                 P_FLOW_PAGE   => v_app||v_page     -- p_Flow_page
              );
              Apex_Util.Set_Session_State('LOGIN_MESSAGE','Authentication Successful for - Client ID'||p_client_id || ' User - ' || p_user_name);
        ELSE
----    Login Failure, redirect to page 101 (Login Page).
              Owa_Util.Redirect_Url('f?p='||p_App_Id||':LOGIN');
        END   IF;
EXCEPTION 
WHEN            others 
THEN 
----               We don't know what happened so log an unknown internal error and save the sql message to the authentication status
                APEX_UTIL.SET_AUTHENTICATION_RESULT(7);
                Apex_Util.Set_Session_State('LOGIN_MESSAGE','Error - Unknown Internal Error - Client ID'||p_client_id);
                APEX_UTIL.SET_CUSTOM_AUTH_STATUS(sqlerrm);
END     CMN_UTILS_Process_Login;
----------------------------------------------------------------------------------------------------------------------------------------------
