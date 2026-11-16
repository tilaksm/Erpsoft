--------------------------------------------------------------------------------------------------------------------------------------------------
----      API to Reverse Accounting
----      written by    : shriniwas tilak.
-----     date written  : 28th December 2025
-----     modified v1   : 
-----     v1 modified on: 
---------------------------------------------------------------------------------------------------------------------------------
create or replace PROCEDURE FINS_REVERSE_ACCOUNTING 
              ( p_return_code                 out varchar2,
                p_return_message              out varchar2,
                p_place_lattitude             in  varchar2      default '18.49926036387643',
                p_place_longitude             in  varchar2      default '73.8567922912605',
                p_place_ip_address            in  varchar2      default '58.84.61.64',
                p_user_id                     in  varchar2      default 0,
                p_client_id                   in  number,
                p_feed_trx_application_id     in  number,
                p_feed_trx_document_type_id   in  number,
                p_feed_trx_document_id        in  number
              )
    is
----    This API (Process) of Reversing the accounting of the transactions, goes through following activities -
----    1.  Reversing the period_balance and year_balance in fins_accouning _balances table affecting the accounts
----        in the mentioned transaction.
----    2.  Reversing the period_balance and year_balance in fins_party_accounting_balances table for the given party.
----    3.  Reversing the period_balance and year_balance in fins_item_accounting_balances table for the given item.
----    4.  Initializing the base records and marking them eligible for re accounting.
----    5.  Changing the status of the base records.
----    6.  Updating the records from fins_gl_jv_lines and fins_gl_jv_headers table to the status of cancelled.
----    7.  Call Action History API and register the action history for Reversal of Accounting.
----    8.  Call Notification Registration API to send the Notifications.

