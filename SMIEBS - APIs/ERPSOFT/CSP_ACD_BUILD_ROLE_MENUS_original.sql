CREATE OR REPLACE
PROCEDURE CSP_ACD_BUILD_ROLE_MENUS_API
                    (  RETURN_CODE        OUT   VARCHAR2,
                       RETURN_MESSAGE     OUT   VARCHAR2,
                       p_user_id           IN   NUMBER,
                       p_client_id         IN   NUMBER,
                       p_role_id           IN   NUMBER
                    )
AS

----    Declare Variables and Cursors required for generation
        err_message       varchar2(200) :=  null;
        exists_flag       varchar2(01)  :=  null;
        recs_added        number        :=  0;
        v_role_menu_id    number        :=  null;

        CURSOR  get_roles IS
                Select    crm.client_id                                 client_id,
                          crm.role_id                                   role_id,
                          crm.role_code                                 role_code,
                          crm.role_name                                 role_name
                from      cmn_role_master                               crm
                where     1                                           = 1
                and       crm.role_id                                 = nvl(p_role_id,crm.role_id)
                and       crm.client_id                               = p_client_id;

BEGIN
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Started');
        DBMS_OUTPUT.put_line ('Execution Started');
        RETURN_CODE    :=  0;
        RETURN_MESSAGE :=  ' ';

        for   set_menu in  get_roles
        loop
---              v_role_menu_id   :=  v_role_menu_id + 1;
              BEGIN
                                    insert  into  cmn_role_menu_master
                                    (       creation_date,
                                            created_by,
                                            last_update_date,
                                            last_updated_by,
                                            start_date,
                                            end_date,
                                            status_id,
                                            status_date,
                                            role_menu_id,
                                            role_menu_name,
                                            description,
                                            client_id,
                                            role_id,
                                            menu_header_id,
                                            menu_line_id,
                                            access_YN
                                    )
                                    select  sysdate,
                                            0,
                                            sysdate,
                                            0,
                                            sysdate,
                                            null,
                                            10012,
                                            sysdate,
                                            rownum,
                                            set_menu.role_code||' - '||cml.menu_line_name,
                                            initcap(set_menu.role_code||' - '||cml.menu_line_name),
                                            set_menu.client_id,
                                            set_menu.role_id,
                                            cml.menu_header_id,
                                            cml.menu_line_id,
                                            'Y'
                                    from    cmn_menu_lines                  cml
                                    where   1                             = 1
                                    and     not exists
                                            ( select  'c'
                                              from    cmn_role_menu_master  crmm
                                              where   1                   = 1
                                              and     crmm.menu_line_id   = cml.menu_line_id
                                              and     crmm.menu_header_id = cml.menu_header_id
                                              and     crmm.role_id        = set_menu.role_id
                                              and     crmm.client_id      = set_menu.client_id
                                            )
                                    and     cml.menu_line_id              > 0
                                    and     cml.client_id                 = p_client_id
                                    order   by  cml.menu_line_id;
                            commit;
              EXCEPTION      
              WHEN          OTHERS
              THEN          RETURN_CODE     :=  2;
                            RETURN_MESSAGE  :=  'Some Error In Defining the Role Menus '||v_role_menu_id||' - '||SQLERRM;
                            RETURN;
              END;
              commit;     
        end  loop;

        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Role Menus Created : '||recs_added);
        DBMS_OUTPUT.put_line ('Role Menus Created : '||recs_added);
        Apex_Util.Set_Session_State('RETURN_MESSAGE' ,'Execution Sucessful');
        DBMS_OUTPUT.put_line ('Execution Successful');

        RETURN_CODE    :=  0;
        RETURN_MESSAGE :=  'Role Menus Building Successful Execution, Records Created = '||recs_added;
        RETURN;
EXCEPTION
    WHEN        OTHERS
    THEN        DBMS_OUTPUT.put_line (RETURN_MESSAGE || ' - ' || SQLERRM);
                Apex_Util.Set_Session_State('RETURN_MESSAGE' ,RETURN_MESSAGE || ' - ' || SQLERRM);
                APEX_ERROR.add_error ( p_error_code       => RETURN_MESSAGE || ' - ' || SQLERRM,
                                      p0                 => null,
                                      p_display_location => apex_error.c_inline_with_field_and_notif,
                                      p_page_item_name   => null 
                                    );
                RETURN_CODE    :=  2;
                RETURN_MESSAGE :=  RETURN_MESSAGE || ' - ' || SQLERRM;
                RETURN;
END  CSP_ACD_Build_Role_Menus_API;   ----  Automatic Population of Role Menus
--------------------------------------------------------------------------------------------------------------------------------------------------
