CREATE TABLE [SelectionOutput].OnlineEmailContactDetails (
	ID						INT								IDENTITY (1, 1) NOT NULL,
	Brand					NVARCHAR(510)					NOT NULL,
    Market					VARCHAR(200)	                NOT NULL,
    Questionnaire			VARCHAR(100)					NOT NULL,
    EmailLanguage			VARCHAR(100)					NOT NULL,
    EmailSignator			NVARCHAR(500)					NULL,
    EmailSignatorTitle		NVARCHAR(500)					NULL,
    EmailContactText		NVARCHAR(2000)					NULL,
    EmailCompanyDetails		NVARCHAR(2000)					NULL,
    JLRCompanyname			NVARCHAR(2000)					NULL,
    JLRPrivacyPolicy		NVARCHAR(2000)					NULL, 
    [SubBrand]				VARCHAR(50)						NULL			-- TASK 1017 House of Brands
);





