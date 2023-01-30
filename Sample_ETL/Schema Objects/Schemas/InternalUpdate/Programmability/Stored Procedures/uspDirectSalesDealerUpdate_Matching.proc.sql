CREATE PROCEDURE [InternalUpdate].[uspDirectSalesDealerUpdate_Matching]
			
	@MarketCode  VARCHAR(3)

AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	SET DATEFORMAT DMY
	
	
	DECLARE @CountryID [dbo].[CountryID]

	--CONVERT THE HANDOVER DATE (SALE DATE)
	UPDATE	InternalUpdate.DirectSalesDealerUpdate
	SET		ConvertedHandoverDate = CONVERT( DATETIME, [CUSTOMER HANDOVER DATE])
	WHERE	ISDATE ([CUSTOMER HANDOVER DATE]) = 1



	--POPULATE THE COUNTRYID	
	SELECT @CountryID = CountryID FROM [$(SampleDB)].[ContactMechanism].[Countries] WHERE [ISOAlpha3] = @MarketCode
	
	UPDATE	InternalUpdate.DirectSalesDealerUpdate
	SET		CountryID = @CountryID

	--POPULATE THE ManufacturerPartyID
	UPDATE		DSDU
	SET			[ManufacturerPartyID] = BR.[ManufacturerPartyID]
	FROM		InternalUpdate.DirectSalesDealerUpdate	DSDU 
	INNER JOIN	[$(SampleDB)].[dbo].[Brands]					BR ON	CASE DSDU.Brand 
																	WHEN 'SAJ' THEN 'Jaguar'
																	WHEN 'SAL' THEN 'Land Rover'
																END = BR.[Brand]
													

	--POPULATE THE DEALERID (USING CountryID & ManufacturerID/ManfucturerPartyID)
	UPDATE		V
	SET			V.SalesDealerID = D.DealerID
	FROM
	(	
		--LOSE THE LEADING ZEROS
		SELECT	DealerID, RoleTypeIDFrom, PartyIDTo, RoleTypeIDTo, PartyRelationshipTypeID, CountryID,
					CASE
						WHEN ISNUMERIC(DealerCode) = 1 THEN CONVERT(VARCHAR,CONVERT(BIGINT,DealerCode))
						ELSE DealerCode
					END AS DealerCode
		FROM	Match.vwDealers
	) D
	INNER JOIN	InternalUpdate.DirectSalesDealerUpdate		V	ON	CASE 
																		WHEN ISNUMERIC(V.[FINAL DESTINATION CODE]) = 1 THEN CONVERT(VARCHAR,CONVERT(BIGINT,V.[FINAL DESTINATION CODE]))
																		ELSE V.[FINAL DESTINATION CODE]
																	END = D.DealerCode
	INNER JOIN	[$(SampleDB)].[Event].[EventTypeCategories]		etc ON	etc.EventTypeID				= (SELECT[EventTypeID] FROM [$(SampleDB)].[Event].[EventTypes] WHERE  EventType = 'Sales')
	INNER JOIN	[$(SampleDB)].[Event].[EventCategories]			ec	ON	ec.EventCategoryID			= etc.EventCategoryID 
																								AND ec.EventCategory IN ('Sales')
	WHERE		D.PartyIDTo = V.[ManufacturerPartyID]
				AND D.RoleTypeIDFrom IN (SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes)  -- SALES DEALER
				AND (D.CountryID = V.CountryID)
				AND ISNULL(V.SalesDealerID, 0) = 0


	
	--VIN MATCHING; MATCH VEHICLEID'S BY VIN'S WE'VE ALREADY LOADED
	UPDATE		VV
	SET			VV.MatchedODSVehicleID	= OV.VehicleID
	FROM		InternalUpdate.DirectSalesDealerUpdate	VV
	INNER JOIN	[$(SampleDB)].Vehicle.vwVehicles				OV ON	VV.VIN =	OV.VehicleChecksum
																		AND VV.ManufacturerPartyID = OV.ManufacturerID
	WHERE		ISNULL(VV.MatchedODSVehicleID, 0) = 0

	
	--EVENT MATCHING
	; WITH LoadedEvents AS (
			SELECT DISTINCT
				E.EventID, 
				E.EventTypeID, 
				COALESCE(E.EventDate, R.RegistrationDate) AS EventDate, 
				EPR.PartyID AS DealerID,
				VPRE.VehicleID
			FROM [$(SampleDB)].Event.Events E
			INNER JOIN [$(SampleDB)].Vehicle.VehiclePartyRoleEvents VPRE ON E.EventID = VPRE.EventID
			LEFT JOIN [$(SampleDB)].Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
			LEFT JOIN [$(SampleDB)].Vehicle.VehicleRegistrationEvents VRE
			INNER JOIN [$(SampleDB)].Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID
			ON VPRE.VehicleID = VRE.VehicleID AND VPRE.EventID = VRE.EventID
			WHERE E.EventTypeID IN (SELECT EventTypeID From [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Sales')
		)
		,CTE_AllowsEventMatching															-- v1.2
		AS (
			SELECT		v.ID, ISNULL(bmq.BypassEventMatching, 0) AS BypassEventMatching 
			FROM		InternalUpdate.DirectSalesDealerUpdate	v
			INNER JOIN [$(SampleDB)].dbo.brands						b	ON b.manufacturerPartyID	= v.manufacturerPartyID
			INNER JOIN [$(SampleDB)].[dbo].[Markets]				m	ON m.CountryID				= v.CountryID
			INNER JOIN [$(SampleDB)].[Event].[EventTypeCategories]	etc ON etc.EventTypeID			= (SELECT[EventTypeID] FROM [$(SampleDB)].[Event].[EventTypes] WHERE  EventType = 'Sales')
			INNER JOIN [$(SampleDB)].[Event].[EventCategories]		ec	ON ec.EventCategoryID		= etc.EventCategoryID
			INNER JOIN [$(SampleDB)].[dbo].[Questionnaires]			q	ON q.Questionnaire			= ec.EventCategory
			INNER JOIN [$(SampleDB)].dbo.BrandMarketQuestionnaireMetadata bmq ON bmq.BrandID			= b.BrandID
																								  AND bmq.MarketID = m.MarketID
																								  AND bmq.QuestionnaireId = q.QuestionnaireID 
																								  AND bmq.SelectionOutputActive = 1   -- to ensure we do not pick up Enprecis, etc
																								  AND ISNULL(bmq.BypassEventMatching, 0) = 0 -- Only recs where ByPassEventMatching is set OFF
		)
		UPDATE		V
		SET			V.MatchedODSEventID = LE.EventID
		FROM		InternalUpdate.DirectSalesDealerUpdate	V
		INNER JOIN	LoadedEvents							LE ON v.ConvertedHandoverDate		=	LE.EventDate
																									AND V.MatchedODSVehicleID = LE.VehicleID

		INNER JOIN	CTE_AllowsEventMatching am ON am.ID = v.ID	
		WHERE		LE.EventTypeID = (SELECT[EventTypeID] FROM [$(SampleDB)].[Event].[EventTypes] WHERE  EventType = 'Sales')
					AND LE.DealerID IS NULL 


END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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