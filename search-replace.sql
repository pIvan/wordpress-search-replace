DROP PROCEDURE IF EXISTS run_wp_table_update;

DELIMITER GO
CREATE PROCEDURE run_wp_table_update(
	IN FIND_URL VARCHAR(255),
	IN REPLACE_URL_WITH VARCHAR(255)
)
BEGIN
	DECLARE finished INTEGER DEFAULT 0;
	DECLARE query_string longtext DEFAULT "";
	DECLARE query_cursor CURSOR FOR (SELECT QUERY FROM sql_queries);
	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
		BEGIN
			ROLLBACK;
			RESIGNAL;
		END;


	START TRANSACTION;
		SET @DATABASENAME := (SELECT DATABASE() FROM DUAL);
		-- enable more then 1024 bytes long string in CONCAT
		SET @@session.group_concat_max_len = @@global.max_allowed_packet;

		DROP TEMPORARY TABLE IF EXISTS all_tables_attributes;
		DROP TEMPORARY TABLE IF EXISTS sql_queries;

		-- get all atributes we need to check
		CREATE TEMPORARY TABLE all_tables_attributes
		SELECT
			col.TABLE_NAME
			,col.COLUMN_NAME
			,CONCAT(col.COLUMN_NAME, ' = REPLACE(', col.COLUMN_NAME, ', \'', FIND_URL, '\', \'', REPLACE_URL_WITH, '\')') AS SQL_PART
		FROM
			INFORMATION_SCHEMA.TABLES tb
		LEFT JOIN
			INFORMATION_SCHEMA.COLUMNS col
		ON
			tb.TABLE_NAME = col.TABLE_NAME
		WHERE 
			col.TABLE_SCHEMA = @DATABASENAME
			AND (
				LOWER(DATA_TYPE) = 'varchar'
				OR LOWER(DATA_TYPE) = 'tinytext'
				OR LOWER(DATA_TYPE) = 'text'
				OR LOWER(DATA_TYPE) = 'mediumtext'
				OR LOWER(DATA_TYPE) = 'longtext'
			)
		;

		-- prepare query strings
		CREATE TEMPORARY TABLE sql_queries
		SELECT 
			TABLE_NAME
			,GROUP_CONCAT(DISTINCT COLUMN_NAME) AS COLUMN_NAMES
			,CONCAT('UPDATE ', TABLE_NAME, ' SET ', GROUP_CONCAT(DISTINCT SQL_PART)) AS QUERY
		FROM
			all_tables_attributes
		GROUP BY
			TABLE_NAME
		;

		SET SQL_SAFE_UPDATES = 0;
		OPEN query_cursor;
		query_loop: LOOP
			FETCH query_cursor INTO query_string;
			IF finished THEN
				LEAVE query_loop;
			END IF;
			
			SET @query = query_string;
			SELECT @query;

			PREPARE stmt FROM @query; 
			EXECUTE stmt; 
			DEALLOCATE PREPARE stmt;

		END LOOP query_loop;
		CLOSE query_cursor;
		SET SQL_SAFE_UPDATES = 1;
	COMMIT;
END GO


DELIMITER ;
SET @FIND_URL = 'http://localhost/projects-name/';
SET @REPLACE_URL_WITH = 'https://www.example.com/';

CALL run_wp_table_update(@FIND_URL, @REPLACE_URL_WITH);
DROP PROCEDURE IF EXISTS run_wp_table_update;
