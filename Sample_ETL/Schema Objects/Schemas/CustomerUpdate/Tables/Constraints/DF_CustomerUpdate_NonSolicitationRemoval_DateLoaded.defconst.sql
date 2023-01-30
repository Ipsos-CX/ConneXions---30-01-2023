ALTER TABLE [CustomerUpdate].[NonSolicitationRemoval]
   ADD CONSTRAINT [DF_CustomerUpdate_NonSolicitationRemoval_DateLoaded] 
   DEFAULT GETDATE()
   FOR DateLoaded


