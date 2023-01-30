ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_PersonOrganisation] 
   DEFAULT ''
   FOR [Person/Organisation]
