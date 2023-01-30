CREATE PROCEDURE [SampleReport].[uspGenerateBaseDataDistinctEvents]
	
AS 

	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

/*
	Purpose:	Removes duplicated events from the sample reporting base table from which the various sub reports are generated from
				
				N.B. There are no parameters. The base data table has already been populated at this stage for the sample report generation.
		
	Version		Date				Developer			Comment
	1.0			18/11/2013			Martin Riverol		Created (BUG #9296)
	1.1			29/11/2013			Martin Riverol		Amended distinct event logic to keep sent cases as opposed to cases (as they may have been rejected)
*/

BEGIN TRY

	/* REMOVE RECORDS ALREADY MARKED AS DUPLICATES */

		DELETE FROM SampleReport.Base
		WHERE DuplicateRowFlag = 1
		
	/* BUG# 9296 DE-DUPLICATION RULES
		1. DE-DUPLICATE ON VIN / EVENTDATE
		2. REMOVE EVENT THAT HAS NOT BEEN SELECTED
		3. IF BOTH SELECTED, KEEP BOTH
		4. IF NEITHER HAVE BEEN SELECTED, KEEP THE ONE FROM THE DEALER ‘SERVICE’ AND DELETE THE DDW ONE 
	*/
	
	--IF (OBJECT_ID('tempdb..#SortDupesForRemoval') IS NOT NULL)
			--BEGIN
				--DROP TABLE #SortDupesForRemoval
			--END
	
	
	--CREATE TABLE #SortDupesForRemoval
			
		--(
			--AuditItemID BIGINT
			--, VIN VARCHAR(50)
			--, EventDate DATETIME2
			--, CaseID INT
			--, SentDate DATETIME2
			--, FileName VARCHAR(100)
			--, RemovalSort SMALLINT
		--);
			
	--WITH cteDupes
	--AS
		--(
			--SELECT VIN, EventDate
			--FROM SampleReport.Base B
			--GROUP BY B.VIN, B.EventDate
			--HAVING COUNT(*) > 1
		--) 
		
			--INSERT INTO #SortDupesForRemoval
				
				--(
					--AuditItemID
					--, VIN
					--, EventDate
					--, CaseID
					--, SentDate
					--, FileName
					--, RemovalSort
				--)
					--SELECT 
						--B.AuditItemID
						--, B.VIN
						--, B.EventDate
						--, B.CaseID
						--, B.SentDate
						--, FileName
						--, ROW_NUMBER() OVER (PARTITION BY B.VIN, B.EventDate ORDER BY B.SentDate DESC, CASE WHEN B.FileName LIKE '%DDW%' THEN 0 ELSE 1 END) RemovalSort
					--FROM SampleReport.Base B
					--INNER JOIN cteDupes D ON B.VIN = D.VIN AND B.EventDate = D.EventDate;

	
	--DELETE FROM B 
	--FROM #SortDupesForRemoval R
	--INNER JOIN SampleReport.Base B ON R.AuditItemID = B.AuditItemID
	--WHERE R.RemovalSort > 1
	--AND R.SentDate IS NULL		
	
	DELETE FROM SampleReport.Base
	WHERE DedupeEqualToEvents = 1

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