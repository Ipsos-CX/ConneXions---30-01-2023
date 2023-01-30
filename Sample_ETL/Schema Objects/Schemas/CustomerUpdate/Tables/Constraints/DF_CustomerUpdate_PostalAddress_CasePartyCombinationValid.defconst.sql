ALTER TABLE [CustomerUpdate].[PostalAddress]
   ADD CONSTRAINT [DF_CustomerUpdate_PostalAddress_CasePartyCombinationValid] 
   DEFAULT 0
   FOR CasePartyCombinationValid


