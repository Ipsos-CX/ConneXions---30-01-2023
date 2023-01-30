ALTER TABLE [CustomerUpdate].[EmailAddress]
   ADD CONSTRAINT [DF_CustomerUpdate_EmailAddress_EmailIsCurrentForParty] 
   DEFAULT 0
   FOR EmailIsCurrentForParty


