
CREATE VIEW [SampleReport].[vwInviteMatrixNew]
AS 

/*
	Purpose:	Return NEW entries in Invite Matrix
	
	Release		Version		Date		Deveoloper				Comment
	LIVE		1.0			19112021	Ben King     			TASK 690
	LIVE		1.1			20221010	Eddie Thomas			TASK 1017 - HOB

*/
	SELECT DISTINCT
		I.Brand,
		I.Market, 
		I.Questionnaire, 
		I.EmailLanguage, 
		I.EmailSignator, 
		I.EmailSignatorTitle, 
		I.EmailContactText, 
		I.EmailCompanyDetails, 
		I.JLRCompanyname, 
		I.JLRPrivacyPolicy,
		I.SubBrand

	FROM [$(ETLDB)].Stage.InviteMatrix I
	LEFT JOIN [$(SampleDB)].SelectionOutput.OnlineEmailContactDetails O ON I.Brand = O.Brand
																AND I.Market = O.Market
															    AND I.Questionnaire = O.Questionnaire
																AND I.EmailLanguage = O.EmailLanguage
																AND I.SubBrand		= O.SubBrand
	WHERE O.Market IS NULL
	
GO