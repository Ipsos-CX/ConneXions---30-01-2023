

/*CREATE PROCEDURE OnlineExpiryReOutputs.uspGetReOutputCases
@DaysToReport int
AS
SET NOCOUNT ON

--------------------------------------------------------------------------------------------
--
-- Name : OnlineExpiryReOutputs.uspReportCases
--
-- Desc : Reports Cases that have been re-output for expired On-line records.
--
-- Change History...
-- 
-- Version	Date		Author		Description
-- =======	====		======		===========
--	1.0		26-03-2012	Chris Ross	Original version
--
--------------------------------------------------------------------------------------------


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	

SELECT CCMO.CaseID ,
	   ASO.PartyID,
	   CO.AuditItemID,
	   CCMO.ActionDate AS OnlineExpiredDate,	
	   CCMO.ReOutputProcessDate,
	   CT.CaseOutputType AS ReOutputType,
	   ASO.VIN,
	   EA.EmailAddress,
	   ASO.Fullname,
	   ASO.Add1 ,
	   ASO.Add2 ,
	   ASO.Add3 ,
	   ASO.Add4 ,
	   ASO.Add5 ,
	   ASO.LandPhone,
	   ASO.workphone,
	   ASO.MobilePhone ,
	   ASO.Dealer
FROM Sample.Event.CaseContactMechanismOutcomes CCMO
INNER JOIN Sample.ContactMechanism.EmailAddresses EA on EA.ContactMechanismID = CCMO.ContactMechanismID 
inner join Sample.Event.CaseOutput CO on CO.CaseID = CCMO.CaseID 
INNER JOIN Sample.Event.CaseOutputTypes CT on CT.CaseOutputTypeID = CO.CaseOutputTypeID 
inner join Sample_Audit.Audit.SelectionOutput ASO 
						on ASO.AuditItemID = CO.AuditItemID 
						AND DATEADD(dd, DATEDIFF(dd, 0, ASO.DateOutput), 0) = DATEADD(dd, DATEDIFF(dd, 0, CCMO.ReOutputProcessDate), 0)
WHERE CCMO.OutcomeCode = (select OutcomeCode from Sample.ContactMechanism.OutcomeCodes oc 
						 where oc.Outcome = 'Online Expiry Date Reached')
AND CCMO.ReOutputSuccess = 1
AND CCMO.ReOutputProcessDate >= DATEADD(day, -@DaysToReport , getdate())
ORDER BY CCMO.ReOutputProcessDate , OnlineExpiredDate 

	
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
		
END CATCH*/


