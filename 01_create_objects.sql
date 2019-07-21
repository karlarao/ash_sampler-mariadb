-- modified by Karl Arao for RDS Mariadb 10.1.23 compatibility
-- original project https://github.com/hatem-mahmoud/Ash_sampler

-- Installation: 
--   on your text editor replace mariadb2 with the username that you'll use for monitoring
-- or use sed below:
--   sed 's/mariadb2/your_username_here/g' 01_create_objects.sql.bak > 01.sql
--   sed 's/mariadb2/your_username_here/g' 02_ash_sampler.sql > 02.sql


USE mariadb2;

CREATE algorithm=temptable SQL security invoker view `mariadb2`.`aas_source` 
  (`thd_id`,`conn_id`,`user`,`db`,`command`,`state`,`time`,`current_statement`,`statement_latency`,`lock_latency`,`rows_examined`,`rows_sent`,`rows_affected`,`tmp_tables`,`tmp_disk_tables`,`full_scan`,`last_statement`,`last_statement_latency`,`last_wait`,`last_wait_latency`,`source`,`pid`,`program_name`)
AS 
  SELECT    `pps`.`thread_id`      AS `thd_id`, 
            `pps`.`processlist_id` AS `conn_id`, 
            IF((`pps`.`name` IN ('thread/sql/one_connection', 
                                 'thread/thread_pool/tp_one_connection')), concat(`pps`.`processlist_user`,'@',`pps`.`processlist_host`),REPLACE(`pps`.`name`,'thread/','')) AS `user`,
            `pps`.`processlist_db`                                                                                                                                           AS `db`,
            `pps`.`processlist_command`                                                                                                                                      AS `command`,
            `pps`.`processlist_state`                                                                                                                                        AS `state`,
            `pps`.`processlist_time`                                                                                                                                         AS `time`,
            `pps`.`processlist_info`                                                                                                                                         AS `current_statement`,
            IF(isnull(`esc`.`end_event_id`),`esc`.`timer_wait`,NULL)                                                                                                         AS `statement_latency`,
            `esc`.`lock_time`                                                                                                                                                AS `lock_latency`,
            `esc`.`rows_examined`                                                                                                                                            AS `rows_examined`,
            `esc`.`rows_sent`                                                                                                                                                AS `rows_sent`,
            `esc`.`rows_affected`                                                                                                                                            AS `rows_affected`,
            `esc`.`created_tmp_tables`                                                                                                                                       AS `tmp_tables`,
            `esc`.`created_tmp_disk_tables`                                                                                                                                  AS `tmp_disk_tables`,
            IF(((`esc`.`no_good_index_used` > 0) 
  OR        ( 
                      `esc`.`no_index_used` > 0)),'YES','NO')              AS `full_scan`, 
            IF((`esc`.`end_event_id` IS NOT NULL),`esc`.`sql_text`,NULL)   AS `last_statement`, 
            IF((`esc`.`end_event_id` IS NOT NULL),`esc`.`timer_wait`,NULL) AS `last_statement_latency`,
            `ewc`.`event_name`                                             AS `last_wait`, 
            IF((isnull(`ewc`.`end_event_id`) 
  AND       ( 
                      `ewc`.`event_name` IS NOT NULL)),'Still Waiting', `ewc`.`timer_wait`) AS `last_wait_latency`,
            `ewc`.`source`                                                                  AS `source`,
            `conattr_pid`.`attr_value`                                                      AS `pid`,
            `conattr_progname`.`attr_value`                                                 AS `program_name` 
  FROM      ((((((`performance_schema`.`threads` `pps` 
  LEFT JOIN `performance_schema`.`events_waits_current` `ewc` 
  ON       (( 
                                `pps`.`thread_id` = `ewc`.`thread_id`))) 
  LEFT JOIN `performance_schema`.`events_stages_current` `estc` 
  ON       (( 
                                `pps`.`thread_id` = `estc`.`thread_id`))) 
  LEFT JOIN `performance_schema`.`events_statements_current` `esc` 
  ON       (( 
                                `pps`.`thread_id` = `esc`.`thread_id`))) 
  LEFT JOIN `performance_schema`.`session_connect_attrs` `conattr_pid` 
  ON       ((( 
                                          `conattr_pid`.`processlist_id` = `pps`.`processlist_id`)
                      AND       ( 
                                          `conattr_pid`.`attr_name` = '_pid')))) 
  LEFT JOIN `performance_schema`.`session_connect_attrs` `conattr_progname` 
  ON       ((( 
                                          `conattr_progname`.`processlist_id` = `pps`.`processlist_id`)
                      AND       ( 
                                          `conattr_progname`.`attr_name` = 'program_name')))) 
  ) 
  WHERE     `pps`.`processlist_id` IS NOT NULL 
  AND       `pps`.`processlist_command` != 'Daemon' 
  AND       `pps`.`processlist_command` != 'Sleep';


