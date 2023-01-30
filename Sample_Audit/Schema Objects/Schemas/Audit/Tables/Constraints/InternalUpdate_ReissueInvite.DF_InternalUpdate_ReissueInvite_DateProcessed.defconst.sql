ALTER TABLE [Audit].[InternalUpdate_ReissueInvite]
   ADD CONSTRAINT [DF_InternalUpdate_ReissueInvite_DateProcessed] 
   DEFAULT GETDATE()
   FOR DateProcessed


