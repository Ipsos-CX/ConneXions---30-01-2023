CREATE PROCEDURE Event.uspUpdateCRMLostLeadReasons

AS

/* 
		Purpose:	Insert new records into Event.CRMLostLeadReasons table
	
		Version		Date			Developer			Comment										
LIVE	1.0			2021-12-09		Chris Ledger		Created

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
		TRUNCATE TABLE Event.CRMLostLeadReasons

		DROP TABLE IF EXISTS #Reasons

		
		;WITH CTE_ExistingReasons AS
		(
			SELECT R.CaseID
			FROM Event.CRMLostLeadReasons R
			GROUP BY R.CaseID
		), CTE_Priority1Reasons AS		-- PRIORITY 1 REASONS
		(
			SELECT R.CaseID,
				R.EventID,
				R.Question,
				Q.MedalliaField AS [Question Text],
				ISNULL(CAST(R.Code AS VARCHAR),'') AS Code,
				R.Response,
				ISNULL(C.[SV-CRM Lead Status],'') AS [SV-CRM Lead Status],
				ISNULL(C.[SV-CRM Lead Status Reason 1],'') AS [SV-CRM Lead Status Reason 1],
				ISNULL(C.[SV-CRM Lead Status Reason 2],'') AS [SV-CRM Lead Status Reason 2],
				ISNULL(C.[SV-CRM Lead Status Reason 3],'') AS [SV-CRM Lead Status Reason 3],
				Q.QuestionOrder
			FROM Event.CRMLostLeadResponses R
				INNER JOIN Event.CRMLostLeadQuestions Q ON R.Question = Q.Question 
				LEFT JOIN Event.CRMLostLeadCodeframes C ON R.Question = C.Question
																	AND R.Code = C.Code
			WHERE C.[SV-CRM Lead Status] IS NOT NULL
				AND ISNULL(C.Priority,0) = 1
				AND NOT EXISTS (	SELECT *
									FROM CTE_ExistingReasons RS
									WHERE RS.CaseID = R.CaseID)
		), CTE_Priority2Reasons AS		-- PRIORITY 2 REASONS
		(
			SELECT R.CaseID,
				R.EventID,
				R.Question,
				Q.MedalliaField AS [Question Text],
				ISNULL(CAST(R.Code AS VARCHAR),'') AS Code,
				R.Response,
				ISNULL(C.[SV-CRM Lead Status],'') AS [SV-CRM Lead Status],
				ISNULL(C.[SV-CRM Lead Status Reason 1],'') AS [SV-CRM Lead Status Reason 1],
				ISNULL(C.[SV-CRM Lead Status Reason 2],'') AS [SV-CRM Lead Status Reason 2],
				ISNULL(C.[SV-CRM Lead Status Reason 3],'') AS [SV-CRM Lead Status Reason 3],
				Q.QuestionOrder
			FROM Event.CRMLostLeadResponses R
				INNER JOIN Event.CRMLostLeadQuestions Q ON R.Question = Q.Question 
				LEFT JOIN Event.CRMLostLeadCodeframes C ON R.Question = C.Question
																	AND R.Code = C.Code
			WHERE C.[SV-CRM Lead Status] IS NOT NULL
				AND ISNULL(C.Priority,0) = 2
				AND NOT EXISTS (	SELECT *
									FROM CTE_ExistingReasons RS
									WHERE RS.CaseID = R.CaseID)
				AND NOT EXISTS (	SELECT *
									FROM CTE_Priority1Reasons RS
									WHERE RS.CaseID = R.CaseID)
		), CTE_Priority3Reasons AS			-- PRIORITY 3 REASONS
		(
			SELECT R.CaseID,
				R.EventID,
				R.Question,
				Q.MedalliaField AS [Question Text],
				ISNULL(CAST(R.Code AS VARCHAR),'') AS Code,
				R.Response,
				ISNULL(C.[SV-CRM Lead Status],'') AS [SV-CRM Lead Status],
				ISNULL(C.[SV-CRM Lead Status Reason 1],'') AS [SV-CRM Lead Status Reason 1],
				ISNULL(C.[SV-CRM Lead Status Reason 2],'') AS [SV-CRM Lead Status Reason 2],
				ISNULL(C.[SV-CRM Lead Status Reason 3],'') AS [SV-CRM Lead Status Reason 3],
				Q.QuestionOrder
			FROM Event.CRMLostLeadResponses R
				INNER JOIN Event.CRMLostLeadQuestions Q ON R.Question = Q.Question 
				LEFT JOIN Event.CRMLostLeadCodeframes C ON R.Question = C.Question
																	AND R.Code = C.Code
			WHERE C.[SV-CRM Lead Status] IS NOT NULL
				AND ISNULL(C.Priority,0) = 3
				AND NOT EXISTS (	SELECT *
									FROM CTE_ExistingReasons RS
									WHERE RS.CaseID = R.CaseID)
				AND NOT EXISTS (	SELECT *
									FROM CTE_Priority1Reasons RS
									WHERE RS.CaseID = R.CaseID)
				AND NOT EXISTS (	SELECT *
									FROM CTE_Priority2Reasons RS
									WHERE RS.CaseID = R.CaseID) 
		), CTE_Priority4Reasons AS			-- PRIORITY 4 REASONS
		(
			SELECT R.CaseID,
				R.EventID,
				R.Question,
				Q.MedalliaField AS [Question Text],
				ISNULL(CAST(R.Code AS VARCHAR),'') AS Code,
				R.Response,
				ISNULL(C.[SV-CRM Lead Status],'') AS [SV-CRM Lead Status],
				ISNULL(C.[SV-CRM Lead Status Reason 1],'') AS [SV-CRM Lead Status Reason 1],
				ISNULL(C.[SV-CRM Lead Status Reason 2],'') AS [SV-CRM Lead Status Reason 2],
				ISNULL(C.[SV-CRM Lead Status Reason 3],'') AS [SV-CRM Lead Status Reason 3],
				Q.QuestionOrder
			FROM Event.CRMLostLeadResponses R
				INNER JOIN Event.CRMLostLeadQuestions Q ON R.Question = Q.Question 
				LEFT JOIN Event.CRMLostLeadCodeframes C ON R.Question = C.Question
																	AND R.Code = C.Code
			WHERE C.[SV-CRM Lead Status] IS NOT NULL
				AND ISNULL(C.Priority,0) = 4
				AND NOT EXISTS (	SELECT *
									FROM CTE_ExistingReasons RS
									WHERE RS.CaseID = R.CaseID)
				AND NOT EXISTS (	SELECT *
									FROM CTE_Priority1Reasons RS
									WHERE RS.CaseID = R.CaseID)
				AND NOT EXISTS (	SELECT *
									FROM CTE_Priority2Reasons RS
									WHERE RS.CaseID = R.CaseID) 
				AND NOT EXISTS (	SELECT *
									FROM CTE_Priority3Reasons RS
									WHERE RS.CaseID = R.CaseID) 
		)
		SELECT R1.*
		INTO #Reasons
		FROM CTE_Priority1Reasons R1
		UNION
		SELECT R2.*
		FROM CTE_Priority2Reasons R2
		UNION
		SELECT R3.*
		FROM CTE_Priority3Reasons R3
		UNION
		SELECT R4.*
		FROM CTE_Priority4Reasons R4


		-- ADD REASONS
		;WITH CTE_LeadStatusReasons AS
		(
			SELECT
				R.[CaseID],
				R.[EventID],
				R.[SV-CRM Lead Status],
				R.[SV-CRM Lead Status Reason 1],
				R.[SV-CRM Lead Status Reason 2],
				R.[SV-CRM Lead Status Reason 3],
				ROW_NUMBER() OVER (PARTITION BY R.[CaseID] ORDER BY R.[Order] ASC) AS RowID
			FROM (	SELECT R.[CaseID],
						R.[EventID],
						1 AS [Order],
						R.[SV-CRM Lead Status],
						R.[SV-CRM Lead Status Reason 1],
						R.[SV-CRM Lead Status Reason 2],
						R.[SV-CRM Lead Status Reason 3]
					FROM #Reasons R
					GROUP BY R.[CaseID], 
						R.[EventID],
						R.[SV-CRM Lead Status],
						R.[SV-CRM Lead Status Reason 1],
						R.[SV-CRM Lead Status Reason 2],
						R.[SV-CRM Lead Status Reason 3]
					HAVING COUNT(*) = (SELECT COUNT(*) FROM #Reasons R1 WHERE R1.[CaseID] = R.[CaseID])
					UNION
					SELECT R.[CaseID],
						R.[EventID],
						2 AS [Order],
						R.[SV-CRM Lead Status],
						R.[SV-CRM Lead Status Reason 1],
						R.[SV-CRM Lead Status Reason 2],
						'' AS [SV-CRM Lead Status Reason 3]
					FROM #Reasons R
					GROUP BY R.[CaseID],
						R.[EventID],
						R.[SV-CRM Lead Status],
						R.[SV-CRM Lead Status Reason 1],
						R.[SV-CRM Lead Status Reason 2]
					HAVING COUNT(*) = (SELECT COUNT(*) FROM #Reasons R1 WHERE R1.[CaseID] = R.[CaseID])
					UNION
					SELECT R.[CaseID],
						R.[EventID],
						3 AS [Order],
						R.[SV-CRM Lead Status],
						R.[SV-CRM Lead Status Reason 1],
						'' AS [SV-CRM Lead Status Reason 2],
						'' AS [SV-CRM Lead Status Reason 3]
					FROM #Reasons R
					GROUP BY R.[CaseID],
						R.[EventID],
						R.[SV-CRM Lead Status],
						R.[SV-CRM Lead Status Reason 1]
					HAVING COUNT(*) = (SELECT COUNT(*) FROM #Reasons R1 WHERE R1.[CaseID] = R.[CaseID])
					UNION
					SELECT R.[CaseID],
						R.[EventID],
						4 AS [Order],
						R.[SV-CRM Lead Status],
						'Other' AS [SV-CRM Lead Status Reason 1],
						'' AS [SV-CRM Lead Status Reason 2],
						'' AS [SV-CRM Lead Status Reason 3]
					FROM #Reasons R
					GROUP BY R.[CaseID],
						R.[EventID],
						R.[SV-CRM Lead Status]
					HAVING COUNT(*) = (SELECT COUNT(*) FROM #Reasons R1 WHERE R1.[CaseID] = R.[CaseID])
					) R
		), CTE_Reasons AS
		(
			SELECT R.[CaseID],
				R.[EventID],
				R.[SV-CRM Lead Status]  
								+ CASE WHEN R.[SV-CRM Lead Status Reason 1] = '' THEN '' ELSE ' - ' + R.[SV-CRM Lead Status Reason 1] END 
								+ CASE WHEN R.[SV-CRM Lead Status Reason 2] = '' THEN '' ELSE ' - ' + R.[SV-CRM Lead Status Reason 2] END 
								+ CASE WHEN R.[SV-CRM Lead Status Reason 3] = '' THEN '' ELSE ' - ' + R.[SV-CRM Lead Status Reason 3] END AS [SV-CRM Lead Status Reasons]
			FROM #Reasons R
			GROUP BY R.[CaseID],
				R.[EventID],
				R.[SV-CRM Lead Status]
								+ CASE WHEN R.[SV-CRM Lead Status Reason 1] = '' THEN '' ELSE ' - ' + R.[SV-CRM Lead Status Reason 1] END 
								+ CASE WHEN R.[SV-CRM Lead Status Reason 2] = '' THEN '' ELSE ' - ' + R.[SV-CRM Lead Status Reason 2] END 
								+ CASE WHEN R.[SV-CRM Lead Status Reason 3] = '' THEN '' ELSE ' - ' + R.[SV-CRM Lead Status Reason 3] END
		), CTE_RecontactDate AS
		(
			SELECT R.CaseID, 
				R.Response AS RecontactDate
			FROM Event.CRMLostLeadResponses R
			WHERE R.Question = 'Q3a'
		)
		,CTE_Notes AS
		(
			SELECT R1.[CaseID],
				STUFF((	SELECT ', ' + R2.[SV-CRM Lead Status Reasons]
						FROM CTE_Reasons R2
						WHERE R2.[CaseID] = R1.[CaseID]
						FOR XML PATH('')),1,2,'') AS [Notes]
			FROM CTE_Reasons R1
			GROUP BY R1.[CaseID]
		)
		INSERT INTO Event.CRMLostLeadReasons ([CaseID], [EventID], [SV-CRM Lead Status], [SV-CRM Lead Status Reason 1], [SV-CRM Lead Status Reason 2], [SV-CRM Lead Status Reason 3], [Notes], [RecontactDate])
		SELECT LSR.[CaseID],
			LSR.[EventID],
			LSR.[SV-CRM Lead Status],
			LSR.[SV-CRM Lead Status Reason 1],
			LSR.[SV-CRM Lead Status Reason 2],
			LSR.[SV-CRM Lead Status Reason 3],
			CASE	WHEN LSR.[SV-CRM Lead Status] = 'Resurrected' THEN 'This customer has completed the JLR Customer Voice Lost Leads Survey and stated that they are still in market to purchase a JLR vehicle'
					ELSE '' END AS Notes,
					--ELSE REPLACE(N.Notes,', ',CHAR(10)) END AS Notes,
			RD.RecontactDate
		FROM CTE_LeadStatusReasons LSR
			INNER JOIN CTE_Notes N ON LSR.CaseID = N.CaseID
			LEFT JOIN CTE_RecontactDate RD ON LSR.CaseID = RD.CaseID
		WHERE LSR.RowID = 1


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