CREATE TABLE aas1 ( 
 snap_time               datetime                                ,
 thd_id                  bigint(20) unsigned                     ,
 conn_id                 bigint(20) unsigned                     ,
 user                    varchar(128)                            ,
 db                      varchar(64)                             ,
 command                 varchar(16)                             ,
 state                   varchar(64)                             ,
 time                    bigint(20)                              ,
 statement_digest        varchar(64)                             ,
 current_statement       varchar(128)                            ,
 statement_latency       bigint(20) unsigned                     ,
 lock_latency            bigint(20) unsigned                     ,
 rows_examined           bigint(20) unsigned                     ,
 rows_sent               bigint(20) unsigned                     ,
 rows_affected           bigint(20) unsigned                     ,
 tmp_tables              bigint(20) unsigned                     ,
 tmp_disk_tables         bigint(20) unsigned                     ,
 full_scan               varchar(3)                              ,
 last_statement_digest   varchar(64)                             ,
 last_statement          varchar(128)                            ,
 last_statement_latency  bigint(20) unsigned                     ,
 last_wait               varchar(128)                            ,
 last_wait_latency       varchar(20)                             ,
 source                  varchar(64)                             ,
 pid                     varchar(10)                             ,
 program_name            varchar(32)                              )   ENGINE=MEMORY ;  



CREATE TABLE aas2 ( 
 snap_time               datetime                                ,
 thd_id                  bigint(20) unsigned                     ,
 conn_id                 bigint(20) unsigned                     ,
 user                    varchar(128)                            ,
 db                      varchar(64)                             ,
 command                 varchar(16)                             ,
 state                   varchar(64)                             ,
 time                    bigint(20)                              ,
 statement_digest        varchar(64)                             ,
 current_statement       varchar(128)                            ,
 statement_latency       bigint(20) unsigned                     ,
 lock_latency            bigint(20) unsigned                     ,
 rows_examined           bigint(20) unsigned                     ,
 rows_sent               bigint(20) unsigned                     ,
 rows_affected           bigint(20) unsigned                     ,
 tmp_tables              bigint(20) unsigned                     ,
 tmp_disk_tables         bigint(20) unsigned                     ,
 full_scan               varchar(3)                              ,
 last_statement_digest   varchar(64)                             ,
 last_statement          varchar(128)                            ,
 last_statement_latency  bigint(20) unsigned                     ,
 last_wait               varchar(128)                            ,
 last_wait_latency       varchar(20)                             ,
 source                  varchar(64)                             ,
 pid                     varchar(10)                             ,
 program_name            varchar(32)                              )   ENGINE=MEMORY ;  



