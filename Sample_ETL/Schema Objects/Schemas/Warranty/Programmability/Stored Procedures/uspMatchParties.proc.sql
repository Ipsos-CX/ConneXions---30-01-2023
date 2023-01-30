CREATE PROCEDURE Warranty.uspMatchParties
AS

/*
	Purpose:	Uses view to return most appropriate party relating to matched vehicle that has not already been transferred to VWT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)	Simon Peacock		Created from [Prophet-ETL].dbo.uspMATCH_WarrantyParties
	1.1				2018-04-27		Chris Ledger		BUG 14664: Run FULL OR PARTIAL check based on vwMatchWarrantyParties

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @Day VARCHAR(10) = DATENAME(DW,GETDATE())
	
	IF @Day = 'Saturday'
	
		-- RUN FULL UPDATE USING vwMatchWarrantyParties
		
		BEGIN

			-- UPDATE MATCHED PERSON PartyIDs
			UPDATE WE
			SET WE.MatchedODSPersonID = MWP.PartyID
			FROM Warranty.vwMatchWarrantyParties MWP
			INNER JOIN Warranty.WarrantyEvents WE ON WE.MatchedODSVehicleID = MWP.VehicleID
			WHERE ISNULL(WE.MatchedODSPersonID, 0) = 0
			AND MWP.PartyID > 0
			AND MWP.Person = 1;

			-- UPDATE MATCHED ORGANISATION PartyIDs
			UPDATE WE
			SET WE.MatchedODSOrganisationID = MWP.PartyID
			FROM Warranty.vwMatchWarrantyParties MWP
			INNER JOIN Warranty.WarrantyEvents WE ON WE.MatchedODSVehicleID = MWP.VehicleID
			WHERE ISNULL(WE.MatchedODSOrganisationID, 0) = 0
			AND MWP.PartyID > 0
			AND MWP.Organisation = 1;
		
		END
	
	ELSE
	
		-- RUN PARTIAL UPDATE USING vwMatchWarrantyPartiesPartial

		BEGIN
	
			-- UPDATE MATCHED PERSON PartyIDs
			UPDATE WE
			SET WE.MatchedODSPersonID = MWP.PartyID
			FROM Warranty.vwMatchWarrantyPartiesPartial MWP
			INNER JOIN Warranty.WarrantyEvents WE ON WE.MatchedODSVehicleID = MWP.VehicleID
			WHERE ISNULL(WE.MatchedODSPersonID, 0) = 0
			AND MWP.PartyID > 0
			AND MWP.Person = 1;

			-- UPDATE MATCHED ORGANISATION PartyIDs
			UPDATE WE
			SET WE.MatchedODSOrganisationID = MWP.PartyID
			FROM Warranty.vwMatchWarrantyPartiesPartial MWP
			INNER JOIN Warranty.WarrantyEvents WE ON WE.MatchedODSVehicleID = MWP.VehicleID
			WHERE ISNULL(WE.MatchedODSOrganisationID, 0) = 0
			AND MWP.PartyID > 0
			AND MWP.Organisation = 1;

		END

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