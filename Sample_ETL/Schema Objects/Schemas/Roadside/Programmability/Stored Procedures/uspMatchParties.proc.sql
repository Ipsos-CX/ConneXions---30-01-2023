CREATE PROCEDURE Roadside.uspMatchParties
AS

/*
	Purpose:	Uses view to return most appropriate party relating to matched vehicle that has not already been transferred to VWT
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Chris Ross		Created from [Sample_ETL].Warranty.uspMatchParties
	1.1				14-10-2013		Chris Ross			Bug 8976 - Only update where the PerformNormalVWTLoadFlag is set to 'N' i.e. we are 
														doing non-standard system loading/matching.
	1.2				10-04-2014		Chris Ross			Bug 10216 - Match People and Organisations on name as well as VIN (where it exists)
	1.3				09-03-2016		Chris Ross			BUG 12470 - update so that only exact matches of lastname or organisation will populate partyID
	1.4				21-03-2016		Chris Ross			BUG 12470 - Modified to populate the Person just using VIN where no name or organisation name populated.
																	Where Organisation name present in sample then only populate Organisation where one exists.
														
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- UPDATE MATCHED PERSON PartyIDs
	UPDATE WE
	SET WE.MatchedODSPersonID = MWP.PartyID
	FROM Roadside.vwMatchRoadsideParties MWP
	INNER JOIN Roadside.RoadsideEvents WE ON WE.MatchedODSVehicleID = MWP.VehicleID
	WHERE MWP.PartyType = 'P' -- Person
	AND (   WE.SurnameField1 = MWP.LastName							-- v1.2 / 1.3/ 1.4
		 OR (WE.SurnameField1 = ''  AND WE.CompanyName = '')		-- v1.2 / 1.3/ 1.4
		)
	AND WE.PerformNormalVWTLoadFlag = 'N'		-- v1.1

	-- UPDATE MATCHED ORGANISATION PartyIDs
	UPDATE WE
	SET WE.MatchedODSOrganisationID = MWP.PartyID
	FROM Roadside.vwMatchRoadsideParties MWP
	INNER JOIN Roadside.RoadsideEvents WE ON WE.MatchedODSVehicleID = MWP.VehicleID
	WHERE MWP.PartyType = 'O' -- Organisation
	AND (   WE.CompanyName = MWP.OrganisationName						-- v1.2 / 1.3/ 1.4
	     OR (WE.SurnameField1 = ''  AND WE.CompanyName = '')		-- v1.2 / 1.3/ 1.4
		)
	AND WE.PerformNormalVWTLoadFlag = 'N'		-- v1.1
	
	
	
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