CREATE TABLE aas3 ( 
 snap_time               datetime                                ,
 thd_id                  bigint(20) unsigned                     ,
 conn_id                 bigint(20) unsigned                     ,
 user                    varchar(128)                            ,
 db                      varchar(64)                             ,
 command                 varchar(16)                             ,
 state                   varchar(64)                             ,
 time                    bigint(20)                              ,
 statement_digest        varchar(64)                             ,
 current_statement       varchar(128)                            ,
 statement_latency       bigint(20) unsigned                     ,
 lock_latency            bigint(20) unsigned                     ,
 rows_examined           bigint(20) unsigned                     ,
 rows_sent               bigint(20) unsigned                     ,
 rows_affected           bigint(20) unsigned                     ,
 tmp_tables              bigint(20) unsigned                     ,
 tmp_disk_tables         bigint(20) unsigned                     ,
 full_scan               varchar(3)                              ,
 last_statement_digest   varchar(64)                             ,
 last_statement          varchar(128)                            ,
 last_statement_latency  bigint(20) unsigned                     ,
 last_wait               varchar(128)                            ,
 last_wait_latency       varchar(20)                             ,
 source                  varchar(64)                             ,
 pid                     varchar(10)                             ,
 program_name            varchar(32)                              )   ENGINE=MEMORY ;  


CREATE TABLE aas4 ( 
 snap_time               datetime                                ,
 thd_id                  bigint(20) unsigned                     ,
 conn_id                 bigint(20) unsigned                     ,
 user                    varchar(128)                            ,
 db                      varchar(64)                             ,
 command                 varchar(16)                             ,
 state                   varchar(64)                             ,
 time                    bigint(20)                              ,
 statement_digest        varchar(64)                             ,
 current_statement       varchar(128)                            ,
 statement_latency       bigint(20) unsigned                     ,
 lock_latency            bigint(20) unsigned                     ,
 rows_examined           bigint(20) unsigned                     ,
 rows_sent               bigint(20) unsigned                     ,
 rows_affected           bigint(20) unsigned                     ,
 tmp_tables              bigint(20) unsigned                     ,
 tmp_disk_tables         bigint(20) unsigned                     ,
 full_scan               varchar(3)                              ,
 last_statement_digest   varchar(64)                             ,
 last_statement          varchar(128)                            ,
 last_statement_latency  bigint(20) unsigned                     ,
 last_wait               varchar(128)                            ,
 last_wait_latency       varchar(20)                             ,
 source                  varchar(64)                             ,
 pid                     varchar(10)                             ,
 program_name            varchar(32)                              )   ENGINE=MEMORY ;  

 CREATE ALGORITHM=TEMPTABLE  SQL SECURITY INVOKER VIEW `mariadb2`.`active_session_history` as 
 select * from `mariadb2`.`aas1` 
 union all
 select * from `mariadb2`.`aas2` 
 union all 
 select * from `mariadb2`.`aas3` 
 union all
 select * from `mariadb2`.`aas4` order by snap_time desc;
 

CREATE TABLE active_session_history_perm ( 
 snap_time               datetime                                ,
 thd_id                  bigint(20) unsigned                     ,
 conn_id                 bigint(20) unsigned                     ,
 user                    varchar(128)                            ,
 db                      varchar(64)                             ,
 command                 varchar(16)                             ,
 state                   varchar(64)                             ,
 time                    bigint(20)                              ,
 statement_digest        varchar(64)                             ,
 current_statement       varchar(128)                            ,
 statement_latency       bigint(20) unsigned                     ,
 lock_latency            bigint(20) unsigned                     ,
 rows_examined           bigint(20) unsigned                     ,
 rows_sent               bigint(20) unsigned                     ,
 rows_affected           bigint(20) unsigned                     ,
 tmp_tables              bigint(20) unsigned                     ,
 tmp_disk_tables         bigint(20) unsigned                     ,
 full_scan               varchar(3)                              ,
 last_statement_digest   varchar(64)                             ,
 last_statement          varchar(128)                            ,
 last_statement_latency  bigint(20) unsigned                     ,
 last_wait               varchar(128)                            ,
 last_wait_latency       varchar(20)                             ,
 source                  varchar(64)                             ,
 pid                     varchar(10)                             ,
 program_name            varchar(32)                              ) ;  
