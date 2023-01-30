CREATE PROCEDURE SelectionOutput.uspGetAllRoadside
	@RussiaOutput INTEGER = 0		-- V1.1
AS 

/*


Description: Gets All Roadside Records for Output.  Called by: Selection Output.dtsx (Output All Roadside - Data Flow Task)
------------


Version		Created			Author		History		
-------		-------			------		-------			
1.0			14-04-2015		C.Ross		Original Version
1.1			12-09-2019		C.Ledger	BUG 15571 - Separate Russia Output
1.2			27-05-2021		C.Ledger	Remove China.Roadside_WithResponses
1.3			02-07-2021		C.Ledger	TASK 535 - Add EventID
1.4			20-07-2021		C.Ledger	TASK 558 - Add EngineType
1.5			21-07-2021		C.Ledger	TASK 552 - Add SVOvehicle
*/
 
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

DECLARE @NOW	DATETIME,	
		@dtCATI	DATETIME
    
SET	@NOW = GETDATE()
SET	@dtCATI	= DATEADD(week, DATEDIFF(day, 0, @NOW)/7, 4)
;WITH CTE_Events AS 
(
	SELECT AEBI.EventID, 
		RE.AuditItemID
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.EventID = AEBI.EventID
		INNER JOIN [$(ETLDB)].Roadside.RoadsideEvents RE ON RE.AuditItemID = AE.AuditItemID
	UNION
	SELECT AEBI.EventID, 
		REP.AuditItemID
	FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN [$(AuditDB)].Audit.Events AE ON AE.EventID = AEBI.EventID
		INNER JOIN [$(ETLDB)].Roadside.RoadsideEventsProcessed REP ON REP.AuditItemID = AE.AuditItemID
)
, CTE_DeDuped_Events (EventID, AuditItemID) AS 
(
	SELECT EventID, 
		MAX(AuditItemID) AS AuditItemID
	FROM CTE_Events
	GROUP BY EventID
)
, CTE_RoadsideEventData AS 
(
	SELECT 
		E.EventID,
		BreakdownDate, 
		BreakdownDateOrig,
		BreakdownCountry, 
		BreakdownCountryID, 
		BreakdownCaseId, 
		CarHireStartDate, 
		ReasonForHire, 
		HireGroupBranch, 
		CarHireTicketNumber, 
		HireJobNumber, 
		RepairingDealer, 
		DataSource,
		ReplacementVehicleMake,
		ReplacementVehicleModel,
		VehicleReplacementTime,
		CarHireStartTime,
		ConvertedCarHireStartTime,
		RepairingDealerCountry,
		RoadsideAssistanceProvider,
		BreakdownAttendingResource,
		CarHireProvider,
		CountryCodeISOAlpha2,
		BreakdownCountryISOAlpha2,
		REP.DealerCode,
		REP.CountryCode AS VehicleOriginCountry
	FROM [$(ETLDB)].Roadside.RoadsideEventsProcessed REP
		INNER JOIN CTE_DeDuped_Events E ON E.AuditItemID = REP.AuditItemID
		INNER JOIN [$(AuditDB)].Audit.Events AE ON REP.AuditItemID = AE.AuditItemID 
	UNION 
	SELECT 
		E.EventID,
		BreakdownDate, 
		BreakdownDateOrig,
		BreakdownCountry, 
		BreakdownCountryID, 
		BreakdownCaseId, 
		CarHireStartDate, 
		ReasonForHire, 
		HireGroupBranch, 
		CarHireTicketNumber, 
		HireJobNumber, 
		RepairingDealer, 
		DataSource,
		ReplacementVehicleMake,
		ReplacementVehicleModel,
		VehicleReplacementTime,
		CarHireStartTime,
		ConvertedCarHireStartTime,
		RepairingDealerCountry,
		RoadsideAssistanceProvider,
		BreakdownAttendingResource,
		CarHireProvider,
		CountryCodeISOAlpha2,
		BreakdownCountryISOAlpha2,
		RE.DealerCode,
		RE.CountryCode AS VehicleOriginCountry
	FROM [$(ETLDB)].Roadside.RoadsideEvents RE
		INNER JOIN CTE_DeDuped_Events E ON E.AuditItemID = RE.AuditItemID
		INNER JOIN [$(AuditDB)].Audit.Events AE ON RE.AuditItemID = AE.AuditItemID 
)
SELECT O.Password, 
	O.ID, 
	O.FullModel, 
	O.Model, 
	O.sType, 
	O.CarReg, 
	REPLACE(O.Title, CHAR(9), '') AS Title,
	REPLACE(O.Initial, CHAR(9), '') AS Initial,
	REPLACE(O.Surname, CHAR(9), '') AS Surname,
	REPLACE(O.Fullname, CHAR(9), '') AS Fullname,
	REPLACE(O.DearName, CHAR(9), '') AS DearName,
	REPLACE(O.CoName, CHAR(9), '') AS CoName,
	REPLACE(O.Add1, CHAR(9), '') AS Add1,
	REPLACE(O.Add2, CHAR(9), '') AS Add2,
	REPLACE(O.Add3, CHAR(9), '') AS Add3,
	REPLACE(O.Add4, CHAR(9), '') AS Add4,
	REPLACE(O.Add5, CHAR(9), '') AS Add5,
	REPLACE(O.Add6, CHAR(9), '') AS Add6,
	REPLACE(O.Add7, CHAR(9), '') AS Add7,
	REPLACE(O.Add8, CHAR(9), '') AS Add8,
	REPLACE(O.Add9, CHAR(9), '') AS Add9,
	O.CTRY, 
	REPLACE(O.EmailAddress, CHAR(9), '') AS EmailAddress,
	RED.DealerCode AS Dealer, 
	O.sno, 
	O.ccode, 
	O.modelcode, 
	O.lang, 
	O.manuf, 
	O.gender, 
	O.qver, 
	O.blank, 
	O.etype, 
	O.reminder, 
	O.week, 
	O.test, 
	O.SampleFlag, 
	O.SalesServiceFile, 
	O.ITYPE, 
	O.Expired,
	O.PartyID,
	RED.BreakdownDate, 
	COALESCE(RED.BreakdownCountryISOAlpha2, RED.BreakdownCountry) AS BreakdownCountry, 
	RED.BreakdownCountryID, 
	REPLACE(RED.BreakdownCaseId, CHAR(9), '') AS BreakdownCaseId,
	REPLACE(RED.CarHireStartDate, CHAR(9), '') AS CarHireStartDate,
	REPLACE(RED.ReasonForHire, CHAR(9), '') AS ReasonForHire,
	REPLACE(RED.HireGroupBranch, CHAR(9), '') AS HireGroupBranch,
	REPLACE(RED.CarHireTicketNumber, CHAR(9), '') AS CarHireTicketNumber,
	REPLACE(RED.HireJobNumber, CHAR(9), '') AS HireJobNumber,
	REPLACE(RED.RepairingDealer, CHAR(9), '') AS RepairingDealer,
	REPLACE(RED.DataSource,  CHAR(9), '') AS DataSource,
	REPLACE(RED.ReplacementVehicleMake, CHAR(9), '') AS ReplacementVehicleMake,
	REPLACE(RED.ReplacementVehicleModel, CHAR(9), '') AS ReplacementVehicleModel,
	REPLACE(RED.CarHireStartTime, CHAR(9), '') AS CarHireStartTime,
	RED.ConvertedCarHireStartTime,
	REPLACE(RED.RepairingDealerCountry, CHAR(9), '') AS RepairingDealerCountry,
	REPLACE(RED.RoadsideAssistanceProvider, CHAR(9), '') AS RoadsideAssistanceProvider,
	REPLACE(RED.BreakdownAttendingResource, CHAR(9), '') AS BreakdownAttendingResource,
	REPLACE(RED.CarHireProvider,  CHAR(9), '') AS CarHireProvider,
	REPLACE(O.VIN, CHAR(9), '') AS VIN,
	REPLACE(VehicleOriginCountry, CHAR(9), '') AS VehicleOriginCountry,
	REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator	,					
	REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
	REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
	REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
    REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
	REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,
    CASE	WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121) 
			ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
	REPLACE(O.Telephone, CHAR(9), '') AS Telephone,
	REPLACE(O.WorkTel, CHAR(9), '') AS WorkTel,
	REPLACE(O.MobilePhone, CHAR(9), '') AS MobilePhone,
	O.ModelSummary,
	O.BilingualFlag, 
	O.langBilingual, 
	O.DearNameBilingual, 
	O.EmailSignatorTitleBilingual, 
	O.EmailContactTextBilingual, 
	O.EmailCompanyDetailsBilingual, 
	O.JLRPrivacyPolicyBilingual,
	O.EventID,							-- V1.3
	O.EngineType,						-- V1.4
	O.SVOvehicle						-- V1.5						
FROM SelectionOutput.OnlineOutput O 
	INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype
	INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
	INNER JOIN CTE_RoadsideEventData RED ON RED.EventID = AEBI.EventID
	INNER JOIN Contactmechanism.Countries CN ON O.ccode = CN.CountryID
	--LEFT JOIN [$(ETLDB)].China.Roadside_WithResponses CSR ON O.ID = CSR.CaseID		-- V1.2
WHERE ET.EventCategory = 'Roadside'  
	AND CN.Country NOT IN ('UNITED STATES OF AMERICA','Canada')
	AND ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR  (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.1
	--AND CSR.CaseID IS NULL															-- V1.2

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
