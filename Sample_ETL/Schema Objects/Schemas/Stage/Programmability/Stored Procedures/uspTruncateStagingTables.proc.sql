CREATE PROCEDURE Stage.uspTruncateStagingTables

AS

/*
	Purpose: New SP to truncate uncleared staging tables and email developers
	
	Version			Date				Developer			Comment
	1.0				2017-02-17			Chris Ledger		New SP to truncate uncleared staging tables and email developers
	1.1				2019-04-11			Chris Ross			BUG 15345 - Update to use IPSOS email addresses.
	1.2				2019-07-23			Chris Ledger		Add Removed_Records_Staging_Tables to List of Excluded Tables
	1.3				2020-01-10			Chris Ledger		BUG 15372 - Fix Hard coded references to databases
	1.4				2021-04-09			Chris Ledger		Add CRCAgents-GlobalList to list of excluded tables
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @CMD VARCHAR(1000);
	DECLARE @TableName VARCHAR(100);
	DECLARE @ErrorTableName VARCHAR(100);	
	DECLARE @Counter INT;

	DECLARE @tableHTML  NVARCHAR(MAX);
	DECLARE @Subject NVARCHAR(MAX) = 'Staging Table Tidy-Up Report: ' + CONVERT(VARCHAR(10),GETDATE(),103);
	--DECLARE @To NVARCHAR(MAX) = 'Chris.Ledger@ipsos.com';
	DECLARE @To NVARCHAR(MAX) = 'Chris.Ledger@ipsos.com;Ben.King@ipsos.com;Eddie.Thomas@ipsos.com';
	DECLARE @Profile_Name SYSNAME = 'DBAProfile';


	-----------------------------------------------------------------------------
	-- ADD ALL STAGING TABLES INTO #Staging TEMPORARY TABLE (INCLUDING HARD CODED LIST OF TABLES TO EXCLUDE)
	-----------------------------------------------------------------------------
	--DROP TABLE #Staging
	--SELECT TABLE_SCHEMA, TABLE_NAME, 0 AS RowCnt
	--INTO #Staging
	--FROM Sample_ETL.INFORMATION_SCHEMA.TABLES
	--WHERE TABLE_SCHEMA = 'Stage'
	--AND TABLE_NAME <> 'AFRLCodeLookupData'
	--AND TABLE_NAME <> 'Global_Sales_07032016'
	--AND TABLE_NAME <> 'InviteMatrix'
	--AND TABLE_NAME <> 'SVOLookup'

	DROP TABLE IF EXISTS #Staging

	CREATE TABLE #Staging (
	TABLE_SCHEMA VARCHAR(100),
	TABLE_NAME VARCHAR(100),
	RowCnt INT )

	SET @CMD = 'INSERT INTO #Staging (TABLE_SCHEMA, TABLE_NAME, RowCnt)' +
	' SELECT TABLE_SCHEMA, TABLE_NAME, 0 AS RowCnt FROM INFORMATION_SCHEMA.TABLES' +
	' WHERE TABLE_SCHEMA = ''Stage''' +
	' AND TABLE_NAME <> ''CRCAgents-GlobalList'' AND TABLE_NAME <> ''Removed_Records_Staging_Tables'' AND TABLE_NAME <> ''AFRLCodeLookupData'' AND TABLE_NAME <> ''Global_Sales_07032016'' AND TABLE_NAME <> ''InviteMatrix'' AND TABLE_NAME <> ''SVOLookup'''
	EXEC(@CMD);
	

	-----------------------------------------------------------------------------
	-- DECLARE A CURSOR TO LOOP THROUGH #Staging
	-----------------------------------------------------------------------------
	DECLARE cursor1 CURSOR
	FOR
		SELECT TABLE_NAME
		FROM #Staging;
	OPEN cursor1;

	FETCH NEXT FROM cursor1 
			INTO @TableName;

	WHILE @@FETCH_STATUS = 0
		BEGIN

			-----------------------------------------------------------------------------
			-- UPDATE RowCnt 
			-----------------------------------------------------------------------------
			SET @CMD = 'UPDATE S SET RowCnt = (SELECT COUNT(*) FROM Stage.' + @TableName + ') FROM #Staging S WHERE TABLE_NAME = '
				+ CHAR(39) + @TableName + CHAR(39);
			EXEC(@CMD);
           
            
			FETCH NEXT FROM cursor1 
				INTO @TableName;
		END;
	CLOSE cursor1;
	DEALLOCATE cursor1;


	--SELECT * FROM #Staging WHERE RowCnt > 0
	
	-----------------------------------------------------------------------------
	-- CHECK ANY FILES TO DELETE
	-----------------------------------------------------------------------------
	SELECT @Counter = COUNT(*) 
	FROM #Staging
	WHERE RowCnt > 0;

	IF @Counter > 0 
		BEGIN

			-----------------------------------------------------------------------------
			-- DECLARE A CURSOR TO LOOP THROUGH #Staging TABLE
			-----------------------------------------------------------------------------
			DECLARE cursor2 CURSOR
			FOR
				SELECT TABLE_NAME
				FROM #Staging
				WHERE RowCnt > 0;
			OPEN cursor2;
		
			FETCH NEXT FROM cursor2 INTO @TableName;

			WHILE @@FETCH_STATUS = 0
				BEGIN

					-----------------------------------------------------------------------------
					-- COPY STAGING TABLE TO ERROR TABLE
					-----------------------------------------------------------------------------
					SELECT @ErrorTableName = @TableName + '_' + REPLACE(CONVERT(DATE, GETDATE()) ,'-', '') + '_' + REPLACE(LEFT(CONVERT(TIME, GETDATE()),8), ':', '') 
					SET @CMD = 'SELECT * INTO Sample_Errors.Stage.' + @ErrorTableName + ' FROM Stage.' + @TableName 
					EXEC(@CMD);
                
					-----------------------------------------------------------------------------
					-- COPY STAGING TABLE TO ERROR TABLE
					-----------------------------------------------------------------------------
					SET @CMD = 'TRUNCATE TABLE Stage.' + @TableName 
					EXEC(@CMD);


					FETCH NEXT FROM cursor2 INTO @TableName;
				END;

			CLOSE cursor2;
			DEALLOCATE cursor2;
				

			--------------------------------------------------------
			-- CREATE HTML OUPUT
			--------------------------------------------------------
			SET @tableHTML =  	
				N'<H3 style ="font-size:12px; font-family:arial,helvetica,sans-serif; font-weight:normal; text-align:left; background:#ffffff;">The following staging tables were not truncated in the overnight load.<BR>They have been truncated and copied to Sample_Errors database:-</H3>' +
				N'<table border="0" align="left" cellpadding="2" cellspacing="0" style="color:black;font-family:arial,helvetica,sans-serif;text-align:left;" >' +
				N'<tr style ="font-size:12px; font-weight:bold; text-align:left; background:#ffffff;"><td style="width:300px">Table</td>' +  
				N'<td>No. of Rows</td></tr>' +  
				CAST ( ( SELECT 'font-size:12px; font-weight:normal; text-align:left; background:#ffffff' as [@style], td = TABLE_NAME, '',
					RowCnt AS td
					FROM #Staging
					WHERE RowCnt > 0
					ORDER BY TABLE_NAME
					FOR XML PATH('tr'), TYPE) AS NVARCHAR(MAX) ) +  
				N'</table>' ;  
			--------------------------------------------------------
		    
			--------------------------------------------------------
			-- SEND EMAIL IF STAGING TABLES NOT TRUNCATED 
			--------------------------------------------------------
			EXEC msdb.dbo.sp_send_dbmail @profile_name = @Profile_Name,
				@recipients = @To, @subject = @Subject, @body = @tableHTML, @body_format = 'HTML';
			--------------------------------------------------------

		END;

	DROP TABLE #Staging;

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
			
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH