CREATE PROCEDURE SelectionOutput.uspGetAllIAssistance
	@RussiaOutput INTEGER = 0		-- V1.2	
AS

/*
------------------------------------------------------------------------
Description: Gets I-Assistance Records for Selection Output  
Called by: Selection Output.dtsx (Output All I-Assistance - Data Flow Task)
------------------------------------------------------------------------

------------------------------------------------------------------------
Version		Created			Author			History		
1.0			2016-11-09		Chris Ledger	Created from uspGetAllCRC
1.1			2018-12-04		Chris Ledger	
1.2			2019-09-12		Chris Ledger	BUG 15571 - Separate Russia Output
1.3			2021-05-27		Chris Ledger	Tidy formatting
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
	
	DECLARE @DeDupedEvents TABLE(  
		EventID INT NULL,
		AuditItemID INT NULL,
		UNIQUE CLUSTERED (EventID)		
	)

	INSERT INTO @DeDupedEvents (EventID, AuditItemID)
	SELECT EventID, 
		MAX(AuditItemID) AS AuditItemID
	FROM [$(ETLDB)].IAssistance.IAssistanceEvents
	GROUP BY EventID
	

	SELECT DISTINCT
		O.PartyID,
		O.ID,
		O.FullModel,
		O.Model,
		O.sType,
		REPLACE(O.CarReg, CHAR(9), '') AS CarReg,
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
		ISNULL(O.dealer, '') AS Dealer,
		O.sno,
		O.ccode,
		CASE	WHEN O.VIN LIKE '%I-Ass Unknown%' OR O.Model = 'Unknown Vehicle' THEN '99999' 
				ELSE O.modelcode END AS modelcode,
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
		O.SalesServiceFile AS IAssistanceSurveyFile,
		O.ITYPE,
		O.Expired,
		REPLACE(O.VIN, CHAR(9), '') AS VIN,
		O.[Password],
		CAST(REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS VARCHAR(10)) AS EventDate, 
		CASE WHEN O.Itype ='T' THEN  CONVERT(NVARCHAR(10), @dtCATI, 121)
			 ELSE CONVERT(NVARCHAR(10), @NOW, 121) END AS SelectionDate,
		REPLACE(O.Telephone, CHAR(9), '') AS Telephone,
		REPLACE(O.WorkTel, CHAR(9), '') AS WorkTel,
		REPLACE(O.MobilePhone, CHAR(9), '') AS MobilePhone,
		O.ModelSummary,    	
		REPLACE(O.EmailSignator, CHAR(10), '<br/>') AS EmailSignator,					
		REPLACE(O.EmailSignatorTitle, CHAR(10), '<br/>') AS EmailSignatorTitle,	
		REPLACE(O.EmailContactText, CHAR(10), '<br/>') AS EmailContactText,	
		REPLACE(O.EmailCompanyDetails, CHAR(10), '<br/>') AS EmailCompanyDetails,
		REPLACE(O.JLRCompanyname, CHAR(10), '<br/>') AS JLRCompanyname,
		REPLACE(O.JLRPrivacyPolicy, CHAR(10), '<br/>') AS JLRPrivacyPolicy,	
		O.BilingualFlag,	
		O.langBilingual,			
		O.DearNameBilingual,		
		O.EmailSignatorTitleBilingual,
		O.EmailContactTextBilingual,
		O.EmailCompanyDetailsBilingual,
		O.JLRPrivacyPolicyBilingual,	
		IAE.IAssistanceProvider,
		IAE.IAssistanceCallID,
		CAST(IAE.IAssistanceCallStartDate AS DATE) AS IAssistanceCallStartDate,
		CAST(IAE.IAssistanceCallCloseDate AS DATE) AS IAssistanceCallCloseDate,
		IAE.IAssistanceHelpdeskAdvisorName,
		IAE.IAssistanceHelpdeskAdvisorID,
		IAE.IAssistanceCallMethod
    FROM SelectionOutput.OnlineOutput O
		INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = O.etype 
											AND ET.EventCategory = 'I-Assistance' 	
		INNER JOIN Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = O.ID 
		INNER JOIN @DeDupedEvents DDE ON DDE.EventID = AEBI.EventID
		INNER JOIN [$(ETLDB)].IAssistance.IAssistanceEvents IAE ON IAE.AuditItemID = DDE.AuditItemID	
	WHERE ((@RussiaOutput = 1 AND ISNULL(O.CTRY,'') = 'Russian Federation') OR (@RussiaOutput = 0 AND ISNULL(O.CTRY,'') <> 'Russian Federation'))	-- V1.2

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