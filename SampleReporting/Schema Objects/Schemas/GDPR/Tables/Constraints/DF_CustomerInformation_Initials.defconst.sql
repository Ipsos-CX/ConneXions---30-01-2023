ALTER TABLE [GDPR].[CustomerInformation]
   ADD CONSTRAINT [DF_CustomerInformation_Initials] 
   DEFAULT ''
   FOR [Initials]