----    declare variables and cursors required for generation
        err_message                         varchar2(200)     :=  null;
        exists_flag                         varchar2(01)      :=  null;
        dummy_flag                          varchar2(01)      :=  null;
        v_return_code                       varchar2(01)      :=  null;
        v_return_message                    varchar2(4000)    :=  null;

        v_fiscal_year                       varchar2(10)      :=  null;
        v_current_fiscal_year               varchar2(10)      :=  null;
        v_previous_fiscal_year              varchar2(10)      :=  null;
        v_next_fiscal_year                  varchar2(10)      :=  null;
        v_current_period_id                 number            :=  null;
        v_from_period_id                    number            :=  null;
        v_gl_sl_link_table                  varchar2(100)     :=  null;
        v_user_name                         varchar2(100)     :=  null;
        v_action_id                         number            :=  null;
        v_organization_id                   number            :=  null;
        v_lob_id                            number            :=  null;
        v_profit_centre_id                  number            :=  null;
        v_jv_header_id                      number            :=  null;
        v_jv_category_id                    number            :=  null;
        v_jv_sub_category_id                number            :=  null;
        v_posted_date                       date              :=  null;
        v_user_party_id                     number            :=  null;

        v_from_account_balance_id           varchar2(40)      :=  null;
        v_to_account_balance_id             varchar2(40)      :=  null;
        v_posting_id                        number            :=  null;

        some_error                          exception;

        CURSOR  get_gl_balances  
        IS  
                SELECT  fgjl.client_id                    client_id,
                        fgjl.feed_trx_application_id      feed_trx_application_id,
                        fgjl.feed_trx_document_type_id    feed_trx_document_type_id,
                        fgjl.feed_trx_document_id         feed_trx_document_id,
                        fgjl.code_combination_id          code_combination_id,
                        fgjl.jv_line_id                   jv_line_id,
                        fgjl.jv_header_id                 jv_header_id,
                        fgjl.period_id                    period_id,
                        fgjl.accounted_dr                 accounted_dr,
                        fgjl.accounted_cr                 accounted_cr,
                        fgjl.TR_accounted_dr              TR_accounted_dr,
                        fgjl.TR_accounted_cr              TR_accounted_cr,
                        fgjl.AR_accounted_dr              AR_accounted_dr,
                        fgjl.AR_accounted_cr              AR_accounted_cr,
                        fgjl.SR_accounted_dr              SR_accounted_dr,
                        fgjl.SR_accounted_cr              SR_accounted_cr,
                        fgjl.party_combination_id         party_combination_id,
                        fgjl.party_id                     party_id,
                        fgjl.inventory_item_id            inventory_item_id,
                        fgjl.profit_centre_id             profit_centre_id,
                        fgjl.lob_id                       lob_id,
                        fgjl.organization_id              organization_id
                FROM    fins_gl_jv_lines            fgjl
                WHERE   1                         = 1
                AND     feed_trx_application_id   = p_feed_trx_application_id
                AND     feed_trx_document_type_id = p_feed_trx_document_type_id
                AND     feed_trx_document_id      = p_feed_trx_document_id
                AND     client_id                 = p_client_id;

        CURSOR  get_party_balances  
        IS  
                SELECT  fgjl.client_id                    client_id,
                        fgjl.feed_trx_application_id      feed_trx_application_id,
                        fgjl.feed_trx_document_type_id    feed_trx_document_type_id,
                        fgjl.feed_trx_document_id         feed_trx_document_id,
                        fgjl.code_combination_id          code_combination_id,
                        fgjl.jv_line_id                   jv_line_id,
                        fgjl.jv_header_id                 jv_header_id,
                        fgjl.period_id                    period_id,
                        fgjl.accounted_dr                 accounted_dr,
                        fgjl.accounted_cr                 accounted_cr,
                        fgjl.TR_accounted_dr              TR_accounted_dr,
                        fgjl.TR_accounted_cr              TR_accounted_cr,
                        fgjl.AR_accounted_dr              AR_accounted_dr,
                        fgjl.AR_accounted_cr              AR_accounted_cr,
                        fgjl.SR_accounted_dr              SR_accounted_dr,
                        fgjl.SR_accounted_cr              SR_accounted_cr,
                        fgjl.party_combination_id         party_combination_id,
                        fgjl.party_id                     party_id,
                        fgjl.inventory_item_id            inventory_item_id,
                        fgjl.profit_centre_id             profit_centre_id,
                        fgjl.lob_id                       lob_id,
                        fgjl.organization_id              organization_id
                FROM    fins_gl_jv_lines            fgjl
                WHERE   1                                       = 1
                AND     fgjl.status_id                    not in (10006,10007)
                AND     exists
                        ( select  'Y'
                          from    cmn_account_code_combinations_v cc
                          where   1                           = 1
                          and     ( cc.account_type_code      = '03-ASSETS-ST(CA)-03-TRADE-RECEIVABLES'
                                    or
                                    cc.account_type_code      = '02-ST-LIABILITY-CL-02-TRADE-PAYABLES'
                                    or
                                    cc.account_code          in (200461,200481)
                                  )
                          and     cc.code_combination_id      = fgjl.code_combination_id
                          and     cc.profit_centre_id         = fgjl.profit_centre_id
                          and     cc.lob_id                   = fgjl.lob_id
                          and     cc.organization_id          = fgjl.organization_id
                          and     cc.client_id                = fgjl.client_id
                        )
                AND     exists
                        ( select  'c'
                        from    cmn_sub_category_master     ccm,
                                fins_gl_jv_headers          fgjh
                        where   1                         = 1
                        and     ltrim(rtrim(ccm.sub_category_code))    in ('RECEIVABLES','PAYABLES','MANUAL')
                        and     ccm.sub_category_id       = fgjh.jv_source_code_id
                        and     ccm.category_id           = fgjh.jv_source_set_id
                        and     ccm.client_id             = fgjl.client_id
                        and     fgjh.jv_header_id         = fgjl.jv_header_id
                        and     fgjh.client_id            = fgjl.client_id
                        )
                AND     fgjl.party_id                          is not null
                AND     fgjl.party_combination_id              is not null
                AND     feed_trx_application_id   = p_feed_trx_application_id
                AND     feed_trx_document_type_id = p_feed_trx_document_type_id
                AND     feed_trx_document_id      = p_feed_trx_document_id
                AND     client_id                 = p_client_id;

        CURSOR  get_item_balances  
        IS  
                SELECT  fgjl.client_id                    client_id,
                        fgjl.feed_trx_application_id      feed_trx_application_id,
                        fgjl.feed_trx_document_type_id    feed_trx_document_type_id,
                        fgjl.feed_trx_document_id         feed_trx_document_id,
                        fgjl.code_combination_id          code_combination_id,
                        fgjl.jv_line_id                   jv_line_id,
                        fgjl.jv_header_id                 jv_header_id,
                        fgjl.period_id                    period_id,
                        fgjl.quantity_dr                  quantity_dr,
                        fgjl.quantity_cr                  quantity_cr,
                        fgjl.accounted_dr                 accounted_dr,
                        fgjl.accounted_cr                 accounted_cr,
                        fgjl.TR_accounted_dr              TR_accounted_dr,
                        fgjl.TR_accounted_cr              TR_accounted_cr,
                        fgjl.AR_accounted_dr              AR_accounted_dr,
                        fgjl.AR_accounted_cr              AR_accounted_cr,
                        fgjl.SR_accounted_dr              SR_accounted_dr,
                        fgjl.SR_accounted_cr              SR_accounted_cr,
                        fgjl.party_combination_id         party_combination_id,
                        fgjl.party_id                     party_id,
                        fgjl.inventory_item_id            inventory_item_id,
                        fgjl.profit_centre_id             profit_centre_id,
                        fgjl.lob_id                       lob_id,
                        fgjl.organization_id              organization_id
                FROM    fins_gl_jv_lines                  fgjl
                WHERE   1                                = 1
                AND     fgjl.status_id                   not in (10006,10007)
                AND     exists
                        ( select  'Y'
                          from    cmn_account_code_combinations_v cc
                          where   1                           = 1
                          and     cc.account_type_code        = '03-ASSETS-ST(CA)-02-INVENTORIES-STOCKS'
                          and     cc.code_combination_id      = fgjl.code_combination_id
                          and     cc.profit_centre_id         = fgjl.profit_centre_id
                          and     cc.lob_id                   = fgjl.lob_id
                          and     cc.organization_id          = fgjl.organization_id
                          and     cc.client_id                = fgjl.client_id
                        )
                AND     fgjl.inventory_item_id               is not null
                AND     feed_trx_application_id   = p_feed_trx_application_id
                AND     feed_trx_document_type_id = p_feed_trx_document_type_id
                AND     feed_trx_document_id      = p_feed_trx_document_id
                AND     client_id                 = p_client_id;

