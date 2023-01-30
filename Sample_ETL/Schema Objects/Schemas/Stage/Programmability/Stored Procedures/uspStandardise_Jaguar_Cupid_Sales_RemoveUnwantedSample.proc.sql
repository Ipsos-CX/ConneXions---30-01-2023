CREATE PROCEDURE Stage.uspStandardise_Jaguar_Cupid_Sales_RemoveUnwantedSample
@SampleFileName NVARCHAR (100)

AS
/*
	Purpose:	The Jaguar Cupid file contains records for sample that we are not authorised to use or should be being supplied in another 
				sample file. We need to remove this data prior to loading and amend the RowCount in audit accordingly.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock	Created from [Prophet-ETL].dbo.uspVWTLOAD_CupidJaguarRemoveUnauthorisedSample
	1.1				03/12/2015		Chris Ledger		Remove bug which deletes update records from all files loaded rather than specific one 

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		-- REMOVE ALL UPDATE RECORDS PRIOR TO VWT TRANSFER
		-- V1.1 Only delete records from current file
		DELETE Stage.Jaguar_Cupid_Sales
		FROM Stage.Jaguar_Cupid_Sales
		INNER JOIN [$(AuditDB)].dbo.Files F ON Stage.Jaguar_Cupid_Sales.AuditID = F.AuditID
		WHERE F.[FileName] = @SampleFileName 
		AND PhysicalRowID >=
			(
				SELECT MIN(PhysicalRowID)
				FROM Stage.Jaguar_Cupid_Sales
				INNER JOIN [$(AuditDB)].dbo.Files F ON Stage.Jaguar_Cupid_Sales.AuditID = F.AuditID
				WHERE ResidenceCountry = '016' AND CustomerID = 'GBRANOPUPDT'
				AND F.[FileName] = @SampleFileName
			)
			
		-- REMOVE SUPERFLOUS HEADERS AND FOOTERS
		DELETE
		FROM Stage.Jaguar_Cupid_Sales
		WHERE ResidenceCountry = '016' and CustomerID = 'GBRANOPGBRI'
		
		-- SET THE ANDORAN RECORDS TO BE SPAIN
		UPDATE Stage.Jaguar_Cupid_Sales
		SET ResidenceCountry = 'ESP'
		WHERE ResidenceCountry = 'AND'

		-- REMOVE ALL UNAUTHORISED COUNTRIES FROM STAGING TABLE
		DELETE
		FROM Stage.Jaguar_Cupid_Sales
		WHERE ID NOT IN (
			SELECT DISTINCT S.ID
			FROM [$(SampleDB)].dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ
			INNER JOIN [$(SampleDB)].ContactMechanism.Countries C ON C.CountryID = BMQ.CountryID
			INNER JOIN Stage.Jaguar_Cupid_Sales S ON S.ResidenceCountry = C.ISOAlpha3
												AND CASE S.Manufacturer
														WHEN 'J' THEN 'Jaguar'
														WHEN 'L' THEN 'Land Rover'
													END = BMQ.Brand
			WHERE BMQ.SampleFileNamePrefix = 'Jaguar_Cupid_Sales'
		)

		-- UPDATE THE FILE ROW COUNT IN AUDIT
		UPDATE F
		SET F.FileRowCount = X.FileRowCount
		FROM (
			SELECT S.AuditID, COUNT(S.ID) AS FileRowCount
			FROM Stage.Jaguar_Cupid_Sales S
			GROUP BY S.AuditID
		) X
		INNER JOIN [$(AuditDB)].dbo.Files F ON F.AuditID = X.AuditID

	COMMIT TRAN
	
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
		
	-- CREATE A COPY OF THE STAGING TABLE FOR USE IN PRODUCTION SUPPORT
	DECLARE @TimestampString CHAR(15)
	SELECT @TimestampString = [$(ErrorDB)].dbo.udfGetTimestampString(GETDATE())
	
	EXEC('
		SELECT *
		INTO [$(ErrorDB)].Stage.Jaguar_Cupid_Sales_' + @TimestampString + '
		FROM Stage.Jaguar_Cupid_Sales
	')
	
	-- FINALLY RAISE THE ERROR
	RAISERROR ( @ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine )
	
END CATCH