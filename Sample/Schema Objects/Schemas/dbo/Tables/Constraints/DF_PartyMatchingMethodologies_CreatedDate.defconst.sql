ALTER TABLE [dbo].[PartyMatchingMethodologies]
   ADD CONSTRAINT [DF_PartyMatchingMethodologies_CreatedDate] 
   DEFAULT (getdate())
   FOR  CreatedDate


