CREATE PROCEDURE [Enprecis].[uspCQIGetSelectionOutput]
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

/*
	Purpose:	Produces on-line output for CQI pilot  
		
	Version			Date				Developer			Comment
	1.0				08/04/2016			Chris Ledger		Created
	1.1				09/09/2016			Chris Ross			BUG 12584 - Update to allow all countries not just "AUS" Australia.
	1.2				22/01/2020			Chris Ledger		Bug 15372 - Fix database references and cases
	1.3 			12/03/2020			Ben King			BUG 18000 - Map Business Region to 'blank' variable.
*/

	-------------------------------------------------------------------
	-- SCRIPT FOR CQI OUTPUT TAKEN FROM [SelectionOutput].[uspRunOutput], [SelectionOutput].[uspPopulateOnlineFile] & [SelectionOutput].[uspOnlineEmailContactDetails]
	-------------------------------------------------------------------

	-------------------------------------------------------------------
	-- GET ALL SelectionRequirementIDs FROM Requirement.SelectionCases FOR CaseIDs
	-------------------------------------------------------------------

	IF (OBJECT_ID('tempdb..#SelectionRequirementIDs') IS NOT NULL)
	BEGIN
		DROP TABLE #SelectionRequirementIDs
	END

	CREATE TABLE #SelectionRequirementIDs
	(
		[ID] INT IDENTITY(1,1) NOT NULL,
		SelectionRequirementID INT
	)

	INSERT INTO #SelectionRequirementIDs
	SELECT DISTINCT R1.RequirementID AS 'SelectionRequirementID'
	FROM Requirement.Requirements R
	INNER JOIN Requirement.RequirementRollups RR ON R.RequirementID = RR.RequirementIDPartOf
	INNER JOIN Requirement.Requirements R1 ON RR.RequirementIDMadeUpOf = R1.RequirementID
	INNER JOIN Requirement.SelectionCases SC ON SC.RequirementIDPartOf = RR.RequirementIDMadeUpOf
	INNER JOIN Enprecis.CQISelectionCases CQI ON SC.CaseID = CQI.CaseID
	WHERE R.RequirementTypeID = 2
	AND R.Requirement LIKE '%ENP%2014%'    -- v1.1

	DECLARE @SelectionRequirementID INT
	DECLARE @Counter INT
	

	SET @Counter = 1

	
	------------------------------------------------------------------------------------
	-- LOOP THROUGH SELECTION REQUIREMENTIDS 
	------------------------------------------------------------------------------------
	WHILE @Counter <= (SELECT COUNT(*) FROM #SelectionRequirementIDs)
	BEGIN
		SELECT
			@SelectionRequirementID = SelectionRequirementID
		FROM #SelectionRequirementIDs WHERE [ID] = @Counter

		-- GET THE CASE DETAILS
		INSERT INTO SelectionOutput.Base
		(
			 PartyID
			,CaseID
			,ModelDescription
			,VIN
			,Manufacturer
			,RegistrationNumber
			,Title
			,FirstName
			,LastName
			,Addressee
			,Salutation
			,OrganisationName
			,PostalAddressContactMechanismID
			,BuildingName
			,SubStreet
			,Street
			,SubLocality
			,Locality
			,Town
			,Region
			,PostCode
			,Country
			,DealerCode				-- v1.1
			,DealerName
			,VersionCode
			,CountryID
			,ModelRequirementID
			,LanguageID
			,ManufacturerPartyID
			,GenderID
			,QuestionnaireVersion
			,EventTypeID
			,EventDate				-- v1.1
			,SelectionTypeID
			,EmailAddressContactMechanismID
			,EmailAddress
			,LandPhone			--v1.1
			,MobilePhone		--v1.1
			,WorkPhone			--v1.1
			,GDDDealerCode		--v1.3
			,ReportingDealerPartyID --v1.3
			,VariantID			--v1.3
			,ModelVariant		--v1.3
		)
		EXEC Event.uspGetSelectionCases @SelectionRequirementID			


		-- GET or SET the SelectionOutputPassword value --------------------- v1.2
		UPDATE b
		SET b.SelectionOutputPassword = CASE WHEN ISNULL(c.SelectionOutputPassword, '') <> ''
									       THEN c.SelectionOutputPassword
									       ELSE SelectionOutput.udfGeneratePassword()
									       END 
		FROM SelectionOutput.Base b
		INNER JOIN Event.Cases c ON c.CaseID = b.CaseID

		-- INCREMENT THE COUNTER
		SET @Counter = @Counter + 1

	END


	-------------------------------------------------------------------
	-- DELETE ROWS THAT DON'T EXIST IN Enprecis_CQISelectionCases
	-------------------------------------------------------------------
	DELETE FROM SelectionOutput.Base
	FROM SelectionOutput.Base B
	LEFT JOIN Enprecis.CQISelectionCases CQI ON B.CaseID = CQI.CaseID
	WHERE CQI.CaseID IS NULL

	
	---------------------------------------------------------------
	-- EMAIL OUTPUT WITH CHECKS FOR VALID EMAILS REMOVED
	---------------------------------------------------------------
	INSERT INTO SelectionOutput.Email
	(
		Password,
		[ID],
		FullModel,
		Model,
		VIN,
		sType,
		CarReg,
		Title,
		Initial,
		Surname,
		Fullname,
		DearName,
		CoName,
		Add1,
		Add2,
		Add3,
		Add4,
		Add5,
		Add6,
		Add7,
		Add8,
		Add9,
		CTRY,
		EmailAddress,
		Dealer,
		sno,
		ccode,
		modelcode,
		lang,
		manuf,
		gender,
		qver,
		blank,
		etype,
		reminder,
		[week],
		test,
		SampleFlag,
		SalesServiceFile,
		DealerCode,
		EventDate,
		LandPhone,
		WorkPhone,
		MobilePhone,
		PartyID,
		GDDDealerCode, --v1.3
		ReportingDealerPartyID, --v1.3
		VariantID, --v1.3
		ModelVariant -- v1.3
	)
	SELECT DISTINCT
		B.SelectionOutputPassword AS Password,
		B.CaseID AS [ID],
		B.ModelDescription AS FullModel,
		B.ModelDescription AS Model,
		B.VIN,
		B.Manufacturer AS sType,
		B.RegistrationNumber AS CarReg,
		B.Title,
		B.FirstName AS Initial,
		B.LastName AS Surname,
		B.Addressee AS Fullname,
		B.Salutation AS DearName,
		B.OrganisationName AS CoName,
		B.BuildingName AS Add1,
		B.SubStreet AS Add2,
		B.Street AS Add3,
		B.SubLocality AS Add4,
		B.Locality AS Add5,
		B.Town AS Add6,
		B.Region AS Add7,
		B.PostCode AS Add8,
		'' AS Add9,
		B.Country AS CTRY,
		B.EmailAddress,
		B.DealerName AS Dealer,
		B.VersionCode AS sno,
		B.CountryID AS ccode,
		B.ModelRequirementID AS modelcode,
		B.LanguageID AS lang,
		B.ManufacturerPartyID AS manuf,
		B.GenderID AS gender,
		B.QuestionnaireVersion AS qver,
		'' AS blank,
		B.EventTypeID AS etype,
		1 AS reminder,
		SelectionOutput.udfGetWeekNumber(GETDATE()) AS [week],
		0 AS test,
		1 AS SampleFlag,
		'' AS SalesServiceFile,
		B.DealerCode,
		B.EventDate,
		B.LandPhone,
		B.WorkPhone,
		B.MobilePhone,
		B.PartyID,
		B.GDDDealerCode, --v1.3
		B.ReportingDealerPartyID, --v1.3
		B.VariantID, --v1.3
		B.ModelVariant -- v1.3
	FROM SelectionOutput.Base B
	WHERE ISNULL(B.EmailAddressContactMechanismID, 0) > 0 


	--------------------------------------------------------------------------
	-- Clear down Base Table
	TRUNCATE TABLE SelectionOutput.Base
	--------------------------------------------------------------------------


	--------------------------------------------------------------------------
	-- POPULATE ONLINE FILE - COUNTRY IS AUSTRALIA
	--------------------------------------------------------------------------
	
	INSERT INTO SelectionOutput.OnlineOutput
	(
		[Password], 
		[ID], 
		[FullModel], 
		[Model],
		[VIN], 
		[sType], 
		[CarReg], 
		[Title], 
		[Initial], 
		[Surname], 
		[Fullname], 
		[DearName], 
		[CoName], 
		[Add1], 
		[Add2], 
		[Add3], 
		[Add4], 
		[Add5], 
		[Add6], 
		[Add7], 
		[Add8], 
		[Add9], 
		[CTRY], 
		[EmailAddress], 
		[Dealer], 
		[sno], 
		[ccode], 
		[modelcode], 
		[lang], 
		[manuf], 
		[gender], 
		[qver], 
		[blank], 
		[etype], 
		[reminder], 
		[week], 
		[test], 
		[SampleFlag], 
		[SalesServiceFile],
		[ITYPE],
		[Market],
		[Expired],
		EventDate,
		DealerCode,
		Telephone,
		WorkTel,
		MobilePhone,
		PartyID,
		GDDDealerCode,
		ReportingDealerPartyID,
		VariantID,
		ModelVariant,
		CATIType
	)
	SELECT
		SO.[Password], 
		SO.[ID], 
		SO.[FullModel], 
		SO.[Model], 
		SO.[VIN],
		SO.[sType], 
		SO.[CarReg], 
		SO.[Title], 
		SO.[Initial], 
		SO.[Surname], 
		SO.[Fullname], 
		SO.[DearName], 
		SO.[CoName], 
		SO.[Add1], 
		SO.[Add2], 
		SO.[Add3], 
		SO.[Add4], 
		SO.[Add5], 
		SO.[Add6], 
		SO.[Add7], 
		SO.[Add8], 
		SO.[Add9], 
		SO.[CTRY], 
		SO.[EmailAddress], 
		SO.[Dealer], 
		SO.[sno], 
		SO.[ccode], 
		SO.[modelcode], 
		SO.[lang], 
		SO.[manuf], 
		SO.[gender], 
		SO.[qver], 
		SO.[blank], 
		SO.[etype], 
		SO.[reminder], 
		SO.[week], 
		SO.[test], 
		SO.[SampleFlag], 
		SO.[SalesServiceFile],
		'H' AS [ITYPE],
		BMQ.ISOAlpha3,
		DATEADD(D, BMQ.NumDaysToExpireOnlineQuestionnaire, DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)) AS Expired,
		SO.EventDate,
		SO.DealerCode,
		LandPhone,
		WorkPhone,
		MobilePhone,
		SO.PartyID,
		SO.GDDDealerCode,
		SO.ReportingDealerPartyID,
		SO.VariantID,
		SO.ModelVariant,
		0 AS CATIType
	FROM SelectionOutput.Email SO
	INNER JOIN Requirement.SelectionCases SC ON SC.CaseID = SO.ID
	INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = SC.CaseID
	INNER JOIN Event.Events E ON E.EventID = AEBI.EventID
	INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
	LEFT  JOIN SelectionOutput.SelectionsToOutput O ON O.SelectionRequirementID = SC.RequirementIDPartOf
	INNER JOIN dbo.vwBrandMarketQuestionnaireSampleMetadata BMQ ON BMQ.Brand = SO.sType
																AND BMQ.ISOAlpha3 = 'AUS'
																AND BMQ.Questionnaire = ET.EventCategory
	WHERE ISNULL(BMQ.IncludeEmailOutputInAllFile, 0) = 1


	--------------------------------------------------------------------------
	-- Add in additional information required for On-line    -- v1.3
	UPDATE o
	SET		ManufacturerDealerCode = f.ManufacturerDealerCode, 
			ModelYear = MY.ModelYear , 
			CustomerIdentifier = cr.CustomerIdentifier, 
			OwnershipCycle  = cd.OwnershipCycle ,
			OutletPartyID = cd.DealerPartyID,					--v1.4
			blank = ISNULL(f.BusinessRegion,'')							--v1.10
	from SelectionOutput.OnlineOutput o
	inner join Meta.CaseDetails cd on cd.CaseID = o.id
	inner join Event.EventTypeCategories etc on etc.EventTypeID = etype 
	inner join Event.EventCategories ec on etc.EventCategoryID = ec.EventCategoryID
	left join [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Flat f
								on f.DealerCode = o.dealercode
								and f.OutletPartyID = cd.DealerPartyID 
								and f.OutletFunction = case ec.EventCategory 
														when 'Service' then 'Aftersales'
														else ec.EventCategory 
														end
							--	and f.ManufacturerDealerCode is not null   -- v1.9
	LEFT JOIN [Vehicle].ModelYear MY ON MY.VINCharacter = SUBSTRING(o.VIN , MY.VINPosition , 1) AND cd.ManufacturerPartyID = MY.ManufacturerPartyID
	LEFT join [$(AuditDB)].Audit.CustomerRelationships cr on cr.PartyIDFrom = cd.PartyID 
								and cr.CustomerIdentifierUsable = 1 
								and cr.AuditItemID = (Select MAX(AuditItemID) 
															from  [$(AuditDB)].Audit.CustomerRelationships cr2 
															where cr2.PartyIDFrom = cr.PartyIDFrom 
															and cr2.CustomerIdentifierUsable = cr.CustomerIdentifierUsable
													  )
	--------------------------------------------------------------------------
	--V1.3
	--UPDATE BusinessRegion for All other questionnaires not within Dealer Hierarchy.
	--NB: BusinessRegion is unique to Market
	UPDATE	O
	SET		blank = ISNULL(F.BusinessRegion,'')
	FROM	SelectionOutput.OnlineOutput O
	INNER JOIN dbo.markets M ON M.Market = O.CTRY
	INNER JOIN [$(ETLDB)].DealerManagement.DEALERS_JLRCSP_Flat F ON F.Market = COALESCE(m.DealerTableEquivMarket, M.Market)
	WHERE	ISNULL(blank,'') = ''

	--------------------------------------------------------------------------
	-- Clear down Email Table
	TRUNCATE TABLE SelectionOutput.Email
	--------------------------------------------------------------------------


	------------------------------------------------------------------
	-- Update Email Contact Details 
	EXEC SelectionOutput.uspOnlineEmailContactDetails
	------------------------------------------------------------------
	

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