----          Main Process of Accounting Reversalstarts here.
begin
              p_return_code     :=  0;
              p_return_message  :=  'Accounting Reversal Started';

              dbms_output.put_line (p_return_code||' - '||p_return_message);

---           Find out the from period_id and current_period_id
              begin
                        select  period_id,
                                upper(trim(gl_sl_link_table)),
                                organization_id,
                                lob_id,
                                profit_centre_id,
                                jv_header_id,
                                posted_date,
                                jv_category_id,
                                jv_sub_category_id
                        into    v_from_period_id,
                                v_gl_sl_link_table,
                                v_organization_id,
                                v_lob_id,
                                v_profit_centre_id,
                                v_jv_header_id,
                                v_posted_date,
                                v_jv_category_id,
                                v_jv_sub_category_id
                        from    fins_gl_jv_headers  
                        where   1                           = 1
                        and     feed_trx_application_id     = p_feed_trx_application_id
                        and     feed_trx_document_type_id   = p_feed_trx_document_type_id
                        and     feed_trx_document_id        = p_feed_trx_document_id
                        and     client_id                   = p_client_id;
              exception
              when      no_data_found
              then      v_from_period_id  :=  null;
              when      others
              then      v_from_period_id  :=  null;
              end;

              begin
                        select  to_char(sysdate,'YYYYMM')
                        into    v_current_period_id
                        from    dual;
              exception
              when      no_data_found
              then      v_current_period_id  :=  null;
              when      others
              then      v_current_period_id  :=  null;
              end;

              begin
                        select  cpm.party_name,
                                cpm.party_id
                        into    v_user_name,
                                v_user_party_id
                        from    cmn_party_master  cpm,
                                cmn_user_master   cum
                        where   1               = 1
                        and     cpm.party_id    = cum.party_id
                        and     cpm.client_id   = cum.client_id
                        and     cum.user_id     = p_user_id
                        and     cum.client_id   = p_client_id;
              exception
              when      no_data_found
              then      v_user_name  :=  null;
              when      others
              then      v_user_name  :=  null;
              end;

----          Reset the Accounting Balances from the document period till date period
              for       set_gl_balances  in  get_gl_balances
              loop
