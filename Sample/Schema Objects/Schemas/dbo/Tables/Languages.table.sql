CREATE TABLE [dbo].[Languages] (
    [LanguageID]   dbo.LanguageID NOT NULL IDENTITY(1,1),
    [Language] VARCHAR(100) NOT NULL,
    [ISOAlpha2]    CHAR (2)       NULL,
    [ISOAlpha3]    CHAR (3)       NULL, 
    [APIOLanguage] VARCHAR(100) NULL						-- TASK 598
);

