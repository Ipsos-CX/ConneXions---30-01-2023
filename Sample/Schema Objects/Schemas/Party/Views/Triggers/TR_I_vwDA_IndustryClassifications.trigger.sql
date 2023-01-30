CREATE TRIGGER Party.TR_I_vwDA_IndustryClassifications ON Party.vwDA_IndustryClassifications
INSTEAD OF INSERT

AS

/*
	Purpose:	Loads Industry Classification data from the VWT into the system.
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.vwDA_IndustryClassifications.TR_I_vwDA_IndustryClassifications
	1.1				09-12-2019		Chris Ross			BUG 16810 - New code to accept and load PartyExclusionCategoryID into Sample.Party.IndustryClassifications and Sample_Audit.Audit.IndustryClassifications 

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN

		-- FIRST INSERT INTO SUPERTYPE PartyClassifications VIA TRIGGER ON VIEW THAT HANDLES INSERT INTO AUDIT
		INSERT INTO Party.vwDA_PartyClassifications
		(
			AuditItemID, 
			PartyTypeID, 
			PartyID, 
			FromDate, 
			ThroughDate
		)
		SELECT
			AuditItemID, 
			PartyTypeID, 
			PartyID, 
			FromDate, 
			ThroughDate
		FROM INSERTED


		;WITH CTE_OrderedByExclusionCategories										-- v1.1
		AS (
			SELECT ROW_NUMBER() OVER(PARTITION BY I.PartyTypeID, I.PartyID ORDER BY pet.OrderOfPreference) AS RowID,
				I.PartyTypeID, 
				I.PartyID,
				I.PartyExclusionCategoryID	-- v1.1
			FROM INSERTED I
			INNER JOIN Party.PartyExclusionCategories pet ON pet.PartyExclusionCategoryID = I.PartyExclusionCategoryID
			LEFT JOIN Party.IndustryClassifications IC ON IC.PartyTypeID = I.PartyTypeID
														AND IC.PartyID = I.PartyID
			WHERE IC.PartyID IS NULL
		)  
		INSERT INTO Party.IndustryClassifications
		(
			PartyTypeID, 
			PartyID,
			PartyExclusionCategoryID	-- v1.1
		)
		SELECT 
			cte.PartyTypeID, 
			cte.PartyID,
			cte.PartyExclusionCategoryID	-- v1.1
		FROM CTE_OrderedByExclusionCategories cte
		WHERE RowID = 1

		

		INSERT INTO [$(AuditDB)].Audit.IndustryClassifications
		(
			AuditItemID, 
			PartyTypeID, 
			PartyID, 
			FromDate,
			PartyExclusionCategoryID	-- v1.1
		)
		SELECT DISTINCT
			I.AuditItemID, 
			I.PartyTypeID, 
			I.PartyID, 
			PC.FromDate,
			I.PartyExclusionCategoryID	-- v1.1
		FROM INSERTED I
		INNER JOIN Party.PartyClassifications PC ON I.PartyTypeID = PC.PartyTypeID
												AND I.PartyID = PC.PartyID
		LEFT JOIN [$(AuditDB)].Audit.IndustryClassifications AIC ON AIC.AuditItemID = I.AuditItemID
																AND AIC.PartyTypeID = I.PartyTypeID
																AND AIC.PartyID = I.PartyID
																AND AIC.FromDate = PC.FromDate
		WHERE AIC.AuditItemID IS NULL
		
	COMMIT TRAN
	
END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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