----                    First reset accounting balances
                        begin
                                    update  /*+ PARALLEL (fins_accounting_balances, 4) */
                                            fins_accounting_balances      fab
                                    set     period_begin_balance_dr     = nvl(period_begin_balance_dr,0)          - 
                                                                          nvl(set_gl_balances.accounted_dr,0),
                                            period_begin_balance_cr     = nvl(period_begin_balance_cr,0)          -
                                                                          nvl(set_gl_balances.accounted_cr,0),
                                            TR_period_begin_balance_dr  = nvl(TR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_gl_balances.TR_accounted_dr,0),
                                            TR_period_begin_balance_cr  = nvl(TR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_gl_balances.TR_accounted_cr,0),
                                            AR_period_begin_balance_dr  = nvl(AR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_gl_balances.AR_accounted_dr,0),
                                            AR_period_begin_balance_cr  = nvl(AR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_gl_balances.AR_accounted_cr,0),
                                            SR_period_begin_balance_dr  = nvl(SR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_gl_balances.SR_accounted_dr,0),
                                            SR_period_begin_balance_cr  = nvl(SR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_gl_balances.SR_accounted_cr,0),
                                            year_begin_balance_dr       = nvl(year_begin_balance_dr,0)            - 
                                                                          nvl(set_gl_balances.accounted_dr,0),
                                            year_begin_balance_cr       = nvl(year_begin_balance_cr,0)            - 
                                                                          nvl(set_gl_balances.accounted_cr,0),
                                            TR_year_begin_balance_dr    = nvl(TR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_gl_balances.TR_accounted_dr,0),
                                            TR_year_begin_balance_cr    = nvl(TR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_gl_balances.TR_accounted_cr,0),
                                            AR_year_begin_balance_dr    = nvl(AR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_gl_balances.AR_accounted_dr,0),
                                            AR_year_begin_balance_cr    = nvl(AR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_gl_balances.AR_accounted_cr,0),
                                            SR_year_begin_balance_dr    = nvl(SR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_gl_balances.SR_accounted_dr,0),
                                            SR_year_begin_balance_cr    = nvl(SR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_gl_balances.SR_accounted_cr,0),
                                            period_net_dr               = nvl(period_net_dr,0)     - nvl(set_gl_balances.accounted_dr,0),
                                            period_net_cr               = nvl(period_net_cr,0)     - nvl(set_gl_balances.accounted_cr,0),
                                            TR_period_net_dr            = nvl(TR_period_net_dr,0)  - nvl(set_gl_balances.TR_accounted_dr,0),
                                            TR_period_net_cr            = nvl(TR_period_net_cr,0)  - nvl(set_gl_balances.TR_accounted_cr,0),
                                            AR_period_net_dr            = nvl(AR_period_net_dr,0)  - nvl(set_gl_balances.AR_accounted_dr,0),
                                            AR_period_net_cr            = nvl(AR_period_net_cr,0)  - nvl(set_gl_balances.AR_accounted_cr,0),
                                            SR_period_net_dr            = nvl(SR_period_net_dr,0)  - nvl(set_gl_balances.SR_accounted_dr,0),
                                            SR_period_net_cr            = nvl(SR_period_net_cr,0)  - nvl(set_gl_balances.SR_accounted_cr,0),
                                            place_lattitude             = p_place_lattitude,
                                            place_longitude             = p_place_longitude,
                                            place_ip_address            = p_place_ip_address,
                                            last_update_date            = sysdate,
                                            last_updated_by             = p_user_id
                                    where   1                           = 1
                                    and     fab.period_id              >= v_from_period_id
                                    and     fab.period_id              <= v_current_period_id
                                    and     fab.code_combination_id     = set_gl_balances.code_combination_id
                                    and     fab.client_id               = set_gl_balances.client_id;
                        exception 
                        when        others
                        then        p_return_message  :=  p_return_message  ||  ' GL Balances Can not be Reset for the Transaction ';
                                    dbms_output.put_line (p_return_message);
                                    raise some_error;
                                    rollback;
                        end;
                        commit;
              end       loop;
              p_return_message  :=  p_return_message  ||  ' GL Balances Reset for the Transaction ';
              dbms_output.put_line (p_return_message);
              commit;

----          Reset Fins_party_accounting_balances              

              for       set_party_balances  in  get_party_balances
              loop
----                    First reset accounting balances
                        begin
                                    update  /*+ PARALLEL (fins_party_accounting_balances, 4) */
                                            fins_party_accounting_balances      fab
                                    set     period_begin_balance_dr     = nvl(period_begin_balance_dr,0)          - 
                                                                          nvl(set_party_balances.accounted_dr,0),
                                            period_begin_balance_cr     = nvl(period_begin_balance_cr,0)          -
                                                                          nvl(set_party_balances.accounted_cr,0),
                                            TR_period_begin_balance_dr  = nvl(TR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_party_balances.TR_accounted_dr,0),
                                            TR_period_begin_balance_cr  = nvl(TR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_party_balances.TR_accounted_cr,0),
                                            AR_period_begin_balance_dr  = nvl(AR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_party_balances.AR_accounted_dr,0),
                                            AR_period_begin_balance_cr  = nvl(AR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_party_balances.AR_accounted_cr,0),
                                            SR_period_begin_balance_dr  = nvl(SR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_party_balances.SR_accounted_dr,0),
                                            SR_period_begin_balance_cr  = nvl(SR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_party_balances.SR_accounted_cr,0),
                                            year_begin_balance_dr       = nvl(year_begin_balance_dr,0)            - 
                                                                          nvl(set_party_balances.accounted_dr,0),
                                            year_begin_balance_cr       = nvl(year_begin_balance_cr,0)            - 
                                                                          nvl(set_party_balances.accounted_cr,0),
                                            TR_year_begin_balance_dr    = nvl(TR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_party_balances.TR_accounted_dr,0),
                                            TR_year_begin_balance_cr    = nvl(TR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_party_balances.TR_accounted_cr,0),
                                            AR_year_begin_balance_dr    = nvl(AR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_party_balances.AR_accounted_dr,0),
                                            AR_year_begin_balance_cr    = nvl(AR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_party_balances.AR_accounted_cr,0),
                                            SR_year_begin_balance_dr    = nvl(SR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_party_balances.SR_accounted_dr,0),
                                            SR_year_begin_balance_cr    = nvl(SR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_party_balances.SR_accounted_cr,0),
                                            period_net_dr               = nvl(period_net_dr,0)     - nvl(set_party_balances.accounted_dr,0),
                                            period_net_cr               = nvl(period_net_cr,0)     - nvl(set_party_balances.accounted_cr,0),
                                            TR_period_net_dr            = nvl(TR_period_net_dr,0)  - nvl(set_party_balances.TR_accounted_dr,0),
                                            TR_period_net_cr            = nvl(TR_period_net_cr,0)  - nvl(set_party_balances.TR_accounted_cr,0),
                                            AR_period_net_dr            = nvl(AR_period_net_dr,0)  - nvl(set_party_balances.AR_accounted_dr,0),
                                            AR_period_net_cr            = nvl(AR_period_net_cr,0)  - nvl(set_party_balances.AR_accounted_cr,0),
                                            SR_period_net_dr            = nvl(SR_period_net_dr,0)  - nvl(set_party_balances.SR_accounted_dr,0),
                                            SR_period_net_cr            = nvl(SR_period_net_cr,0)  - nvl(set_party_balances.SR_accounted_cr,0),
                                            place_lattitude             = p_place_lattitude,
                                            place_longitude             = p_place_longitude,
                                            place_ip_address            = p_place_ip_address,
                                            last_update_date            = sysdate,
                                            last_updated_by             = p_user_id
                                    where   1                           = 1
                                    and     fab.period_id              >= v_from_period_id
                                    and     fab.period_id              <= v_current_period_id
                                    and     fab.party_combination_id    = set_party_balances.party_combination_id
                                    and     fab.party_id                = set_party_balances.party_id
                                    and     fab.client_id               = set_party_balances.client_id;
                        exception 
                        when        others
                         then        p_return_message  :=  p_return_message  ||  ' Party Balances Can not be Reset for the Transaction ';
                                    dbms_output.put_line (p_return_message);
                                    raise some_error;
                                    rollback;
                       end;
                        commit;
              end       loop;
              p_return_message  :=  p_return_message  ||  ' Party  Balances Reset for the Transaction ';
              dbms_output.put_line (p_return_message);
              commit;

