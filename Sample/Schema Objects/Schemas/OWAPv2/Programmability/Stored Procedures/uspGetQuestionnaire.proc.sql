CREATE PROCEDURE [OWAPv2].[uspGetQuestionnaire]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
BEGIN
/*
Description
-----------

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			20-09-2016	Eddie Thomas	Created

*/
--Disable Counts
	SET NOCOUNT ON


--Return Languages result set
	SELECT	[QuestionnaireID],
			[Questionnaire]
	FROM	[dbo].[Questionnaires]

	ORDER BY [Questionnaire]

	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END
