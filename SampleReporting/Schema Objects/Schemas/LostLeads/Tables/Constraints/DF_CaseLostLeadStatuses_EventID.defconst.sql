ALTER TABLE [LostLeads].[CaseLostLeadStatuses]
   ADD CONSTRAINT [DF_CaseLostLeadStatuses_EventID] 
   DEFAULT 0
   FOR EventID