----          Reset Item accounting balances
              for       set_item_balances  in  get_item_balances
              loop
----                    First reset accounting balances
                        begin
                                    update  /*+ PARALLEL (fins_item_accounting_balances, 4) */
                                            fins_item_accounting_balances      fab
                                    set     period_begin_balance_dr     = nvl(period_begin_balance_dr,0)          - 
                                                                          nvl(set_item_balances.accounted_dr,0),
                                            period_begin_balance_cr     = nvl(period_begin_balance_cr,0)          -
                                                                          nvl(set_item_balances.accounted_cr,0),
                                            TR_period_begin_balance_dr  = nvl(TR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_item_balances.TR_accounted_dr,0),
                                            TR_period_begin_balance_cr  = nvl(TR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_item_balances.TR_accounted_cr,0),
                                            AR_period_begin_balance_dr  = nvl(AR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_item_balances.AR_accounted_dr,0),
                                            AR_period_begin_balance_cr  = nvl(AR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_item_balances.AR_accounted_cr,0),
                                            SR_period_begin_balance_dr  = nvl(SR_period_begin_balance_dr,0)       - 
                                                                          nvl(set_item_balances.SR_accounted_dr,0),
                                            SR_period_begin_balance_cr  = nvl(SR_period_begin_balance_cr,0)       - 
                                                                          nvl(set_item_balances.SR_accounted_cr,0),
                                            year_begin_balance_dr       = nvl(year_begin_balance_dr,0)            - 
                                                                          nvl(set_item_balances.accounted_dr,0),
                                            year_begin_balance_cr       = nvl(year_begin_balance_cr,0)            - 
                                                                          nvl(set_item_balances.accounted_cr,0),
                                            TR_year_begin_balance_dr    = nvl(TR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_item_balances.TR_accounted_dr,0),
                                            TR_year_begin_balance_cr    = nvl(TR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_item_balances.TR_accounted_cr,0),
                                            AR_year_begin_balance_dr    = nvl(AR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_item_balances.AR_accounted_dr,0),
                                            AR_year_begin_balance_cr    = nvl(AR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_item_balances.AR_accounted_cr,0),
                                            SR_year_begin_balance_dr    = nvl(SR_year_begin_balance_dr,0)         - 
                                                                          nvl(set_item_balances.SR_accounted_dr,0),
                                            SR_year_begin_balance_cr    = nvl(SR_year_begin_balance_cr,0)         - 
                                                                          nvl(set_item_balances.SR_accounted_cr,0),
                                            period_net_dr               = nvl(period_net_dr,0)     - nvl(set_item_balances.accounted_dr,0),
                                            period_net_cr               = nvl(period_net_cr,0)     - nvl(set_item_balances.accounted_cr,0),
                                            TR_period_net_dr            = nvl(TR_period_net_dr,0)  - nvl(set_item_balances.TR_accounted_dr,0),
                                            TR_period_net_cr            = nvl(TR_period_net_cr,0)  - nvl(set_item_balances.TR_accounted_cr,0),
                                            AR_period_net_dr            = nvl(AR_period_net_dr,0)  - nvl(set_item_balances.AR_accounted_dr,0),
                                            AR_period_net_cr            = nvl(AR_period_net_cr,0)  - nvl(set_item_balances.AR_accounted_cr,0),
                                            SR_period_net_dr            = nvl(SR_period_net_dr,0)  - nvl(set_item_balances.SR_accounted_dr,0),
                                            SR_period_net_cr            = nvl(SR_period_net_cr,0)  - nvl(set_item_balances.SR_accounted_cr,0),
                                            place_lattitude             = p_place_lattitude,
                                            place_longitude             = p_place_longitude,
                                            place_ip_address            = p_place_ip_address,
                                            last_update_date            = sysdate,
                                            last_updated_by             = p_user_id
                                    where   1                           = 1
                                    and     fab.period_id              >= v_from_period_id
                                    and     fab.period_id              <= v_current_period_id
                                    and     fab.inventory_item_id       = set_item_balances.inventory_item_id
                                    and     fab.client_id               = set_item_balances.client_id;
                        exception 
                        when        others
                        then        p_return_message  :=  p_return_message  ||  ' ITEM Balances Can not be Reset for the Transaction ';
                                    dbms_output.put_line (p_return_message);
                                    raise some_error;
                                    rollback;
                        end;
                        commit;
              end       loop;

              p_return_message  :=  p_return_message  ||  ' Inventory Item  Balances Reset for the Transaction ';
              dbms_output.put_line (p_return_message);
              commit;

