ALTER TABLE [CustomerUpdate].[ContactOutcome]
   ADD CONSTRAINT [DF_CustomerUpdate_ContactOutcome_DateLoaded] 
   DEFAULT GETDATE()
   FOR DateLoaded


