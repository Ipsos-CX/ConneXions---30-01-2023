ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_OrganisationName] 
   DEFAULT ''
   FOR [Organisation Name]