----          Initializing the Base Records for Payables
              begin
                        update  fins_ap_transactions                fat
                        set     fat.sla_accounting_date           = null,
                                fat.sla_accounting_flag           = 'N',
                                fat.sla_header_id                 = null,
                                fat.sla_jv_name                   = null,
                                fat.eligible_to_accounting        = 'N',
                                fat.status_id                     = 10002,
                                fat.status_date                   = sysdate, 
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.application_id                = p_feed_trx_application_id
                        and     fat.ap_trx_type_id                = p_feed_trx_document_type_id
                        and     fat.ap_trx_id                     = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ap_transactions Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

              begin
                        update  fins_ap_transaction_lines           fatl
                        set     fatl.sla_accounting_date          = null,
                                fatl.sla_accounting_flag          = 'N',
                                fatl.sla_header_id                = null,
                                fatl.sla_jv_name                  = null,
                                fatl.eligible_to_accounting       = 'N',
                                fatl.status_id                    = 10002,
                                fatl.status_date                  = sysdate, 
                                fatl.last_update_date             = sysdate,
                                fatl.last_updated_by              = p_user_id
                        where   1                                 = 1
                        and     exists
                                ( select  'c'
                                  from    fins_ap_transactions      fat
                                  where   1                       = 1
                                  and     fat.ap_trx_type_id      = p_feed_trx_document_type_id
                                  and     fat.ap_trx_id           = fatl.ap_trx_id
                                  and     fat.client_id           = fatl.client_id
                                )
                        and     fatl.application_id               = p_feed_trx_application_id
                        and     fatl.ap_trx_id                    = p_feed_trx_document_id
                        and     fatl.client_id                    = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ap_transaction_lines Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

              begin
                        update  fins_ap_payments                    fat
                        set     fat.sla_accounting_date           = null,
                                fat.sla_accounting_flag           = 'N',
                                fat.sla_header_id                 = null,
                                fat.sla_jv_name                   = null,
                                fat.eligible_to_accounting        = 'N',
                                fat.status_id                     = 10002,
                                fat.status_date                   = sysdate, 
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.application_id                = p_feed_trx_application_id
                        and     fat.transaction_type_id           = p_feed_trx_document_type_id
                        and     fat.check_id                      = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ap_Payments Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

              begin
                        update  fins_ap_transaction_payments        fat
                        set     fat.sla_accounting_date           = null,
                                fat.sla_accounting_flag           = 'N',
                                fat.sla_header_id                 = null,
                                fat.sla_jv_name                   = null,
                                fat.eligible_to_accounting        = 'N',
                                fat.status_id                     = 10002,
                                fat.status_date                   = sysdate, 
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.application_id                = p_feed_trx_application_id
                        and     fat.transaction_type_id           = p_feed_trx_document_type_id
                        and     fat.transaction_payment_id        = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ap_transaction_payments Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

