-- modified by Karl Arao for RDS Mariadb 10.1.23 compatibility
-- original project https://github.com/hatem-mahmoud/Ash_sampler

-- Installation: 
--   on your text editor replace mariadb2 with the username that you'll use for monitoring
-- or use sed below:
--   sed 's/mariadb2/your_username_here/g' 01_create_objects.sql.bak > 01.sql
--   sed 's/mariadb2/your_username_here/g' 02_ash_sampler.sql > 02.sql

-- Parameters
-- -----------
-- in_max_runtime (DECIMAL(20,2)):
--   The maximum time to keep collecting data.
--   Use NULL to get the default which is 60 seconds or 1 for infinite gathering.
-- in_interval (DECIMAL(20,2)):
--   How long to sleep between data collections. 
--   Use NULL to get the default which is 1 second.
-- in_memory_size (INT):
--   Size of the memory table. Will be used to set parameter max_heap_table_size.
--   The max consumed memory will be 4*in_memory_size (Tables aas1,aas2,aas3 and aas4)


-- Example run
-- ----------- 
-- infinite gathering, for every 1 sec, and create 16MB in-memory buffers
--
-- call ash_sampler(1,1,16);


-- After collection do the following:
-- ----------- 
-- 1) CTRL-C or kill the ash_sampler - the process with SQL "SELECT SLEEP( NAME_CONST('in_interval'"
-- 
-- mysql> show processlist;
-- Id	User	Host	db	Command	Time	State	Info	Progress
-- 4	rdsadmin	localhost:11948	NULL	Sleep	6		NULL	0.000
-- 136	mariadb2	nyc.res.rr.com:53978	mariadb2	Query	5283	User sleep	SELECT SLEEP( NAME_CONST('in_interval',1.00)) INTO @sleep	0.000
-- 
-- mysql> kill 136;
--
-- 2) Using DBeaver Community Edition. Export the active_session_history and active_session_history_perm data to CSV
-- 
-- select * from active_session_history;
-- select * from active_session_history_perm;



USE mariadb2;

-- execute this CREATE PROCEDURE using DBeaver Community Edition 
CREATE PROCEDURE ash_sampler (     
        IN in_max_runtime DECIMAL(20,2),
        IN in_interval DECIMAL(20,2),
        IN in_memory_size INT
    )
    SQL SECURITY INVOKER
    NOT DETERMINISTIC    
