
-- CGR 13-12-2016 - BUG 13364 - REMOVED AS CODE NOW NOT REQUIRED (note: this was enever released to Live)



--CREATE PROCEDURE [Load].[uspSampleSuppliedNonSolicitations_Unsuppressions]

--AS


	--Purpose:	Set through date on non-solicitations where sample file flagged as 'unsuppress' 
				--and non-solicitaion flags not set.
	
	--Version			Date			Developer			Comment
	--1.0				10-02-2015		Chris Ross			Original
	



--SET NOCOUNT ON

--DECLARE @ErrorNumber INT
--DECLARE @ErrorSeverity INT
--DECLARE @ErrorState INT
--DECLARE @ErrorLocation NVARCHAR(500)
--DECLARE @ErrorLine INT
--DECLARE @ErrorMessage NVARCHAR(2048)

--BEGIN TRY


	---- Set one time to stamp all records with
	--DECLARE @CurrentDatetime DATETIME
	--SET @CurrentDatetime = GETDATE()
	

	--------------------------------------------------------------------------------------------------------------------------------------------
	---- Get all valid non-suppressions from VWT
	--------------------------------------------------------------------------------------------------------------------------------------------

	--SELECT
		--v.AuditItemID, 
		--COALESCE(NULLIF(v.MatchedODSPersonID, 0), NULLIF(v.MatchedODSOrganisationID, 0), NULLIF(v.MatchedODSPartyID, 0), 0) AS PartyID,
		--CASE WHEN v.PartySuppression = 0  AND m.NonSolSupplied_Party = 1  THEN 1 ELSE 0 END AS PartyUnSuppression,
		--CASE WHEN v.PostalSuppression = 0 AND m.NonSolSupplied_Postal = 1 THEN 1 ELSE 0 END AS PostalUnSuppression,
		--CASE WHEN v.EmailSuppression = 0  AND m.NonSolSupplied_Email = 1  THEN 1 ELSE 0 END AS EmailUnSuppression, 
		--v.MatchedODSAddressID AS PostalContactMechanismID,
		--v.MatchedODSEmailAddressID AS EmailContactMechanismID
	--INTO #Unsuppressions
	--FROM dbo.VWT v
	--INNER JOIN [$(AuditDB)].dbo.Files f ON f.AuditID = v.AuditID
	--INNER JOIN [$(SampleDB)].dbo.SampleFileMetadata m ON f.FileName LIKE  m.SampleFileNamePrefix + '%'
											  --AND m.NonSolUnsuppress_Active = 1
	--WHERE (
		--v.PartySuppression = 0  AND m.NonSolSupplied_Party = 1
		--OR ( v.PostalSuppression = 0 AND m.NonSolSupplied_Postal = 1 AND COALESCE ( NULLIF ( v.MatchedODSAddressID, 0 ) , 0 ) > 0 )
		--OR ( v.EmailSuppression = 0 AND m.NonSolSupplied_Email = 1 AND v.EmailAddress IS NOT NULL AND ( NULLIF(v.MatchedODSEmailAddressID, 0) > 0 ) ) 
	--)
	--AND COALESCE( 
			--NULLIF(MatchedODSPersonID, 0), 
			--NULLIF(MatchedODSOrganisationID, 0), 
			--NULLIF(MatchedODSPartyID, 0), 0) > 0;



	--------------------------------------------------------------------------------------------------------------------------------------------
	---- Unsuppress Party Non-soliciations (i.e. set through date)
	--------------------------------------------------------------------------------------------------------------------------------------------

	---- Get Party Non-solications
	-------------------------------
	--SELECT  U.*,
			--ns.NonSolicitationID
	--INTO #PartyNonSolicationUnsuppress
	--FROM #Unsuppressions U
	--INNER JOIN [$(SampleDB)].dbo.NonSolicitations ns ON ns.PartyID = U.PartyID
	--INNER JOIN [$(SampleDB)].Party.NonSolicitations pns ON pns.NonSolicitationID = ns.NonSolicitationID
	--WHERE U.PartyUnsuppression = 1	
	--AND ns.HardSet <> 1	 -- Do not unsuppress where a HardSet nonsoliciation
	--AND ISNULL(ns.ThroughDate, CAST('2099-01-01' AS datetime)) > GETDATE()  -- Only unsuppress is not already set or in the future.


	--BEGIN TRAN ------------

		---- Set ThroughDate and Notes columns on Non-solications table
		----------------------------------------------------------------
		--UPDATE  NS
		--SET     ThroughDate = @CurrentDatetime,
				--Notes = 'Sample Supplied Non Solicitation Unsuppression'
		--FROM    #PartyNonSolicationUnsuppress CN
				--INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.NonSolicitationID = CN.NonSolicitationID
		--WHERE   ThroughDate IS NULL
				--OR ThroughDate > @CurrentDatetime

				


		---- Save to the Non-solicitations Audit table so we have record
		----------------------------------------------------------------
		--INSERT INTO [$(AuditDB)].Audit.NonSolicitations
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
		--SELECT DISTINCT
			--un.AuditItemID, 
			--ns.NonSolicitationID, 
			--ns.NonSolicitationTextID,
			--ns.PartyID,
			--ns.RoleTypeID,
			--ns.FromDate,
			--@CurrentDatetime AS ThroughDate,
			--'Sample Supplied Non Solicitation Unsuppression'
		--FROM #PartyNonSolicationUnsuppress un
		--INNER JOIN [$(SampleDB)].dbo.nonsolicitations ns ON ns.NonSolicitationID = un.NonSolicitationID


	--COMMIT TRAN ------------
	
	

	--------------------------------------------------------------------------------------------------------------------------------------------
	---- Unsuppress Postal Non-soliciations (i.e. set through date)
	--------------------------------------------------------------------------------------------------------------------------------------------


	---- Get Postal Non-solications
	-------------------------------
	--SELECT  U.*,
			--ns.NonSolicitationID
	--INTO #PostalNonSolicationUnsuppress
	--FROM #Unsuppressions U
	--INNER JOIN [$(SampleDB)].dbo.NonSolicitations ns ON ns.PartyID = U.PartyID
	--INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations cns ON cns.NonSolicitationID = ns.NonSolicitationID AND cns.ContactMechanismID = U.PostalContactMechanismID
	--WHERE U.PostalUnsuppression = 1	
	--AND ns.HardSet <> 1	 -- Do not unsuppress where a HardSet nonsoliciation
	--AND ISNULL(ns.ThroughDate, CAST('2099-01-01' AS datetime)) > GETDATE()  -- Only unsuppress is not already set or in the future.


	--BEGIN TRAN --------------

		---- Set ThroughDate and Notes columns on Non-solications table
		----------------------------------------------------------------
		--UPDATE  NS
		--SET     ThroughDate = @CurrentDatetime,
				--Notes = 'Sample Supplied Non Solicitation Unsuppression'
		--FROM    #PostalNonSolicationUnsuppress CN
				--INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.NonSolicitationID = CN.NonSolicitationID
		--WHERE   ThroughDate IS NULL
				--OR ThroughDate > @CurrentDatetime



		---- Save to the Non-solicitations Audit table so we have a record
		------------------------------------------------------------------
		--INSERT INTO [$(AuditDB)].Audit.NonSolicitations
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
		--SELECT DISTINCT
			--un.AuditItemID, 
			--ns.NonSolicitationID, 
			--ns.NonSolicitationTextID,
			--ns.PartyID,
			--ns.RoleTypeID,
			--ns.FromDate,
			--@CurrentDatetime AS ThroughDate,
			--'Sample Supplied Non Solicitation Unsuppression'
		--FROM #PostalNonSolicationUnsuppress un
		--INNER JOIN [$(SampleDB)].dbo.nonsolicitations ns ON ns.NonSolicitationID = un.NonSolicitationID


	--COMMIT TRAN ---------------



	--------------------------------------------------------------------------------------------------------------------------------------------
	---- Unsuppress Email Non-soliciations (i.e. set through date)
	--------------------------------------------------------------------------------------------------------------------------------------------

	---- Get Email Non-solications
	-------------------------------
	--SELECT  U.*,
			--ns.NonSolicitationID
	--INTO #EmailNonSolicationUnsuppress
	---- select * 
	--FROM #Unsuppressions U
	--INNER JOIN [$(SampleDB)].dbo.NonSolicitations ns ON ns.PartyID = U.PartyID
	--INNER JOIN [$(SampleDB)].ContactMechanism.NonSolicitations cns ON cns.NonSolicitationID = ns.NonSolicitationID AND cns.ContactMechanismID = U.EmailContactMechanismID
	--WHERE U.EmailUnsuppression = 1	
	--AND ns.HardSet <> 1	 -- Do not unsuppress where a HardSet nonsoliciation
	--AND ISNULL(ns.ThroughDate, CAST('2099-01-01' AS datetime)) > GETDATE()  -- Only unsuppress is not already set or in the future.


	--BEGIN TRAN -----------

		---- Set ThroughDate and Notes columns on Non-solications table
		----------------------------------------------------------------
		--UPDATE  NS
		--SET     ThroughDate = @CurrentDatetime,
				--Notes = 'Sample Supplied Non Solicitation Unsuppression'
		--FROM    #EmailNonSolicationUnsuppress CN
				--INNER JOIN [$(SampleDB)].dbo.NonSolicitations NS ON NS.NonSolicitationID = CN.NonSolicitationID
		--WHERE   ThroughDate IS NULL
				--OR ThroughDate > @CurrentDatetime



		---- Save to the Non-solicitations Audit table so we have a record
		------------------------------------------------------------------
		--INSERT INTO [$(AuditDB)].Audit.NonSolicitations
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
		--SELECT DISTINCT
			--un.AuditItemID, 
			--ns.NonSolicitationID, 
			--ns.NonSolicitationTextID,
			--ns.PartyID,
			--ns.RoleTypeID,
			--ns.FromDate,
			--@CurrentDatetime AS ThroughDate,
			--'Sample Supplied Non Solicitation Unsuppression'
		--FROM #EmailNonSolicationUnsuppress un
		--INNER JOIN [$(SampleDB)].dbo.nonsolicitations ns ON ns.NonSolicitationID = un.NonSolicitationID


	 --COMMIT TRAN ---------------


	--DROP TABLE #Unsuppressions
	--DROP TABLE #PartyNonSolicationUnsuppress
	--DROP TABLE #PostalNonSolicationUnsuppress
	--DROP TABLE #EmailNonSolicationUnsuppress
	

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