----          Initializing the Base Records for Receivables
              begin
                        update  fins_ar_transactions                fat
                        set     fat.sla_accounting_flag           = 'N',
                                fat.sla_header_id                 = null,
                                fat.sla_jv_name                   = null,
                                fat.eligible_to_accounting        = 'N',
                                fat.status_id                     = 10002,
                                fat.status_date                   = sysdate,
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.application_id                = p_feed_trx_application_id
                        and     fat.ar_trx_type_id                = p_feed_trx_document_type_id
                        and     fat.ar_trx_id                     = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ar_transactions Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

              begin
                        update  fins_ar_transaction_lines           fatl
                        set     fatl.sla_accounting_date          = null,
                                fatl.sla_accounting_flag          = 'N',
                                fatl.sla_header_id                = null,
                                fatl.sla_line_id                  = null,
                                fatl.sla_line_number              = null,
                                fatl.eligible_to_accounting       = 'N',
                                fatl.status_id                    = 10002,
                                fatl.status_date                  = sysdate,
                                fatl.last_update_date             = sysdate,
                                fatl.last_updated_by              = p_user_id
                        where   1                                 = 1
                        and     exists
                                ( select  'c'
                                  from    fins_ar_transactions      fat
                                  where   1                       = 1
                                  and     fat.ar_trx_type_id      = p_feed_trx_document_type_id
                                  and     fat.ar_trx_id           = fatl.ar_trx_id
                                  and     fat.client_id           = fatl.client_id
                                )
                        and     fatl.application_id               = p_feed_trx_application_id
                        and     fatl.ar_trx_id                    = p_feed_trx_document_id
                        and     fatl.client_id                    = p_client_id;
                        commit; 
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ar_transaction_lines Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

              begin
                        update  fins_ar_applications                fat
                        set     fat.sla_accounting_flag           = 'N',
                                fat.sla_header_id                 = null,
                                fat.sla_jv_name                   = null,
                                fat.eligible_to_accounting        = 'N',
                                fat.status_id                     = 10002,
                                fat.status_date                   = sysdate, 
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.application_id                = p_feed_trx_application_id
                        and     fat.transaction_type_id           = p_feed_trx_document_type_id
                        and     fat.RECEIVABLE_APLICATION_ID      = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ar_applications Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

              begin
                        update  fins_ar_money_receipts              fat
                        set     fat.sla_accounting_date           = null,
                                fat.sla_accounting_flag           = 'N',
                                fat.sla_header_id                 = null,
                                fat.sla_jv_name                   = null,
                                fat.eligible_to_accounting        = 'N',
                                fat.status_id                     = 10002,
                                fat.status_date                   = sysdate, 
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.application_id                = p_feed_trx_application_id
                        and     fat.transaction_type_id           = p_feed_trx_document_type_id
                        and     fat.ar_receipt_id                 = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_ar_money_receipts Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

----          Initializing the Base Records for Material Receipts
              begin
                        update  imr_receipt_headers                 fat
                        set     fat.receipt_accounted_flag        = null,
                                fat.receipt_accounting_date       = null,
                                fat.receipt_accounting_event_id   = null,
                                fat.receipt_accounting_header_id  = null,
                                fat.receipt_accounting_line_id    = null,
                                fat.receipt_eligible_to_accounting= 'N',
                                fat.delivery_accounted_flag       = null,
                                fat.delivery_accounting_date      = null,
                                fat.delivery_accounting_event_id  = null,
                                fat.delivery_accounting_header_id = null,
                                fat.delivery_accounting_line_id   = null,
                                fat.delivery_eligible_to_accounting= 'N',
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.transaction_type_id           = p_feed_trx_document_type_id
                        and     fat.receipt_header_id             = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' imr_receipt_headers Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

              begin
                        update  imr_receipt_lines                   fat
                        set     fat.receipt_accounted_flag        = null,
                                fat.receipt_accounting_date       = null,
                                fat.receipt_accounting_event_id   = null,
                                fat.receipt_accounting_header_id  = null,
                                fat.receipt_accounting_line_id    = null,
                                fat.receipt_eligible_to_accounting= 'N',
                                fat.delivery_accounted_flag       = null,
                                fat.delivery_accounting_date      = null,
                                fat.delivery_accounting_event_id  = null,
                                fat.delivery_accounting_header_id = null,
                                fat.delivery_accounting_line_id   = null,
                                fat.delivery_eligible_to_accounting= 'N',
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.transaction_type_id           = p_feed_trx_document_type_id
                        and     fat.receipt_header_id             = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' imr_receipt_lines Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

----          Initializing the Base Records for Material Transactions
              begin
                        update  inv_material_transactions           fat
                        set     fat.accounted_flag                = 'N',
                                fat.accounted_date                = null,
                                fat.accounted_transaction_id      = null,
                                fat.eligible_to_accounting        = 'N',
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.transaction_type_id           = p_feed_trx_document_type_id
                        and     fat.inv_transaction_id            = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' inv_material_transactions Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;

----          Cancelling the Records from fins_gl_jv_lines and fins_gl_jv_headers
----          Modified by shriniwas on 7th July 2026 to Delete the records insted of marking Canceled
              begin
/*                        update  fins_gl_jv_lines                    fat
                        set     fat.attribute_01                  = 'Accounting Reversed on '||to_char(sysdate,'DD-MON-YYYY')||
                                                                    'By '||v_user_name,
                                fat.status_id                     = 10006,
                                fat.status_date                   = sysdate,
                                fat.place_lattitude               = p_place_lattitude,
                                fat.place_longitude               = p_place_longitude,
                                fat.place_ip_address              = p_place_ip_address,
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.feed_trx_application_id       = p_feed_trx_application_id
                        and     fat.feed_trx_document_type_id     = p_feed_trx_document_type_id
                        and     fat.feed_trx_document_id          = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
*/
                        delete  fins_gl_jv_lines                    fat
                        where   1                                 = 1
                        and     fat.feed_trx_application_id       = p_feed_trx_application_id
                        and     fat.feed_trx_document_type_id     = p_feed_trx_document_type_id
                        and     fat.feed_trx_document_id          = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_gl_jv_lines Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;
              p_return_message  :=  p_return_message  ||  ' Fins_gl_jv_lines has been Reset for the Transaction ';
              dbms_output.put_line (p_return_message);

              begin
