
-- CGR 13-12-2016 - BUG 13364 - REMOVED AS NOW REDUNDANT CODE


--CREATE PROCEDURE [Load].[uspSampleSuppliedNonSolicitations]

--AS

	--Purpose:	Write the various non solicitations supplied in the sample files to the Sample database
	
	--Version			Date			Developer			Comment
	--1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspODSLOAD_SampleSuppliedNonsolicitations
	--1.1				29/May-2012		Pardip Mudhar		BUG 7005 - Suppressed all records for email when email contact id is null
														--This caters for a case where same parties postal address and email is to suppressed
													    --but email does not exist on the sample system (Brazil)
	--1.2				06-07-2015		Chris Ross			BUG 11689 - Add in extra code to non-solicitate associated Contact Mechanisms to 
														--ensure Email and Postal Suppressions work as +full+ suppressions.
	--1.3				21-09-2015		Chris Ross			BUG 11387 - add in Phone Suppressions


--SET NOCOUNT ON

--DECLARE @ErrorNumber INT
--DECLARE @ErrorSeverity INT
--DECLARE @ErrorState INT
--DECLARE @ErrorLocation NVARCHAR(500)
--DECLARE @ErrorLine INT
--DECLARE @ErrorMessage NVARCHAR(2048)

--BEGIN TRY

	--BEGIN TRAN

		----------------------------------------------------------------------------------
		---- PARTY 
		----------------------------------------------------------------------------------
		
		--INSERT INTO [$(SampleDB)].Party.vwDA_NonSolicitations
		--(
			--AuditItemID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--SELECT
			--AuditItemID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--FROM Load.vwSampleSuppliedNonSolicitations
		--WHERE PartySuppression = 1
		
		
		----------------------------------------------------------------------------------
		---- POSTAL
		----------------------------------------------------------------------------------
	
		---- use temp table to build all required non-sols
		--CREATE TABLE #PostalNonSols
		--(
			--AuditItemID				bigint,
			--ContactMechanismID		bigint,
			--NonSolicitationID		int,
			--NonSolicitationTextID	int,
			--PartyID					int,
			--RoleTypeID				int,
			--FromDate				datetime2,
			--ThroughDate				datetime2,
			--Notes					varchar(200)
		--)

		---- Get non-sols (suppressions) from VWT
		--INSERT INTO #PostalNonSols
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--SELECT
			--AuditItemID,
			--PostalContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--FROM Load.vwSampleSuppliedNonSolicitations
		--WHERE PostalSuppression = 1
		
		---- Add in any other postal contact mechanisms associated with the Party
		--INSERT INTO #PostalNonSols
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--select pns.AuditItemID, 
				--pa.ContactMechanismID, 
				--pns.NonSolicitationID, 
				--pns.NonSolicitationTextID,
				--pcm.PartyID,
				--pns.RoleTypeID,
				--pns.FromDate,
				--pns.ThroughDate,
				--pns.Notes
		--from #PostalNonSols pns
		--INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm ON pcm.PartyID = pns.PartyID
		--INNER JOIN [$(SampleDB)].ContactMechanism.PostalAddresses pa ON pa.ContactMechanismID = pcm.ContactMechanismID 
		--LEFT JOIN [$(SampleDB)].ContactMechanism.NonSolicitations cns ON cns.ContactMechanismID = pa.ContactMechanismID
		--LEFT JOIN [$(SampleDB)].dbo.NonSolicitations ns ON ns.NonSolicitationID = cns.NonSolicitationID
		--WHERE (   cns.ContactMechanismID IS NULL
			   --OR ISNULL(ns.ThroughDate, '20990101') < GETDATE()
			  --)
		--AND pa.ContactMechanismID NOT IN (SELECT ContactMechanismID FROM #PostalNonSols)

		
		---- Create all required non-sols
		--INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_ContactMechanismNonSolicitations
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--SELECT
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--FROM #PostalNonSols
		


		----------------------------------------------------------------------------------
		---- EMAIL
		----------------------------------------------------------------------------------
		

		---- use temp table to build all required non-sols
		--CREATE TABLE #EmailNonSols
		--(
			--AuditItemID				bigint,
			--ContactMechanismID		bigint,
			--NonSolicitationID		int,
			--NonSolicitationTextID	int,
			--PartyID					int,
			--RoleTypeID				int,
			--FromDate				datetime2,
			--ThroughDate				datetime2,
			--Notes					varchar(200)
		--)

		---- Get non-sols (suppressions) from VWT
		--INSERT INTO #EmailNonSols
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--SELECT
			--AuditItemID,
			--EmailContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--FROM Load.vwSampleSuppliedNonSolicitations
		--WHERE EmailSuppression = 1
		--AND EmailContactMechanismID IS NOT NULL

		---- Add in any other postal contact mechanisms associated with the Party
		--INSERT INTO #EmailNonSols
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--select pns.AuditItemID, 
				--pa.ContactMechanismID, 
				--pns.NonSolicitationID, 
				--pns.NonSolicitationTextID,
				--pcm.PartyID,
				--pns.RoleTypeID,
				--pns.FromDate,
				--pns.ThroughDate,
				--pns.Notes
		--from #EmailNonSols pns
		--INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm ON pcm.PartyID = pns.PartyID
		--INNER JOIN [$(SampleDB)].ContactMechanism.EmailAddresses pa ON pa.ContactMechanismID = pcm.ContactMechanismID 
		--LEFT JOIN [$(SampleDB)].ContactMechanism.NonSolicitations cns ON cns.ContactMechanismID = pa.ContactMechanismID
		--LEFT JOIN [$(SampleDB)].dbo.NonSolicitations ns ON ns.NonSolicitationID = cns.NonSolicitationID
		--WHERE (   cns.ContactMechanismID IS NULL
			   --OR ISNULL(ns.ThroughDate, '20990101') < GETDATE()
			  --)
		--AND pa.ContactMechanismID NOT IN (SELECT ContactMechanismID FROM #EmailNonSols)

		
		---- Create all required non-sols
		--INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_ContactMechanismNonSolicitations
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--SELECT
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--FROM #EmailNonSols



		----------------------------------------------------------------------------------
		---- TELEPHONE
		----------------------------------------------------------------------------------
		

		---- use temp table to build all required non-sols
		--CREATE TABLE #PhoneNonSols
		--(
			--AuditItemID				bigint,
			--ContactMechanismID		bigint,
			--NonSolicitationID		int,
			--NonSolicitationTextID	int,
			--PartyID					int,
			--RoleTypeID				int,
			--FromDate				datetime2,
			--ThroughDate				datetime2,
			--Notes					varchar(200)
		--)

		---- Get non-sols (suppressions) from VWT
		--INSERT INTO #PhoneNonSols
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--SELECT
			--AuditItemID,
			--TelephoneContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--FROM Load.vwSampleSuppliedPhoneNonSolicitations
		--WHERE TelephoneContactMechanismID IS NOT NULL

		---- Add in any other phone contact mechanisms associated with the Party
		--INSERT INTO #PhoneNonSols
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--select pns.AuditItemID, 
				--pa.ContactMechanismID, 
				--pns.NonSolicitationID, 
				--pns.NonSolicitationTextID,
				--pcm.PartyID,
				--pns.RoleTypeID,
				--pns.FromDate,
				--pns.ThroughDate,
				--pns.Notes
		--from #PhoneNonSols pns
		--INNER JOIN [$(SampleDB)].ContactMechanism.PartyContactMechanisms pcm ON pcm.PartyID = pns.PartyID
		--INNER JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers pa ON pa.ContactMechanismID = pcm.ContactMechanismID 
		--LEFT JOIN [$(SampleDB)].ContactMechanism.NonSolicitations cns ON cns.ContactMechanismID = pa.ContactMechanismID
		--LEFT JOIN [$(SampleDB)].dbo.NonSolicitations ns ON ns.NonSolicitationID = cns.NonSolicitationID
		--WHERE (   cns.ContactMechanismID IS NULL
			   --OR ISNULL(ns.ThroughDate, '20990101') < GETDATE()
			  --)
		--AND pa.ContactMechanismID NOT IN (SELECT ContactMechanismID FROM #PhoneNonSols)

		
		---- Create all required non-sols
		--INSERT INTO [$(SampleDB)].ContactMechanism.vwDA_ContactMechanismNonSolicitations
		--(
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--)
		--SELECT
			--AuditItemID,
			--ContactMechanismID,
			--NonSolicitationID,
			--NonSolicitationTextID,
			--PartyID,
			--RoleTypeID,
			--FromDate,
			--ThroughDate,
			--Notes
		--FROM #PhoneNonSols


	--COMMIT TRAN

--END TRY
--BEGIN CATCH

	--IF @@TRANCOUNT > 0
	--BEGIN
		--ROLLBACK TRAN
	--END

	--SELECT
		 --@ErrorNumber = Error_Number()
		--,@ErrorSeverity = Error_Severity()
		--,@ErrorState = Error_State()
		--,@ErrorLocation = Error_Procedure()
		--,@ErrorLine = Error_Line()
		--,@ErrorMessage = Error_Message()

	--EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 --@ErrorNumber
		--,@ErrorSeverity
		--,@ErrorState
		--,@ErrorLocation
		--,@ErrorLine
		--,@ErrorMessage
			
	--RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
--END CATCH