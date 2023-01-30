CREATE PROCEDURE [OWAPv2].[uspGetDealerLevelInviteMatrix]
@RowCount INT=0 OUTPUT, @ErrorCode INT=0 OUTPUT
AS
BEGIN

/*
Description
-----------
Returns all entries in the Invite Matrix 

Version		Date		Author			Why
------------------------------------------------------------------------------------------------------
1.0			28-06-2018	Eddie Thomas	Created
1.1			20-01-2020	Chris Ledger	Bug 15372 - Fix database references


*/
	--Disable Counts
	SET NOCOUNT ON

	SELECT				DISTINCT cdd.InviteMatrixDealerLevelID, cdd.BrandID, cdd.CountryID, cdd.QuestionnaireID, cdd.LanguageID,
								bn.Brand, cn.Country AS Market, qn.Questionnaire, imd.DealerID, imd.DealerCode,
								imd.DealerName,  ln.Language AS EmailLanguage, cdd.EmailSignator, cdd.EmailSignatorTitle, cdd.EmailContactText, 
								cdd.EmailCompanyDetails, cdd.JLRCompanyname, cdd.JLRPrivacyPolicy
	FROM						SelectionOutput.OnlineEmailContactDealerDetails cdd
	INNER JOIN		dbo.Brands												bn		ON	cdd.BrandID = bn.BrandID 
	INNER JOIN		dbo.ContactMechanism.Countries							cn		ON	cdd.CountryID = cn.CountryID 
	INNER JOIN		dbo.Languages											ln		ON	cdd.LanguageID = ln.LanguageID 
														
	INNER JOIN		dbo.Questionnaires										qn		ON	cdd.QuestionnaireID = qn.QuestionnaireID
	INNER JOIN		SelectionOutput.vwInviteMatrixDealers				imd		ON	cdd.DealerPartyID = imd.DealerID

	WHERE			imd.CountryID = cn.CountryID
	
	--Get the Error Code for the statement just executed.
	SELECT 
		@RowCount = @@ROWCOUNT,
		@ErrorCode = @@ERROR

END