/*                        update  fins_gl_jv_headers                  fat
                        set     fat.attribute_01                  = 'Accounting Reversed on '||to_char(sysdate,'DD-MON-YYYY')||
                                                                    'By '||v_user_name,
                                fat.status_id                     = 10006,
                                fat.status_date                   = sysdate,
                                fat.place_lattitude               = p_place_lattitude,
                                fat.place_longitude               = p_place_longitude,
                                fat.place_ip_address              = p_place_ip_address,
                                fat.last_update_date              = sysdate,
                                fat.last_updated_by               = p_user_id
                        where   1                                 = 1
                        and     fat.feed_trx_application_id       = p_feed_trx_application_id
                        and     fat.feed_trx_document_type_id     = p_feed_trx_document_type_id
                        and     fat.feed_trx_document_id          = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;
*/
                        delete  fins_gl_jv_headers                  fat
                        where   1                                 = 1
                        and     fat.feed_trx_application_id       = p_feed_trx_application_id
                        and     fat.feed_trx_document_type_id     = p_feed_trx_document_type_id
                        and     fat.feed_trx_document_id          = p_feed_trx_document_id
                        and     fat.client_id                     = p_client_id;

                        commit;
              exception
              when      others
              then      p_return_message  :=  p_return_message  ||  ' fins_gl_jv_headers Can not be Reset for the Transaction ';
                        dbms_output.put_line (p_return_message);
                        raise some_error;
                        rollback;
              end;
              p_return_message  :=  p_return_message  ||  ' Fins_gl_jv_headers has been Reset for the Transaction ';
              dbms_output.put_line (p_return_message);

----          Register action History for Reversal of Accounting
/*
              cmn_maintain_action_history_api
              (       p_return_code                       =>  v_return_code,
                      p_return_message                    =>  v_return_message,
                      p_action                            =>  'I',
                      p_user_id                           =>  p_user_id,
                      p_start_date                        =>  sysdate,
                      p_end_date                          =>  null,
                      p_place_lattitude                   =>  p_place_lattitude,
                      p_place_longitude                   =>  p_place_longitude,
                      p_place_ip_address                  =>  p_place_ip_address,
                      p_transaction_application_id        =>  302,
                      p_transaction_type_id               =>  30202,
                      p_action_id                         =>  v_action_id,
                      p_client_id                         =>  p_client_id,
                      p_application_id                    =>  302,
                      p_organization_id                   =>  v_organization_id,
                      p_lob_id                            =>  v_lob_id,
                      p_profit_centre_id                  =>  v_profit_centre_id,
                      p_department_id                     =>  null,
                      p_region_id                         =>  null,
                      p_branch_id                         =>  null,
                      p_application_process_seq           =>  null,
                      p_source_transaction_type_id        =>  30202,
                      p_source_table_name                 =>  v_gl_sl_link_table,
                      p_source_table_pk_id                =>  'FINS_GL_JV_HEADERS',
                      p_source_document_number            =>  v_jv_header_id,
                      p_source_document_date              =>  v_posted_date,
                      p_source_document_name              =>  null,
                      p_source_document_description       =>  'Reversal of Accounting',
                      p_action_type_set_id                =>  null,
                      p_action_type_code_id               =>  null,
                      p_document_type                     =>  'ACCOUNTING_REVERSAL',
                      p_document_header_id                =>  v_jv_header_id,
                      p_document_line_id                  =>  null,
                      p_source_party_id                   =>  null,
                      p_source_party_combination_id       =>  null,
                      p_action_requested_by_party_id      =>  v_user_party_id,
                      p_action_by_party_id                =>  v_user_party_id,
                      p_action_approved_by_party_id       =>  v_user_party_id,
                      p_action_date                       =>  sysdate,
                      p_action_note                       =>  'Accounting Reversed on '||to_char(sysdate,'DD-MON-YYYY')||
                                                                    'By '||v_user_name
              );

              p_return_message  :=  ' Accounting Reversed Succefuly ';
              dbms_output.put_line (p_return_message);
              commit;
*/              
exception
when        some_error
then        dbms_output.put_line (p_return_message || ' - ' || sqlerrm);
            apex_util.set_session_state('return_message' , p_return_message || ' - ' || sqlerrm);
            apex_error.add_error ( p_error_code         => p_return_message || ' - ' || sqlerrm,
                                   p0                   => null,
                                   p_display_location   => apex_error.c_inline_with_field_and_notif,
                                   p_page_item_name     => null 
                                );
            p_return_code     :=  2;
            p_return_message  :=  p_return_message || ' - ' || sqlerrm;
            return;
end FINS_REVERSE_ACCOUNTING;
---------------------------------------------------------------------------------------------------------------------------------
