CREATE PROCEDURE [SelectionOutput].[uspAuditTelephoneCombinedOutput]
@FileName VARCHAR (255), 
@Brand VARCHAR(255), 
@Questionnaire VARCHAR(255), 
@Ctry VARCHAR(255), 
@Agency VARCHAR(255)

AS
/*

	Purpose:	Audits Telephone Combined Output"
		
	Version			Date			Developer			Comment
	1.2	(?)			2018-03-08		Chris Ledger		BUG 14272: Ensure all fields from CATICLP auditted
	1.3				2018-03-13		Chris Ross			BUG 14413: Fix to look up LLA using GDDDealerCode not DealerCode. Fixed as part of Bluefin bug.
	1.4				2018-09-27		Eddie Thomas		BUG 14820: Lost Leads - Global loader change
	1.5				2019-10-30		Eddie Thomas		BUG 16667: Add HotTopicCodes field and PHEV flags 
	1.6				2020-01-21		Chris Ledger		BUG 15372: Fix Hard coded references to databases.
	1.7				2020-03-13		Chris Ledger		BUG 16891: Add ServiceEventType
*/
SET NOCOUNT ON
SET DATEFORMAT DMY

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		-- CREATE A TEMP TABLE TO HOLD EACH TYPE OF OUTPUT
		CREATE TABLE #OutputtedSelections
		(
			PhysicalRowID INT IDENTITY(1,1) NOT NULL,
			AuditID INT NULL,
			AuditItemID INT NULL,
			CaseID INT NULL,
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, CaseOutputTypeID)
		SELECT DISTINCT
			C.ID as CaseID, 
			(SELECT CaseOutputTypeID FROM Event.CaseOutputTypes WHERE CaseOutputType = 'CATI') AS CaseOutputTypeID
		FROM SelectionOutput.CATICLP	C
		INNER JOIN dbo.Markets	MK ON C.ccode		= MK.CountryID
		INNER JOIN dbo.Regions	RG ON MK.RegionID	= RG.RegionID
		INNER JOIN ContactMechanism.Countries CO ON MK.CountryID = CO.CountryID
		LEFT JOIN [$(ETLDB)].Lookup.LostLeadsAgencyStatus LLR ON C.GDDDealerCode = LLR.CICode
															AND LLR.Market = CO.ISOAlpha2
		LEFT JOIN SelectionOutput.LostLeadAgencies LLA ON LLR.LostSalesProvider = LLA.Agency
		WHERE C.DateOutput IS NULL 
		AND	(C.Brand = @Brand OR 'All Brands' = @Brand) 
		AND	(C.Questionnaire = @Questionnaire)
		AND	(C.CTRY = @Ctry) 
		AND	(LLA.AgencyShortName = @Agency OR (LLA.Agency IS NULL AND 'NA' = @Agency))
			
			
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			
			INSERT INTO [$(AuditDB)].Audit.SelectionOutput
			(
				[AuditID], 
				[AuditItemID], 
				[SelectionOutputTypeID], 				
				[Add1], 
				[Add2], 
				[Add3], 
				[Add4], 
				[Add5], 
				[Add6], 
				[Add7], 
				[Add8], 
				[Add9], 
				[AssignedMode], 
				[blank], 
				[Brand], 
				[CallOutcome], 
				[CallRecordingsCount], 
				[CarReg], 
				[CATIType], 
				[ccode], 
				[CoName], 
				[CTRY], 
				[CustomerIdentifier], 
				[DateOutput], 
				[Dealer], 
				[DealNo], 
				[DearName], 
				[EmailAddress], 
				[EmployeeName], 
				[etype], 
				[EventDate], 
				[ExpirationTime], 
				[Expired], 
				[FileDate], 
				[FOBCode], 
				[FullModel], 
				[Fullname], 
				[GDDDealerCode], 
				[gender], 
				[HomePhoneNumber], 
				[CaseID], 
				[Initial], 
				[ITYPE], 
				[lang], 
				[Language], 
				[manuf], 
				[ManufacturerDealerCode], 
				[Market], 
				[MobilePhone], 
				[MobilePhoneNumber], 
				[Model], 
				[modelcode], 
				[ModelVariant], 
				[ModelYear], 
				[OutletPartyID], 
				[OwnershipCycle], 
				[PartyID], 
				[Password], 
				[PhoneNumber], 
				[PhoneSource], 
				[Questionnaire], 
				[Queue], 
				[qver], 
				[reminder], 
				[ReportingDealerPartyID], 
				[RequiresManualDial], 
				[SalesServiceFile],
				[SampleFlag], 
				[sno], 
				[sType], 
				[Surname], 
				[URL], 
				[SVOvehicle], 
				[Telephone], 
				[test], 
				[TimeZone], 
				[Title], 
				[VariantID], 
				[VIN], 
				[week], 
				[WorkPhone], 
				[WorkPhoneNumber],
				[Agency],
				[JLREventType],							-- V1.4
				[LostLead_DateOfLeadCreation],			-- V1.4
				[LostLead_CompleteSuppressionJLR],		-- V1.4	
				[LostLead_CompleteSuppressionRetailer],	-- V1.4	
				[LostLead_PermissionToEmailJLR],		-- V1.4			
				[LostLead_PermissionToEmailRetailer],	-- V1.4	
				[LostLead_PermissionToPhoneJLR],		-- V1.4			
				[LostLead_PermissionToPhoneRetailer],	-- V1.4	
				[LostLead_PermissionToPostJLR],			-- V1.4			
				[LostLead_PermissionToPostRetailer],	-- V1.4		
				[LostLead_PermissionToSMSJLR],			-- V1.4			
				[LostLead_PermissionToSMSRetailer],		-- V1.4		
				[LostLead_PermissionToSocialMediaJLR],	-- V1.4	
				[LostLead_PermissionToSocialMediaRetailer],	-- V1.4
				[LostLead_DateOfLastContact],			-- V1.4
				[HotTopicCodes],						-- V1.5	
				[ServiceEventType]						-- V1.6
			)
			
			SELECT DISTINCT
				O.[AuditID], 
				O.[AuditItemID], 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'CATI') AS [SelectionOutputTypeID],				
				S.[Add1], 
				S.[Add2], 
				S.[Add3], 
				S.[Add4], 
				S.[Add5], 
				S.[Add6], 
				S.[Add7], 
				S.[Add8], 
				S.[Add9], 
				S.[AssignedMode], 
				S.[blank], 
				S.[Brand], 
				S.[CallOutcome], 
				S.[CallRecordingsCount], 
				S.[CarReg], 
				S.[CATIType], 
				S.[ccode], 
				S.[CoName], 
				S.[CTRY], 
				S.[CustomerIdentifier], 
				S.[DateOutput], 
				S.[Dealer], 
				S.[DealerCode], 
				S.[DearName], 
				S.[EmailAddress], 
				S.[EmployeeName], 
				S.[etype], 
				S.[EventDate], 
				S.[ExpirationTime], 
				S.[Expired], 
				S.[FileDate], 
				S.[FOBCode],
				S.[FullModel], 
				S.[Fullname], 
				S.[GDDDealerCode], 
				S.[gender], 
				S.[HomePhoneNumber], 
				S.[ID], 
				S.[Initial], 
				S.[ITYPE], 
				S.[lang], 
				S.[Language],
				S.[manuf], 
				S.[ManufacturerDealerCode], 
				S.[Market], 
				S.[MobilePhone], 
				S.[MobilePhoneNumber], 
				S.[Model], 
				S.[modelcode], 
				S.[ModelVariant], 
				S.[ModelYear], 
				S.[OutletPartyID], 
				S.[OwnershipCycle], 
				S.[PartyID], 
				S.[Password], 
				S.[PhoneNumber], 
				S.[PhoneSource], 
				S.[Questionnaire], 
				S.[Queue], 
				S.[qver], 
				S.[reminder], 
				S.[ReportingDealerPartyID], 
				S.[RequiresManualDial], 
				S.[SalesServiceFile], 
				S.[SampleFlag], 
				S.[sno], 
				S.[sType], 
				S.[Surname], 
				S.[SurveyURL], 
				S.[SVOvehicle], 
				S.[Telephone], 
				S.[test], 
				S.[TimeZone], 
				S.[Title], 
				S.[VariantID], 
				S.[VIN], 
				S.[week], 
				S.[WorkPhoneNumber], 
				S.[WorkTel],
				@Agency,
				S.[JLREventType],							-- V1.4
				S.[LostLead_DateOfLeadCreation],			-- V1.4
				S.[LostLead_CompleteSuppressionJLR],		-- V1.4		
				S.[LostLead_CompleteSuppressionRetailer],	-- V1.4	
				S.[LostLead_PermissionToEmailJLR],			-- V1.4			
				S.[LostLead_PermissionToEmailRetailer],		-- V1.4	
				S.[LostLead_PermissionToPhoneJLR],			-- V1.4			
				S.[LostLead_PermissionToPhoneRetailer],		-- V1.4	
				S.[LostLead_PermissionToPostJLR],			-- V1.4			
				S.[LostLead_PermissionToPostRetailer],		-- V1.4		
				S.[LostLead_PermissionToSMSJLR],			-- V1.4			
				S.[LostLead_PermissionToSMSRetailer],		-- V1.4		
				S.[LostLead_PermissionToSocialMediaJLR],	-- V1.4	
				S.[LostLead_PermissionToSocialMediaRetailer],-- V1.4
				S.[LostLead_DateOfLastContact],				-- V1.4	
				S.[HotTopicCodes],							-- V1.5
				S.[ServiceEventType]						-- V1.7
			FROM #OutputtedSelections O
			INNER JOIN SelectionOutput.CATICLP S ON O.CaseID = S.ID
			WHERE S.DateOutput IS NULL
			ORDER BY O.AuditItemID

		END

		-- DROP THE TEMPORARY TABLE
		DROP TABLE #OutputtedSelections
		
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH


GO