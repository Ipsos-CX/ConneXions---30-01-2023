CREATE PROCEDURE [SelectionOutput].[uspGetSelectionOutput_CATICRC]

		@Questionnaire VARCHAR(200)

AS
/*
	Purpose:	Get CATI Output
	
	Version			Date				Developer			Comment
	1.0				?					Eddie Thomas		Created
	1.1				04-01-2018			Chris Ross			Added to Connexions solution and modified to use a temp table as the CTE was not getting parsed in the solution.
	1.2				05-07-2018			Eddie Thomas		Removal of SVOvehicle and FOBCode
	1.3				10-01-2019			Eddie Thomas		Added SVOvehicle and FOBCode back in and event de-dupping now filtered by cases currently being processdc
	1.4				29-03-2019			Chris Ross			Added in SET NOCOUNT ON as this was causing issues running the proc from the output package.
	1.5				25-10-2019			Eddie Thomas		BUG 16667 : Add HotTopicCodes field and PHEV flags
	1.6				20-03-2020			Chris Ledger		Fix hard coded database references
	1.7				26-03-2021			Eddie Thomas		BUG 18144 - CRC Agent Look up table
*/


SET NOCOUNT ON		-- 1.4


--V1.1
DECLARE @CTE_DeDuped_Events Table
(
	EventID		BIGINT, 
	AuditItemID	BIGINT
)


--V1.3 ONLY DE-DUPPING ON CASES WE'RE CURRENTLY PROCESSING
INSERT		@CTE_DeDuped_Events
SELECT		ODSEventID AS EventID, MAX(AuditItemID)
FROM		[Sample_ETL].CRC.CRCEvents CRC
INNER JOIN  Meta.CaseDetails CD ON CRC.ODSEventID = CD.EventID
INNER JOIN  SelectionOutput.OnlineOutput  O ON CD.CaseID = O.ID
GROUP BY	ODSEventID
	
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
--CASE WHEN LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBy ELSE CRC.Owner END AS [Owner],  -- BUG 11949 Output Owner field if ClosedBy is blank
--CASE
--	WHEN LK.CODE IS NOT NULL THEN LK.FirstName	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
--	WHEN LK.CODE IS NULL AND LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBY
--	ELSE CRC.[Owner]
--END AS [Owner],	
CASE
	WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
	WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
	ELSE CRC.[Owner]                                                                                                                                                                                                                  
END AS [Owner], --V1.7
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
--CASE WHEN LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBy ELSE CRC.Owner END AS [Owner],  -- BUG 11949 Output Owner field if ClosedBy is blank
--CASE
--	WHEN LK.CODE IS NOT NULL THEN LK.FirstName	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
--	WHEN LK.CODE IS NULL AND LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN CRC.ClosedBY
--	ELSE CRC.[Owner]
--END AS [OwnerType],
CASE
	WHEN lko.CDSID IS NOT NULL THEN lko.CDSID	-- WE'VE GOT A MATCH IN THE LOOKUP TABLE, USE IT. 
	WHEN lkf.CDSID IS NOT NULL THEN lkf.CDSID
	ELSE CRC.[Owner]                                                                                                                                                                                                                  
END AS [OwnerType],  --V1.7
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
ISNULL(VEH.SVOTypeID,0) AS SVOvehicle,  --V1.3
VEH.FOBCode,			--V1.3
O.HotTopicCodes			--V1.5

--SELECT * 
FROM SelectionOutput.OnlineOutput AS O 
INNER JOIN SelectionOutput.CATI C on C.CaseID = O.ID 
								  and C.PartyID = O.PartyID
--INNER JOIN   Event.vwEventTypes AS ET ON ET.EventTypeID = O.etype
INNER JOIN   Event.AutomotiveEventBasedInterviews aebi on aebi.CaseID = O.ID 
INNER JOIN	 @CTE_DeDuped_Events red on red.EventID = aebi.EventID
INNER JOIN   [Sample_ETL].CRC.CRCEvents crc ON crc.AuditItemID = red.AuditItemID
LEFT JOIN	 dbo.Languages l ON l.LanguageID = CRC.PreferredLanguageID

LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lko		ON LTRIM(RTRIM(CRC.[Owner])) = lko.CDSID AND crc.MarketCode = lko.MarketCode  --V1.7

LEFT JOIN	[Sample_ETL].[Lookup].[CRCAgents_GlobalList] lkf		ON LTRIM(RTRIM(CRC.[Owner])) = lkf.FullName AND crc.MarketCode =  lkf.MarketCode  --V1.7
--LEFT JOIN   [Sample_ETL].[Lookup].[CRCAgentLookup] lk ON
--			CASE 
--				WHEN LEN(ISNULL(CRC.ClosedBy,'')) > 0 THEN LTRIM(RTRIM(CRC.ClosedBy))
--				ELSE LTRIM(RTRIM(CRC.[Owner])) 
--			END  = lk.Code AND
			
--			crc.BrandCode = CASE 
--								 WHEN lk.Brand = 'Jaguar' THEN 'J'
--								 WHEN lk.Brand = 'Land Rover' THEN 'L'
--								 ELSE lk.Brand
--							END
							
--							AND
--			crc.MarketCode =  lk.MarketCode

--FILTER OUT RECORDS WHERE OUTPUT LANGUAGE INVALID
INNER JOIN SelectionOutput.CATIAvailableLanguages CL ON	O.sType = CL.Brand AND
														O.Market = CL.Market AND
														O.lang =  CL.LanguageID 

INNER JOIN Vehicle.Vehicles VEH			ON O.VIN = VEH.VIN
WHERE CL.Questionnaire = @Questionnaire
