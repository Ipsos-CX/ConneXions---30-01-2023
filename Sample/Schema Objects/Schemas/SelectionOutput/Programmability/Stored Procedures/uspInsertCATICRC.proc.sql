CREATE PROC SelectionOutput.uspInsertCATICRC
(
	@Brand NVARCHAR(510),
	@Market VARCHAR(200),
	@Questionnaire VARCHAR(255)
)
AS

/*
	Purpose:	Insert Data into SelectionOutput.CATICRC Table
	
	Version			Date			Developer			Comment
	1.0				2019-11-07		Chris Ledger		Bug 15191 - New SP from Insert Into CATICRC SQL Task (Selection Output package)  
	1.1				2021-03-26		Eddie Thomas		BUG 18144 - New CRC Agent Look up
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	;WITH CTE_DeDuped_Events (EventID, AuditItemID)
	AS 
	 (
	  SELECT ODSEventID , MAX(AuditItemID)
	  from Sample_ETL.CRC.CRCEvents
	  GROUP BY ODSEventID
	 )
	INSERT INTO SelectionOutput.CATICRC
	(GfKPartyID, ID, EventDate, fullModel, Model, SType, Carreg, Title, Initial, Surname, CoName, add1, add2, add3, add4, add5, add6, add7, add8, add9, CTRY, EmailAddress, MobilePhone, 
	Telephone, Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, surveyscale, etype, reminder, week, test, sampleflag, CRCsurveyfile, ITYPE, Owner, Password, SRNumber, SampleYear, 
	SampleMonth, CompletionDate, CRCCode, MarketCode, ContactId, AssetId, CustomerLanguageCode, CustomerUniqueId, VehicleAge, VIN, VehicleDerivative, VehicleMileage, VehicleMonthsinService, 
	CustomerFirstName, RowId, ResponseDate, OwnerType, Brand, Market, Questionnaire, Queue, AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome,
	PhoneNumber,PhoneSource,Language,ExpirationTime,HomePhoneNumber,WorkPhoneNumber,MobilePhoneNumber, SVOvehicle,FOBCode)
	
	SELECT DISTINCT
	O.PartyID AS GfKPartyID,
	O.ID,
	CAST(replace(convert(varchar(10), O.EventDate, 102), '.', '-') AS VARCHAR(10)) AS EventDate, 
	O.fullModel,
	O.Model,
	O.SType,
	O.Carreg,
	O.Title,
	O.Initial,
	O.Surname,
	O.CoName,
	O.add1,
	O.add2,
	O.add3,
	O.add4,
	O.add5,
	O.add6,
	O.add7,
	O.add8,
	O.add9,
	O.CTRY,
	O.EmailAddress,
	O.MobilePhone,
	O.Telephone, 
	ISNULL(O.dealer, '') AS Dealer,
	O.sno,
	O.ccode,
	O.modelcode,
	O.lang,
	O.manuf,
	O.gender,
	O.qver,
	blank AS surveyscale,
	O.etype,
	O.reminder,
	O.week,
	O.test,
	O.sampleflag,
	O.SalesServiceFile AS CRCsurveyfile,
	'' AS ITYPE,
	--CASE WHEN LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBy ELSE CRC.Owner END AS Owner,  -- BUG 11949 Output Owner field if ClosedBy is blank
	--CASE
	-- WHEN LK.CODE IS NOT NULL THEN LK.FirstName -- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
	-- WHEN LK.CODE IS NULL AND LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBY
	-- ELSE CRC.Owner
	--END AS Owner,
	CASE
		WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
		WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
		ELSE CRC.[Owner]                                                                                                                                                                                                                  
	END AS Owner,						--V1.1
	O.Password,
	CRC.CaseNumber AS SRNumber,
	CAST(DATEPART(YEAR, O.EventDate) AS VARCHAR(4)) AS SampleYear,
	CAST(DATEPART(MM, O.EventDate) AS VARCHAR(4)) AS SampleMonth,
	'' AS CompletionDate,
	CRC.CRCCode,
	CRC.MarketCode,
	'' AS ContactId,
	'' AS AssetId,
	ISNULL(l.ISOAlpha3, '') AS CustomerLanguageCode,
	CRC.UniqueCustomerId AS CustomerUniqueId,
	'' AS VehicleAge,
	O.VIN,
	CRC.VehicleDerivative,
	CRC.VehicleMileage,
	CRC.VehicleMonthsinService,
	CRC.CustomerFirstName,
	CRC.RowId,
	'' AS ResponseDate,
	--CASE WHEN LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBy ELSE CRC.Owner END AS Owner,  -- BUG 11949 Output Owner field if ClosedBy is blank
	--CASE
	-- WHEN LK.CODE IS NOT NULL THEN LK.FirstName -- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
	-- WHEN LK.CODE IS NULL AND LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBY
	-- ELSE CRC.Owner
	--END AS OwnerType,
	CASE
		WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
		WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
		ELSE CRC.[Owner]                                                                                                                                                                                                                  
	END AS OwnerType,		--V1.1
	@Brand AS Brand,
	@Market AS Market,
	@Questionnaire AS Questionnaire,
	O.Queue,
	O.AssignedMode, 
	O.RequiresManualDial,
	O.CallRecordingsCount,
	O.TimeZone,
	O.CallOutcome, 
	O.PhoneNumber, 
	O.PhoneSource, 
	O.Language,
	O.ExpirationTime,
	O.HomePhoneNumber,
	O.WorkPhoneNumber,
	O.MobilePhoneNumber,
	ISNULL(VEH.SVOTypeID,0) AS SVOvehicle,
	VEH.FOBCode

	FROM SelectionOutput.OnlineOutput AS O 
	INNER JOIN SelectionOutput.CATI C ON C.CaseID = O.ID 
										AND C.PartyID = O.PartyID
	INNER JOIN Event.AutomotiveEventBasedInterviews aebi ON aebi.CaseID = O.ID 
	INNER JOIN CTE_DeDuped_Events red ON red.EventID = aebi.EventID
	INNER JOIN [Sample_ETL].CRC.CRCEvents crc ON crc.AuditItemID = red.AuditItemID
	LEFT JOIN dbo.Languages l ON l.LanguageID = CRC.PreferredLanguageID
	
	LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lko		ON LTRIM(RTRIM(CRC.[Owner])) = lko.CDSID AND crc.MarketCode = lko.MarketCode  --V1.1
	LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lkf		ON LTRIM(RTRIM(CRC.[Owner])) = lkf.FullName AND crc.MarketCode =  lkf.MarketCode  --V1.1

	INNER JOIN Vehicle.Vehicles VEH ON O.VIN = VEH.VIN
	WHERE EXISTS 
	(	SELECT *
		FROM dbo.vwBrandMarketQuestionnaireSampleMetadata M
		INNER JOIN ContactMechanism.Countries C ON M.CountryID = C.CountryID
		WHERE M.Brand = @Brand
		AND C.ISOAlpha3 = @Market
		AND M.Questionnaire = @Questionnaire
		AND M.CATIMerged = 1)
	
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