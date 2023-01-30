CREATE PROCEDURE CaseUpdate.uspCRMLostLeadResponses_Insert

AS

/* 
		Purpose:	Insert new records into [$(SampleDB)].Event.CRMLostLeadResponses table
	
		Version		Date			Developer			Comment										
LIVE	1.0			2021-12-01		Chris Ledger		Created
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

		-- DELETE EXISTING RECORDS
		DELETE FROM R
		FROM [$(SampleDB)].Event.CRMLostLeadResponses R
			INNER JOIN CaseUpdate.CRMLostLeadResponses CR ON R.CaseID = CR.[Case ID]


		-- ADD NEW RECORDS
		;WITH CTE_LostLeadCodes ([Case ID], [Event ID], Question, Code, Verbatim) AS
		(
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Made enquiry about model] = C.MedalliaResponse
			WHERE C.Question = 'S1'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Enquiry channel], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'S2'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], 'S3' AS Question, NULL AS Code, R.[Other JLR model enquiry] AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
			WHERE R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], 'S4' AS Question, NULL AS Code, COALESCE(R.[Other JLR Retailer visited - CA], R.[Other JLR Retailer visited - UK], R.[Other JLR Retailer visited - US]) AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
			WHERE R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Lost Leads NPS] = C.MedalliaResponse
			WHERE C.Question = 'E2'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Did you get what you wanted] = C.MedalliaResponse
			WHERE C.Question = 'E3'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], 'E4' AS Question, NULL AS Code, R.[Did you get what you wanted - comments] AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
			WHERE R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.Welcome = C.MedalliaResponse
			WHERE C.Question = 'E5'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Understanding wants/needs] = C.MedalliaResponse
			WHERE C.Question = 'E6'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Explanation of features/benefits] = C.MedalliaResponse
			WHERE C.Question = 'E7'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Test drive offered] = C.MedalliaResponse
			WHERE C.Question = 'E8'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Follow up] = C.MedalliaResponse
			WHERE C.Question = 'E9'
			UNION
			SELECT R.[Case ID], R.[Event ID], 'E10' AS Question, NULL AS Code, R.[Additional comments about the experience] AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
			WHERE R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Still considering purchasing] = C.MedalliaResponse
			WHERE C.Question = 'Q1'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, CAST(R.[Purchase date - year] AS NVARCHAR) AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Purchase date - month] = C.MedalliaResponse
			WHERE C.Question = 'Q3a'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Reason for postponing purchase] = C.MedalliaResponse
			WHERE C.Question = 'Q3c'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Reason not buying a new car] = C.MedalliaResponse
			WHERE C.Question = 'Q3d'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Reasons not buying JLR], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q4'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Circumstance change] = C.MedalliaResponse
			WHERE C.Question = 'Q4a'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Overall vehicle reasons for non-purchase], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5a'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The design], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The quality], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The performance and driving experience], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The comfort and practicality], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The options], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Purchase Cost], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Cost of Ownership], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The quoted lead time], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Reviews and recommendations], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q5b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], 'Q5c' AS Question, NULL AS Code, R.[Vehicle non-purchase comments] AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
			WHERE R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Overall Retailer reasons for non-purchase], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q6a'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The retailer showroom], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q6b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The Retailer Staff], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q6b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[The Car and Test Drive Experience], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q6b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				CROSS APPLY STRING_SPLIT(R.[Negotiation with retailer], ',')
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON value = C.MedalliaResponse
			WHERE C.Question = 'Q6b'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], 'Q6c' AS Question, NULL AS Code, R.[Retailer non-purchase comments] AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
			WHERE R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.[Main reason not to buy] = C.MedalliaResponse
			WHERE C.Question = 'Q8'
				AND R.ParentAuditItemID = R.AuditItemID
			UNION
			SELECT R.[Case ID], R.[Event ID], C.Question, C.Code, NULL AS Verbatim
			FROM CaseUpdate.CRMLostLeadResponses R
				INNER JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON R.Anonymous = C.MedalliaResponse
			WHERE C.Question = 'E1'
				AND R.ParentAuditItemID = R.AuditItemID
		)
		INSERT INTO [$(SampleDB)].Event.CRMLostLeadResponses (CaseID, EventID, Question, Code, Response)
		SELECT LL.[Case ID] AS CaseID,
			LL.[Event ID] AS EventID,
			LL.Question,
			LL.Code,
			CASE	WHEN C1.Response IS NOT NULL THEN C1.Response + ' - ' + C.Response
					WHEN LL.Question = 'Q3a' THEN C.Response + ' ' + LL.Verbatim
					WHEN C.Response IS NOT NULL THEN C.Response
					ELSE ISNULL(LL.Verbatim,'') END AS Response
		FROM CTE_LostLeadCodes LL 
			LEFT JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C ON LL.Question = C.Question
														AND LL.Code = C.Code
			LEFT JOIN [$(SampleDB)].Event.CRMLostLeadCodeframes C1 ON C.PreviousCode = C1.Code
														AND C.PreviousQuestion = C1.Question 
		WHERE LL.Code IS NOT NULL 
			OR LL.Verbatim IS NOT NULL
		GROUP BY LL.[Case ID],
			LL.[Event ID],
			LL.Question,
			LL.Code,
			CASE	WHEN C1.Response IS NOT NULL THEN C1.Response + ' - ' + C.Response
					WHEN LL.Question = 'Q3a' THEN C.Response + ' ' + LL.Verbatim
					WHEN C.Response IS NOT NULL THEN C.Response
					ELSE ISNULL(LL.Verbatim,'') END


		-- AUDIT NEW RECORDS
		INSERT INTO [$(AuditDB)].Audit.CRMLostLeadResponses (AuditItemID, CaseID, EventID, Question, Code, Response)
		SELECT CR.AuditItemID,
			R.CaseID,
			R.EventID,
			R.Question,
			R.Code,
			R.Response
		FROM [$(SampleDB)].Event.CRMLostLeadResponses R
			INNER JOIN CaseUpdate.CRMLostLeadResponses CR ON R.CaseID = CR.[Case ID]

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
