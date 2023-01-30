CREATE PROCEDURE [Load].[uspDeDuplicateLostLeadEvents]

/*
	Purpose:	Check for Multiple Events on Same Date for someone with different models.
				Set Model to most recently created lost lead.
	
	Version		Date			Developer			Comment
	1.0			05/05/2017		Chris Ledger		BUG 13897 - Created
	1.1			27/03/2018		Eddie Thomas		BUG 14631 - LostLead dupes roll-up - SalesMan name not being rolled up
	1.2			20/10/2018		Chris Ledger		BUG 15056 - Add IAssistance
	1.3			01/10/2019		Chris Ledger		BUG 15490 - Add PreOwned LostLeads
	
*/

AS

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	--------------------------------------------------------------------------------------------------------------------
	-- CREATE TEMPORARY
	--------------------------------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#DistinctLostLeadEvents') IS NOT NULL
		DROP TABLE #DistinctLostLeadEvents
	CREATE TABLE #DistinctLostLeadEvents
	(
		AuditItemID BIGINT,
		MatchedODSEventID BIGINT,
		LostLeadDate DATETIME2(7),
		LostLead_DateOfLeadCreationOrig VARCHAR(30),
		ODSEventTypeID BIGINT,
		PartyID BIGINT,
		DealerID BIGINT,
		RowID BIGINT,
		Salesman NVARCHAR(400)
	)


	--------------------------------------------------------------------------------------------------------------------
	-- GET THE AuditItemID OF LOST LEADS EVENT WE WANT TO KEEP FOR PERSON (I.E. RowID = 1)
	--------------------------------------------------------------------------------------------------------------------
	INSERT INTO #DistinctLostLeadEvents (AuditItemID, MatchedODSEventID, LostLeadDate, LostLead_DateOfLeadCreationOrig, ODSEventTypeID, PartyID, DealerID, RowID, Salesman)
	SELECT	
		AuditItemID,
		MatchedODSEventID, 
		LostLeadDate, 
		ISNULL(LostLead_DateOfLeadCreationOrig,'01/01/1900') AS LostLead_DateOfLeadCreationOrig,
		ODSEventTypeID, 
		COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), 0) AS PartyID,
		COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), NULLIF(RoadsideNetworkPartyID, 0), NULLIF(CRCCentrePartyID, 0), NULLIF(IAssistanceCentrePartyID, 0), 0) AS DealerID,
		ROW_NUMBER() OVER (PARTITION BY 	MatchedODSEventID, 
							COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), 0),
							ODSEventTypeID, 
							LostLeadDate, 
							COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), NULLIF(RoadsideNetworkPartyID, 0), NULLIF(CRCCentrePartyID, 0), NULLIF(IAssistanceCentrePartyID, 0), 0)
							ORDER BY CONVERT( DATETIME, ISNULL(LostLead_DateOfLeadCreationOrig,'01/01/1900'),103) DESC, AuditItemID ASC) AS RowID,
		Salesman
	FROM dbo.VWT V
	WHERE ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = ('LostLeads'))
	OR ODSEventTypeID = (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = ('PreOwned LostLeads'))		-- V1.3
	ORDER BY V.MatchedODSEventID, 
	COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), 0),
	V.ODSEventTypeID, 
	V.LostLeadDate, 
	COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), NULLIF(RoadsideNetworkPartyID, 0), NULLIF(CRCCentrePartyID, 0), NULLIF(IAssistanceCentrePartyID, 0), 0)	
	--------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------------------------------------
	-- UPDATE EventParentAuditItemID FOR ALL LostLead ROWS
	--------------------------------------------------------------------------------------------------------------------
	UPDATE V SET V.EventParentAuditItemID = DLLE.AuditItemID
	FROM dbo.VWT V
	INNER JOIN #DistinctLostLeadEvents DLLE ON V.MatchedODSEventID = DLLE.MatchedODSEventID
			AND V.LostLeadDate = DLLE.LostLeadDate
			AND V.ODSEventTypeID = DLLE.ODSEventTypeID
			AND COALESCE(NULLIF(V.MatchedODSPersonID, 0), NULLIF(V.MatchedODSOrganisationID, 0), 0) = DLLE.PartyID
			AND COALESCE(NULLIF(V.SalesDealerID, 0), NULLIF(V.ServiceDealerID, 0), NULLIF(V.RoadsideNetworkPartyID, 0), NULLIF(V.CRCCentrePartyID, 0), NULLIF(V.IAssistanceCentrePartyID, 0), 0) = DLLE.DealerID
	WHERE DLLE.RowID = 1
	--------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------------------------------------
	-- UPDATE ALL OTHER ROWS
	--------------------------------------------------------------------------------------------------------------------
	UPDATE V SET V.EventParentAuditItemID = V.AuditItemID
	FROM dbo.VWT V
	WHERE V.EventParentAuditItemID IS NULL
	--------------------------------------------------------------------------------------------------------------------


	--------------------------------------------------------------------------------------------------------------------
	-- UPDATE LostLead_DateOfLeadCreation, Vehicle AND Model OF CHILDREN WITH PARENT
	--------------------------------------------------------------------------------------------------------------------
	UPDATE V SET V.LostLead_DateOfLeadCreation = VL.LostLead_DateOfLeadCreationOrig,
	V.MatchedODSVehicleID = VL.MatchedODSVehicleID,
	V.VehicleIdentificationNumber = (SELECT DISTINCT VIN FROm [$(SampleDB)].Vehicle.Vehicles WHERE VehicleID = VL.MatchedODSVehicleID),
	V.MatchedODSModelID = VL.MatchedODSModelID,
	V.Salesman = VL.Salesman
	FROM dbo.VWT V
	INNER JOIN (
		SELECT *
		FROM dbo.VWT
	) VL ON V.EventParentAuditItemID = VL.AuditItemID
	--------------------------------------------------------------------------------------------------------------------

	
	
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


GO