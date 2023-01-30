
CREATE PROCEDURE SelectionOutput.uspExpireOnline
AS
SET NOCOUNT ON

--------------------------------------------------------------------------------------------
--
-- Name : SelectionOutput.uspExpireOnline
--
-- Desc : check On-line Expiry dates/closure dates/Status on event.case and also 
--		  the Status on IR_CASEDETAILS and whether already re-output and then where appropriate 
--		  populate Event.CaseContactMechanismOutcomes table for re-outputting as CATI.
--
-- Change History...
-- 
-- Version	Date		Author		Description
-- =======	====		======		===========
--	1.0		19-03-2012	Chris Ross	Original version
--
--------------------------------------------------------------------------------------------


DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY
	
	DECLARE @CasesToReOutput TABLE 
			(
				ID		INT identity( 1, 1) ,
				CaseID	dbo.CaseID
			);
	
	-- Select cases where the OnlineExpiryDate has passed and the record is still Active and 
	-- has not already been re-outputted
	INSERT INTO @CasesToReOutput 
	SELECT E.CaseID 
	FROM [Event].Cases E
	LEFT JOIN Warehouse.IR_CaseDetails cd on E.CaseID = cd.CaseID 
	where E.OnlineExpirydate <= GETDATE()
	and E.ClosureDate is null
	and E.CaseStatusTypeID = 1
	and ISNULL(cd.CaseStatusTypeID, 1) = 1 -- If no assoc record found, assume still Active
	and not exists -- not already been flagged for re-output
		(
			Select CaseID from [Event].CaseContactMechanismOutcomes where caseid = E.CaseID 
		);
		
	
	IF EXISTS (Select * from @CasesToReOutput )	-- If there are expired on-line cases to re-output...
	BEGIN
		-- Create audit items
		DECLARE @AuditID dbo.AuditID, @Max_AuditItemID dbo.AuditItemID
		SELECT @AuditID = MAX(AuditID) + 1 from [$(AuditDB)].dbo.Audit 
		SELECT @Max_AuditItemID = MAX (audititemid) from [$(AuditDB)].dbo.AuditItems 
		
		INSERT INTO [$(AuditDB)].dbo.Audit (AuditID) values (@AuditID)
		INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditID, AuditItemID)
			SELECT @AuditID, ID + @Max_AuditItemID as AuditItemID FROM @CasesToReOutput 
		
		-- Create re-output records for the Cases to re-output
		insert into Event.vwDA_CaseContactMechanismOutcomes  (AuditItemID, CaseID, PartyID, OutcomeCode, 
															OutcomeCodeTypeID, ContactmechanismID, EmailAddress, 
															ActionDate, CasePartyEmailCombinationValid)
		select  ctr.ID + @Max_AuditItemID as AuditItemID,
				ctr.caseID, 
				aebi.PartyID,
				oc.OutcomeCode, 
				oc.OutcomeCodeTypeID,
				ccm.ContactMechanismID,
				ea.EmailAddress ,
				GETDATE() as ActionDate,
				1 AS CasePartyEmailCombinationValid
		from @CasesToReOutput  ctr
		inner join Event.CaseContactMechanisms ccm on ccm.CaseID = ctr.CaseID
		inner join Event.AutomotiveEventBasedInterviews aebi on aebi.CaseID = ctr.caseID
		inner join ContactMechanism.EmailAddresses ea on ea.ContactMechanismID = ccm.ContactMechanismID 
		inner join ContactMechanism.OutcomeCodes oc on oc.Outcome = 'Online Expiry Date Reached'
		
	END;

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
