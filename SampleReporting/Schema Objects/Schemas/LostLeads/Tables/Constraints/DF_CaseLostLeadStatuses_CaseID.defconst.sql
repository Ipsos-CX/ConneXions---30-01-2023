ALTER TABLE [LostLeads].[CaseLostLeadStatuses]
   ADD CONSTRAINT [DF_CaseLostLeadStatuses_CaseID] 
   DEFAULT 0
   FOR CaseID


