CREATE PROC SelectionOutput.uspInsertCATICLP
(
	@Brand NVARCHAR(510),
	@Market VARCHAR(200),
	@Questionnaire VARCHAR(255)
)
AS

/*
	Purpose:	Insert Data into SelectionOutput.CATICLP Table
	
	Version			Date			Developer			Comment
	1.0				2019-11-07		Chris Ledger		Bug 15191 - New SP from Insert Into CATICLP SQL Task (Selection Output package)  
	1.1				2019-11-13		Chris Ledger		Bug 15576 - Add Canada to LostLeads Survey URL
	1.2				2020-03-13		Chris Ledger		Bug 16891 - Add ServiceEventType
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	INSERT INTO SelectionOutput.CATICLP
	(Password, ID, FullModel, Model, sType, CarReg, Title, Initial, Surname, Fullname, DearName, CoName, Add1, Add2, Add3, Add4, Add5, Add6, Add7, Add8, Add9, CTRY, EmailAddress, 
	Dealer, sno, ccode, modelcode, lang, manuf, gender, qver, blank, etype, reminder, week, test, SampleFlag, SalesServiceFile, ITYPE, Expired, VIN, EventDate, DealerCode, Telephone, 
	WorkTel, MobilePhone, ManufacturerDealerCode, ModelYear, CustomerIdentifier, OwnershipCycle, OutletPartyID, PartyID, GDDDealerCode, ReportingDealerPartyID, VariantID, ModelVariant, 
	SurveyURL, CATIType, FileDate, Brand, Market, Questionnaire, Queue,	AssignedMode, RequiresManualDial, CallRecordingsCount, TimeZone, CallOutcome, PhoneNumber, PhoneSource,
	Language, ExpirationTime, HomePhoneNumber, WorkPhoneNumber, MobilePhoneNumber, EmployeeName, SVOvehicle, FOBCode, JLREventType, LostLead_DateOfLeadCreation, 
	LostLead_CompleteSuppressionJLR, LostLead_CompleteSuppressionRetailer, LostLead_PermissionToEmailJLR, LostLead_PermissionToEmailRetailer, 
	LostLead_PermissionToPhoneJLR, LostLead_PermissionToPhoneRetailer, LostLead_PermissionToPostJLR, LostLead_PermissionToPostRetailer, LostLead_PermissionToSMSJLR, 
	LostLead_PermissionToSMSRetailer, LostLead_PermissionToSocialMediaJLR, LostLead_PermissionToSocialMediaRetailer, LostLead_DateOfLastContact, HotTopicCodes, ServiceEventType)

	SELECT DISTINCT  
	O.Password, O.ID, O.FullModel, O.Model, O.sType, O.CarReg, O.Title, O.Initial, O.Surname, O.Fullname, O.DearName, O.CoName, O.Add1, O.Add2, 
	O.Add3, O.Add4, O.Add5, O.Add6, O.Add7, O.Add8, O.Add9, O.CTRY, O.EmailAddress, O.Dealer, O.sno, O.ccode, O.modelcode, O.lang, O.manuf, 
	O.gender, O.qver, O.blank, O.etype, O.reminder, O.week, O.test, O.SampleFlag, O.SalesServiceFile, O.ITYPE, O.Expired,O.VIN, 
	REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate, 
	O.DealerCode, O.Telephone, O.WorkTel, O.MobilePhone,
	O.ManufacturerDealerCode, O.ModelYear , O.CustomerIdentifier, O.OwnershipCycle  , O.OutletPartyID,
	O.PartyID, O.GDDDealerCode, O.ReportingDealerPartyID, O.VariantID, O.ModelVariant, 
	CASE @Questionnaire
		WHEN 'Lostleads' THEN
			 CASE WHEN CT.ISOAlpha3 IN ('GBR','IND')
				THEN 'https://feedback.tell-jlr.com/S19022329/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) +'/T'
			 WHEN CT.ISOAlpha3 IN ('USA','CAN')																	-- V1.1
				THEN 'https://feedback.tell-jlr.com/S19022330/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) +'/T'
			 ELSE 'https://feedback.tell-jlr.com/T/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) 
			 END
		WHEN 'PreOwned Lostleads' THEN
			 CASE WHEN CT.ISOAlpha3 IN ('GBR','IND')
				THEN 'https://feedback.tell-jlr.com/S19022329/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) +'/T'
			 WHEN CT.ISOAlpha3 IN ('USA','CAN')																	-- V1.1
				THEN 'https://feedback.tell-jlr.com/S19022330/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) +'/T'
			 ELSE 'https://feedback.tell-jlr.com/T/' + RTRIM(O.ID) +'/' + RTRIM(O.Password) 
			 END
	ELSE 'https://feedback.tell-jlr.com/T/' + RTRIM(O.ID) +'/' + RTRIM(O.Password)  
	END AS SurveyURL,
	O.CATIType,  
	CONVERT(VARCHAR,Getdate(),103) AS FileDate,
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
	C.EmployeeName,
	ISNULL(VEH.SVOTypeID,0) AS SVOvehicle,
	VEH.FOBCode,
	O.JLREventType,
	O.DateOfLeadCreation,
	O.CompleteSuppressionJLR,
	O.CompleteSuppressionRetailer,
	O.PermissionToEmailJLR,
	O.PermissionToEmailRetailer,
	O.PermissionToPhoneJLR,
	O.PermissionToPhoneRetailer,
	O.PermissionToPostJLR,
	O.PermissionToPostRetailer,
	O.PermissionToSMSJLR,
	O.PermissionToSMSRetailer,
	O.PermissionToSocialMediaJLR,
	O.PermissionToSocialMediaRetailer,
	O.DateOfLastContact,
	O.HotTopicCodes,
	O.ServiceEventType			-- V1.2

	FROM SelectionOutput.OnlineOutput AS O 
	INNER JOIN SelectionOutput.CATI C ON C.CaseID = O.ID AND C.PartyID = O.PartyID
	INNER JOIN ContactMechanism.Countries CT ON O.ccode = CT.CountryID
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