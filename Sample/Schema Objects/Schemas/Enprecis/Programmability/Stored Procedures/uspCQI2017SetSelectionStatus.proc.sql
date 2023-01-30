CREATE PROCEDURE [Enprecis].[uspCQI2017SetSelectionStatus]
	@SurveyType VARCHAR(20), 
	@RussiaOutput INTEGER = 0	-- V1.2
AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

/*
	Purpose:	Sets Selection Status for CQI 2017 
		
	Version			Date				Developer			Comment
	1.0				16/01/2017			Chris Ledger		Created
	1.1				21/11/2017			Chris Ledger		BUG 14347: Add MCQI
	1.2				12/09/2019			Chris Ledger		BUG 15571: Add CQIRussia 

*/

	------------------------------------------------------------------------------------
	-- UPDATE SELECTION STATUS 
	------------------------------------------------------------------------------------
	UPDATE SR
	SET SR.SelectionStatusTypeID = (SELECT SelectionStatusTypeID FROM Requirement.SelectionStatusTypes WHERE SelectionStatusType = 'Outputted'), SR.DateOutputAuthorised = GETDATE()
	--SELECT R3.Requirement, SR.*
	FROM Requirement.Requirements R2
	INNER JOIN Requirement.RequirementRollups RR ON R2.RequirementID = RR.RequirementIDPartOf
	INNER JOIN Requirement.Requirements R3 ON RR.RequirementIDMadeUpOf = R3.RequirementID
	INNER JOIN Requirement.SelectionRequirements SR ON R3.RequirementID = SR.RequirementID
	WHERE R2.Requirement LIKE '%2017+'		-- V1.1
	AND (SUBSTRING(R2.Requirement,1,3) = @SurveyType OR SUBSTRING(R2.Requirement,1,4) = @SurveyType)	-- V1.1
	AND ((@RussiaOutput = 1 AND R2.Requirement LIKE '%RUS%') OR (@RussiaOutput = 0 AND R2.Requirement NOT LIKE '%RUS%'))	-- V1.2
	AND R2.RequirementTypeID = 2
	AND SR.SelectionStatusTypeID = 2
	------------------------------------------------------------------------------------


	

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