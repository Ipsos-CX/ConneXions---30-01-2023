
CREATE VIEW [SampleReport].[vwInviteMatrixChange]
AS 

/*
	Purpose:	Return CHANGED entries in Invite Matrix
	
	Release			Version		Date		Deveoloper				Comment
	LIVE			1.0			19112021	Ben King     			TASK 690
	LIVE			1.1			20221010	Eddie Thomas			TASK 1017 - HOB

*/
	SELECT DISTINCT
		I.Brand,
		I.Market, 
		I.Questionnaire, 
		I.EmailLanguage, 

		I.EmailSignator AS EmailSignator_NEW, 
		O.EmailSignator AS EmailSignator_ORIGINAL, 
		I.EmailSignatorTitle AS EmailSignatorTitle_NEW, 
		O.EmailSignatorTitle AS EmailSignatorTitle_ORIGINAL,
		I.EmailContactText AS EmailContactText_NEW, 
		O.EmailContactText AS EmailContactText_ORIGINAL, 
		I.EmailCompanyDetails AS EmailCompanyDetails_NEW, 
		O.EmailCompanyDetails AS EmailCompanyDetails_ORIGINAL, 
		I.JLRCompanyname AS JLRCompanyname_NEW, 
		O.JLRCompanyname AS JLRCompanyname_ORIGINAL, 
		I.JLRPrivacyPolicy AS JLRPrivacyPolicy_NEW,
		O.JLRPrivacyPolicy AS JLRPrivacyPolicy_ORIGINAL,
		I.SubBrand AS SubBrand_NEW,
		O.SubBrand AS SubBrand_ORIGINAL
	FROM [$(ETLDB)].Stage.InviteMatrix I
	LEFT JOIN [$(SampleDB)].SelectionOutput.OnlineEmailContactDetails O ON I.Brand = O.Brand
																AND I.Market = O.Market
															    AND I.Questionnaire = O.Questionnaire
																AND I.EmailLanguage = O.EmailLanguage
																AND I.SubBrand = O.SubBrand
	WHERE CONCAT(I.EmailSignator, I.EmailSignatorTitle , I.EmailContactText, I.EmailCompanyDetails, I.JLRCompanyname, I.JLRPrivacyPolicy)
		  <>
		  CONCAT(O.EmailSignator, O.EmailSignatorTitle , O.EmailContactText, O.EmailCompanyDetails, O.JLRCompanyname, O.JLRPrivacyPolicy)
	
GO