CREATE PROCEDURE IAssistance.uspMatchParties
AS

/*
	Purpose:	Uses view to return most appropriate party relating to matched vehicle that has not already been transferred to VWT
	
	Version			Date			Developer			Comment
	1.0				2018-10-23		Chris Ledger		Created from Roadside.uspMatchParties
																	
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- UPDATE MATCHED PERSON PartyIDs
	UPDATE IE
	SET IE.MatchedODSPersonID = MIP.PartyID
	FROM IAssistance.vwMatchIAssistanceParties MIP
	INNER JOIN IAssistance.IAssistanceEvents IE ON IE.MatchedODSVehicleID = MIP.VehicleID
	WHERE MIP.PartyType = 'P' -- Person
	AND (   IE.SurnameField1 = MIP.LastName							
		 OR (IE.SurnameField1 = ''  AND IE.CompanyName = '')		
		)
	AND IE.PerformNormalVWTLoadFlag = 'N'

	-- UPDATE MATCHED ORGANISATION PartyIDs
	UPDATE IE
	SET IE.MatchedODSOrganisationID = MIP.PartyID
	FROM IAssistance.vwMatchIAssistanceParties MIP
	INNER JOIN IAssistance.IAssistanceEvents IE ON IE.MatchedODSVehicleID = MIP.VehicleID
	WHERE MIP.PartyType = 'O' -- Organisation
	AND (   IE.CompanyName = MIP.OrganisationName
	     OR (IE.SurnameField1 = ''  AND IE.CompanyName = '')
		)
	AND IE.PerformNormalVWTLoadFlag = 'N'
	
	
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