BEGIN
    -- Anticipate that the next insertion with catch 100 active sessions
    DECLARE v_safe_guard_rows int DEFAULT 100;
    DECLARE v_max_rows_per_table int DEFAULT 200;
    DECLARE v_number_of_inst_rows int DEFAULT 0;
    DECLARE v_working_on int DEFAULT 1 ; 
    DECLARE v_start, v_runtime DECIMAL(20,2) DEFAULT 0.0;
    DECLARE v_this_thread_enabed ENUM('YES', 'NO');
	DECLARE v_sanp_time DATETIME;

    -- In case of table full error continue execution and switch to the next table
    DECLARE CONTINUE HANDLER FOR SQLSTATE 'HY000' BEGIN set v_number_of_inst_rows = v_max_rows_per_table + 1 ; END;      
   
    SET v_start        = UNIX_TIMESTAMP(),
        in_interval    = IFNULL(in_interval, 1.00),
        in_max_runtime = IFNULL(in_max_runtime, 60.00),
	-- 4 KB is the average row length calculated as DATA_LENGTH/TABLE_ROWS
	-- v_safe_guard_rows is there to anticipate the next insertion and avoid filling the table (to keep some free space for future insertion) 
		v_max_rows_per_table = ROUND(IFNULL(in_memory_size,16)*1024/4,0) - v_safe_guard_rows;
        
	-- Set the new size limit for the memory tables 
    SET max_heap_table_size = 1024*1024*IFNULL(in_memory_size, 16);
    truncate table aas1;    
    truncate table aas2;
    truncate table aas3;    
    truncate table aas4;

    WHILE (v_runtime < in_max_runtime or in_max_runtime = 1) DO   
	   
	   set v_sanp_time = sysdate();
       CASE  v_working_on
         WHEN 1 THEN insert into aas1 select v_sanp_time,a.thd_id, a.conn_id, a.user, a.db, a.command, a.state,a.time,md5(a.current_statement),left(a.current_statement,128),a.statement_latency,a.lock_latency,a.rows_examined,a.rows_sent,a.rows_affected,a.tmp_tables,a.tmp_disk_tables,a.full_scan,md5(a.last_statement),left(a.last_statement,128),a.last_statement_latency,a.last_wait,a.last_wait_latency,a.source,a.pid,a.program_name from aas_source a where  a.conn_id != CONNECTION_ID(); set v_number_of_inst_rows = v_number_of_inst_rows + ROW_COUNT();
         WHEN 2 THEN insert into aas2 select v_sanp_time,a.thd_id, a.conn_id, a.user, a.db, a.command, a.state,a.time,md5(a.current_statement),left(a.current_statement,128),a.statement_latency,a.lock_latency,a.rows_examined,a.rows_sent,a.rows_affected,a.tmp_tables,a.tmp_disk_tables,a.full_scan,md5(a.last_statement),left(a.last_statement,128),a.last_statement_latency,a.last_wait,a.last_wait_latency,a.source,a.pid,a.program_name from aas_source a where  a.conn_id != CONNECTION_ID(); set v_number_of_inst_rows = v_number_of_inst_rows + ROW_COUNT();
         WHEN 3 THEN insert into aas3 select v_sanp_time,a.thd_id, a.conn_id, a.user, a.db, a.command, a.state,a.time,md5(a.current_statement),left(a.current_statement,128),a.statement_latency,a.lock_latency,a.rows_examined,a.rows_sent,a.rows_affected,a.tmp_tables,a.tmp_disk_tables,a.full_scan,md5(a.last_statement),left(a.last_statement,128),a.last_statement_latency,a.last_wait,a.last_wait_latency,a.source,a.pid,a.program_name from aas_source a where  a.conn_id != CONNECTION_ID(); set v_number_of_inst_rows = v_number_of_inst_rows + ROW_COUNT();
         WHEN 4 THEN insert into aas4 select v_sanp_time,a.thd_id, a.conn_id, a.user, a.db, a.command, a.state,a.time,md5(a.current_statement),left(a.current_statement,128),a.statement_latency,a.lock_latency,a.rows_examined,a.rows_sent,a.rows_affected,a.tmp_tables,a.tmp_disk_tables,a.full_scan,md5(a.last_statement),left(a.last_statement,128),a.last_statement_latency,a.last_wait,a.last_wait_latency,a.source,a.pid,a.program_name from aas_source a where  a.conn_id != CONNECTION_ID(); set v_number_of_inst_rows = v_number_of_inst_rows + ROW_COUNT();
        END CASE;
        
	-- If current table is almost full switch to the next table after truncating it. 
        IF (v_number_of_inst_rows > v_max_rows_per_table  ) THEN 
        
            CASE  v_working_on
             WHEN 1 THEN  set v_working_on=2;     truncate table aas2; set v_number_of_inst_rows=0; insert into active_session_history_perm select * from aas1;
             WHEN 2 THEN  set v_working_on=3;     truncate table aas3; set v_number_of_inst_rows=0; insert into active_session_history_perm select * from aas2;
             WHEN 3 THEN  set v_working_on=4;     truncate table aas4; set v_number_of_inst_rows=0; insert into active_session_history_perm select * from aas3;
             WHEN 4 THEN  set v_working_on=1;     truncate table aas1; set v_number_of_inst_rows=0; insert into active_session_history_perm select * from aas4;
            END CASE;

            COMMIT;
            
        END IF;
       
        SELECT SLEEP(in_interval) INTO @sleep;
        SET v_runtime = (UNIX_TIMESTAMP() - v_start);
    END WHILE;
END;


