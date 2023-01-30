CREATE PROCEDURE [InternalUpdate].[uspCaseRejection_Insert]

AS
SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	BEGIN TRAN

		DECLARE @ProcessDate DATETIME
		SET @ProcessDate = GETDATE()

		-- CHECK THE CaseID AND PartyID
		UPDATE CR
		SET CR.CasePartyCombinationValid = 1
		FROM InternalUpdate.CaseRejections CR
		INNER JOIN [$(SampleDB)].Event.AutomotiveEventBasedInterviews AEBI ON AEBI.CaseID = CR.CaseID AND AEBI.PartyID = CR.PartyID
		WHERE CR.DateProcessed IS NULL
		AND CR.AuditItemID = CR.ParentAuditItemID

		--SELECT * FROM InternalUpdate.CaseRejections

		-- CHECK WHETHER REJECTION/UNREJECTION REQUIRED
		UPDATE CR
		SET CR.[Required] = 1
		--SELECT CR.Rejection, CR.[Required]
		FROM InternalUpdate.CaseRejections CR
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
		WHERE CR.DateProcessed IS NULL
		AND CR.AuditItemID = CR.ParentAuditItemID		-- NON DUPLICATE
		AND CR.CasePartyCombinationValid = 1			-- VALID CASEPARTYID COMBINATION		
		AND CR.Rejection <> CAST(CASE CD.CaseRejection WHEN 1 THEN 1 ELSE 0 END AS BIT)


		-- PROCESS REJECTIONS
		INSERT INTO [$(SampleDB)].Event.vwDA_CaseRejections
		(
			AuditItemID,
			CaseID,
			Rejection,
			FromDate
		)
		SELECT CR.AuditItemID, CR.CaseID, CR.Rejection, @ProcessDate
		FROM InternalUpdate.CaseRejections CR
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
		WHERE CR.DateProcessed IS NULL
		AND CR.AuditItemID = CR.ParentAuditItemID		-- NON DUPLICATE
		AND CR.CasePartyCombinationValid = 1			-- VALID CASEPARTYID COMBINATION
		AND CR.[Required] = 1;							-- REQUIRED


		-- CREATE TEMPORARY TABLE TO STORE REJECTION/UNREJECTION
		CREATE TABLE #Rejections 
			(
				[RequirementIDPartOf]	[bigint],
				[RecordsRejected]		[bigint],
				[Rejection]				[bit]
			)	

		INSERT INTO #Rejections ([RequirementIDPartOf],
							[RecordsRejected],
							[Rejection])
		SELECT SC.RequirementIDPartOf AS SCRequirementIDPartOf,
			COUNT(CR.CaseID) AS RecordsRejected,
			CR.Rejection
			FROM    InternalUpdate.CaseRejections CR
			INNER JOIN [$(SampleDB)].Requirement.SelectionCases SC ON CR.CaseID = SC.CaseID
			INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
			WHERE CR.DateProcessed IS NULL
			AND CR.AuditItemID = CR.ParentAuditItemID		-- NON DUPLICATE
			AND CR.CasePartyCombinationValid = 1			-- VALID CASEPARTYID COMBINATION
			AND CR.[Required] = 1							-- NOT ALREADY REJECTED
			GROUP BY SC.RequirementIDPartOf, CR.Rejection
		
		UPDATE SR
		SET SR.RecordsRejected = ISNULL(SR.RecordsRejected, 0) + R.RecordsRejected
		FROM [$(SampleDB)].Requirement.SelectionRequirements SR 
		INNER JOIN #Rejections  R ON SR.RequirementID = R.RequirementIDPartOf
		WHERE R.Rejection = 1

		-- UPDATE CASE DETAILS METADATA FOR REJECTION
		UPDATE CD
		SET CD.CaseRejection = 1,
		CD.CaseStatusTypeID = (SELECT CaseStatusTypeID from [$(SampleDB)].Event.CaseStatusTypes WHERE CaseStatusType = 'Refused by Exec')
		FROM InternalUpdate.CaseRejections CR
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
		WHERE CR.DateProcessed IS NULL
		AND CR.AuditItemID = CR.ParentAuditItemID
		AND CR.CasePartyCombinationValid = 1
		AND CR.Rejection = 1
		AND CR.[Required] = 1;

	
		UPDATE SR
		SET SR.RecordsRejected = ISNULL(SR.RecordsRejected, 0) - A.RecordsRejected
		FROM [$(SampleDB)].Requirement.SelectionRequirements SR 
		INNER JOIN #Rejections A ON SR.RequirementID = A.RequirementIDPartOf
		WHERE A.Rejection = 0

		-- UPDATE CASE DETAILS METADATA
		UPDATE CD
		SET CD.CaseRejection = 0,
		CD.CaseStatusTypeID = (SELECT CaseStatusTypeID from [$(SampleDB)].Event.CaseStatusTypes WHERE CaseStatusType = 'Active')
		FROM InternalUpdate.CaseRejections CR
		INNER JOIN [$(SampleDB)].Meta.CaseDetails CD ON CR.CaseID = CD.CaseID
		WHERE CR.DateProcessed IS NULL
		AND CR.AuditItemID = CR.ParentAuditItemID
		AND CR.CasePartyCombinationValid = 1
		AND CR.Rejection = 0			
		AND CR.[Required] = 1

		-- SET THE DateProcessed IN InternalUpdate.CaseRejections
		UPDATE InternalUpdate.CaseRejections
		SET DateProcessed = @ProcessDate
		WHERE DateProcessed IS NULL

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