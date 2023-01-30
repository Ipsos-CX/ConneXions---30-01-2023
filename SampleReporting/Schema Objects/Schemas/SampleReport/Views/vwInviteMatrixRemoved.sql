
CREATE VIEW [SampleReport].[vwInviteMatrixRemoved]
AS 

/*
	Purpose:	Return REMOVED entries in Invite Matrix
	
	Release			Version		Date		Deveoloper				Comment
	LIVE			1.0			19112021	Ben King     			TASK 690
	LIVE			1.1			20221010	Eddie Thomas			TASK 1017 - HOB

*/

	SELECT DISTINCT
		O.Brand,
		O.Market, 
		O.Questionnaire, 
		O.EmailLanguage, 
		O.EmailSignator, 
		O.EmailSignatorTitle, 
		O.EmailContactText, 
		O.EmailCompanyDetails, 
		O.JLRCompanyname, 
		O.JLRPrivacyPolicy,
		O.SubBrand
	FROM [$(SampleDB)].SelectionOutput.OnlineEmailContactDetails O
	LEFT JOIN [$(ETLDB)].Stage.InviteMatrix I ON I.Brand = O.Brand
											  AND I.Market = O.Market
											  AND I.Questionnaire = O.Questionnaire
											  AND I.EmailLanguage = O.EmailLanguage
											  AND I.SubBrand = O.SubBrand
	WHERE I.Market IS NULL

GO
