CREATE PROCEDURE Warranty.uspLoadToVWT
AS

/*
	Purpose:	Transfers rows to VWT from WarrantyEvents that have matched Vehicles / Parties and have not previously been transferred
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspVWTLOAD_TransferWarranty
	1.1				29/04/2014		Ali Yuksel			Bug 10289: MatchedODSModelID added 

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO dbo.VWT 
	(
		WarrantyID, 
		AuditID, 
		PhysicalFileRow, 
		ManufacturerID, 
		SampleSupplierPartyID, 
		ODSEventTypeID, 
		MatchedODSVehicleID, 
		MatchedODSModelID,
		MatchedODSPersonID, 
		MatchedODSOrganisationID, 
		ServiceDealerCodeOriginatorPartyID, 
		ServiceDealerCode, 
		ServiceDateOrig, 
		ServiceDate,
		CountryID
	)
	SELECT 
		WarrantyID,
		AuditID,
		PhysicalFileRow,
		ManufacturerID,
		SampleSupplierPartyID,
		EventTypeID,
		MatchedODSVehicleID,
		MatchedODSModelID,
		MatchedODSPersonID,
		MatchedODSOrganisationID,
		ServiceDealerCodeOriginatorPartyID,
		ServiceDealerCode,
		ServiceDateOrig,
		ServiceDate,
		CountryID
	FROM Warranty.vwLoadToVWT
	ORDER BY WarrantyID
	
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