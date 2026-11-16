--------------------------------------------------------------------------------------------------------------------------------------------------
----      Systems Administrators Package 
--- -     Written by    : Shriniwas Tilak
-----     Date Written  : 25th March 2020  (Gudi Padava)
-----     Modified V1   : Shriniwas   Tilak
-----     V1 Modified on: 25th March 2020  (Gudi Padava)
--------------------------------------------------------------------------------------------------------------------------------------------------
----    Procedure to build Programs master from apex Pages
----------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE   PROCEDURE  CSP_Build_Programs_API
                    (  RETURN_CODE                    OUT   VARCHAR2,
                       RETURN_MESSAGE                 OUT   VARCHAR2,
                       p_user_id                       IN   NUMBER,
                       p_client_id                     IN   NUMBER,
                       p_workspace                     IN   VARCHAR2
                    )
        AS

----    Declare Variables and Cursors required for generation
        err_message           varchar2(200) := null;
        exists_flag           varchar2(01)  := null;
        dummy_flag            varchar2(01)  := null;
        recs_added            number        := 0;

        Some_Error            EXCEPTION;
BEGIN
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started for Building Programs Master');
        DBMS_OUTPUT.put_line ('Execution Started for Building Programs Master');

----    Start of Building Programs Master
        RETURN_CODE            := 0;                      ----  Successful Execution
        RETURN_MESSAGE         := ' '; 

----    Validate User ID
        IF    (p_user_id is null)
        THEN  RETURN_CODE     := 2;
              RETURN_MESSAGE  := RETURN_MESSAGE ||  ' - '  ||
                                   'Invalid User Name';
        END   IF;

----    Validate Workspace code
        IF    (p_workspace is null)
        THEN  RETURN_CODE     := 2;
              RETURN_MESSAGE  := RETURN_MESSAGE ||  ' - '  ||
                                   'Invalid Workspace Name';
        END   IF;

----    Validate Client ID
        exists_flag  :=  null;
        BEGIN  
              SELECT 'Y'
              INTO   exists_flag
              FROM   cmn_client_master
              WHERE  client_id     = p_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    RETURN_CODE     := 2;
                        RETURN_MESSAGE  := RETURN_MESSAGE || ' - ' ||
                                             'Invalid Client ID Passed';
                WHEN    OTHERS
                THEN    RETURN_CODE     := 2;
                        RETURN_MESSAGE  := RETURN_MESSAGE || ' - ' ||
                                             'Invalid Client ID Passed';
        END;

----    Validate User ID
        exists_flag  :=  null;
        BEGIN  
              SELECT 'Y'
              INTO   exists_flag
              FROM   cmn_user_master_v
              WHERE  user_id     = p_user_id
              AND    client_id   = p_client_id;
        EXCEPTION
                WHEN    NO_DATA_FOUND
                THEN    RETURN_CODE     := 2;
                        RETURN_MESSAGE  := RETURN_MESSAGE || ' - ' ||
                                             'Invalid User ID Passed';
                WHEN    OTHERS
                THEN    RETURN_CODE     := 2;
                        RETURN_MESSAGE  := RETURN_MESSAGE || ' - ' ||
                                             'Invalid User ID Passed';
        END;

----    Verify if thre is an error, if yes then raise exception and exit out
        IF    ( RETURN_CODE <> 0)
        THEN  raise  Some_Error;
        END   IF;

----    Build Program Master

        BEGIN
               INSERT  into cmn_Program_master 
               ( creation_date,
                 created_by,
                 last_update_date,
                 last_updated_by,
                 start_date,
                 end_date,
                 program_id,
                 program_code,
                 program_name,
                 description,
                 apex_workspace,
                 apex_application_id,
                 apex_page_id,
                 attribute_01,
                 python_program_id,
                 php_program_id,
                 other_sw_program_id
               )
               SELECT   aap.created_on,
                        0,
                        sysdate,
                        0,
                        aap.created_on,
                        null,
                        cmn_program_seq.nextval,
                        upper(aap.application_id||':'||aap.page_id ),
                        aap.application_id||' : '||aap.page_name,
                        aap.application_id||' : '||aap.page_name,
                        aap.workspace,
                        aap.application_id,
                        aap.page_id,
                        upper(aap.build_option),
                        null,
                        null,
                        null
               FROM     apex_application_pages  aap
               WHERE    1  =  1
               AND      not exists  
                        (   SELECT 'c'
                            FROM   cmn_program_master  x 
                            WHERE  upper(x.program_name)  =  upper(aap.application_id||' : '||aap.page_name)
                            AND    upper(x.program_code)  =  upper(aap.application_id||':'||aap.page_id )
                        )
----               AND      upper(build_option)  = upper('Accessible : From Menu')
               AND      upper(aap.workspace) = upper(p_workspace);
               commit;
        EXCEPTION   WHEN  OTHERS
                    THEN  RETURN_CODE     := 2;
                          RETURN_MESSAGE  := RETURN_MESSAGE ||  ' - '  ||
                                              'Unable to Build Programs Master' || SQLERRM;
                          raise  Some_Error;
                          RETURN;
        END;  

        RETURN_CODE      :=  0;
        RETURN_MESSAGE   :=  'Building Program Master is Successful';
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Successful for Bu8ilding Programs Master');
        DBMS_OUTPUT.put_line ('Execution Successful for Building Programs Master');

        RETURN;
EXCEPTION
     WHEN       Some_Error
     THEN       RETURN_CODE    :=  2;
                RETURN_MESSAGE :=  RETURN_MESSAGE || ' - ' ||
                                     'Some error Has Occurred...Existing...Unsuccessful Execution';
                RETURN; 
     WHEN       OTHERS
     THEN       DBMS_OUTPUT.put_line (RETURN_MESSAGE || ' - ' || SQLERRM);
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,RETURN_MESSAGE || ' - ' || SQLERRM);
                APEX_ERROR.add_error ( p_error_code       => RETURN_MESSAGE || ' - ' || SQLERRM,
                                       p0                 => null,
                                       p_display_location => apex_error.c_inline_with_field_and_notif,
                                       p_page_item_name   => null 
                                     );
                RETURN_CODE    :=  2;
                RETURN_MESSAGE :=  RETURN_MESSAGE ||  ' - ' || SQLERRM;
                RETURN;
END  CSP_Build_Programs_API;   ----  Procedure to Build Programs Master
-----------------------------------------------------------------------------------------------------------------------------------
