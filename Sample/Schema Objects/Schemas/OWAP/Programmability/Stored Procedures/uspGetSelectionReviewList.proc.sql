CREATE PROC [OWAP].[uspGetSelectionReviewList] 
(
	@RowCount INT = 0 OUTPUT,
	@ErrorCode INT = 0 OUTPUT
)

AS

/*
	Purpose:	Returns a list containing all selections for review on the OWAP
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	; WITH NewSelectionCount AS (
		SELECT
			Q.RequirementID,
			COUNT(SR.RequirementID) AS NewSelectionCount
		FROM Requirement.Requirements Q
		INNER JOIN dbo.BrandMarketQuestionnaireSampleMetadata BMQS ON BMQS.QuestionnaireRequirementID = Q.RequirementID
		INNER JOIN dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BMQID = BMQS.BMQID AND BMQ.IncludeInOWAP = 1
		INNER JOIN Requirement.RequirementRollups QS On Q.RequirementID = QS.RequirementIDPartOf
		INNER JOIN Requirement.SelectionRequirements SR ON QS.RequirementIDMadeUpOf = SR.RequirementID
			AND SR.SelectionStatusTypeID = (
				SELECT SelectionStatusTypeID
				FROM Requirement.SelectionStatusTypes
				WHERE SelectionStatusType = 'Selected'
			)
			AND (
				COALESCE(SR.RecordsSelected, 0) > 0
				OR ( -- IF WE'VE NOT SELECTED ANY RECORDS INCLUDE THE SELECTION AS A NEW ONE IF IT WAS CREATED IN THE LAST 16 DAYS
					ISNULL(DATEDIFF(DAY, SR.SelectionDate, CURRENT_TIMESTAMP), 0) < 16
					AND COALESCE(SR.RecordsSelected, 0) = 0
				)
			)
		GROUP BY Q.RequirementID
	), 
	Users AS (
		SELECT
			 P.PartyID 
			,RT.RoleTypeID
			,P.FirstName + ' ' + P.LastName + ' (' +  RT.RoleType + ')' AS UserName
		FROM Party.People p
		INNER JOIN Party.PartyRoles PR ON P.PartyID = PR.PartyID
		INNER JOIN dbo.RoleTypes RT ON PR.RoleTypeID = RT.RoleTypeID
		INNER JOIN OWAP.RoleTypes ORT ON ORT.RoleTypeID = RT.RoleTypeID
	)
	SELECT DISTINCT
		S.RequirementID AS SelectionID,
		S.Requirement AS SelectionName, 
		Q.RequirementID AS QuestionnaireID, 
		Q.Requirement AS QuestionnaireName, 
		COALESCE(NSC.NewSelectionCount, 0) AS NewSelectionCount,
		P.RequirementID AS ProgrammeID,
		P.Requirement AS ProgrammeName,
		SR.SelectionDate,
		SR.SelectionStatusTypeID,
		SR.LastViewedDate,
		SR.DateOutputAuthorised,
		SR.DateLastRun AS SelectionRunDate,
		ISNULL(SR.RecordsSelected, 0) RecordCount,
		ISNULL(SR.RecordsRejected, 0) RejectedCount,
		LVP.UserName AS LastViewedUserName,
		AP.UserName AS AuthorisedByUserName
	FROM OWAP.Programmes OP
	INNER JOIN Requirement.Requirements P ON P.RequirementID = OP.ProgrammeRequirementID
	INNER JOIN Requirement.RequirementRollups PQ On P.RequirementID = PQ.RequirementIDPartOf
	INNER JOIN Requirement.Requirements Q ON PQ.RequirementIDMadeUpOf = Q.RequirementID
	INNER JOIN dbo.BrandMarketQuestionnaireSampleMetadata BMQS ON BMQS.QuestionnaireRequirementID = Q.RequirementID
	INNER JOIN dbo.BrandMarketQuestionnaireMetadata BMQ ON BMQ.BMQID = BMQS.BMQID AND BMQ.IncludeInOWAP = 1
	LEFT JOIN NewSelectionCount NSC ON Q.RequirementID = NSC.RequirementID
	INNER JOIN Requirement.RequirementRollups QS ON Q.RequirementID = QS.RequirementIDPartOf
	INNER JOIN Requirement.Requirements S ON QS.RequirementIDMadeUpOf = S.RequirementID
	INNER JOIN Requirement.SelectionRequirements SR ON S.RequirementID = SR.RequirementID
		AND SR.DateLastRun IS NOT NULL
		AND SR.DateLastRun > '22 Sep 2009' -- AUTOMATIC OUTPUT GO LIVE DATE
		AND (
			-- WE'VE SELECTED RECORDS AND THE IF IT'S BEEN AUTHORISED IT WAS WITHIN THE LAST 35 DAYS
			(COALESCE(SR.RecordsSelected, 0) > 0
			AND ISNULL(DATEDIFF(DAY, SR.DateOutputAuthorised, CURRENT_TIMESTAMP), 0) < 35)
			OR	(
			COALESCE(SR.RecordsSelected, 0) = 0 
			AND ISNULL(DATEDIFF(DAY, SR.SelectionDate, CURRENT_TIMESTAMP), 0) < 16
			)
		)
	LEFT JOIN Users LVP ON LVP.PartyID = SR.LastViewedPartyID AND LVP.RoleTypeID = SR.LastViewedRoleTypeID				
	LEFT JOIN Users AP ON AP.PartyID = SR.AuthorisingPartyID AND AP.RoleTypeID = SR.AuthorisingRoleTypeID
	ORDER BY 
		P.Requirement, 
		Q.Requirement, 
		SR.DateLastRun DESC
		
	SET @RowCount = @@RowCount

	SET @ErrorCode = ISNULL(Error_Number(), 0)

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