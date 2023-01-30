CREATE PROCEDURE [OWAPv2].[uspGetInviteMatrix]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT

AS
BEGIN

/*
Description
-----------
Returns all entries in the Invite Matrix 

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			29-11-2016	Eddie Thomas	Created
1.1			30-01-2017	Eddie Thomas	JLRCompanyName Replaces Dealer field
1.2			11-07-2018	Eddie Thomas	Now returns JLRPrivacyPolicy
*/
	--Disable Counts
	SET NOCOUNT ON

	SELECT	ID, Brand, Market, JLRCompanyName, Questionnaire, EmailLanguage, EmailSignator, EmailSignatorTitle, 
			EmailContactText, EmailCompanyDetails, JLRPrivacyPolicy
	FROM	SelectionOutput.OnlineEmailContactDetails
	ORDER BY Market, Brand, Questionnaire, EmailLanguage



	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END