ALTER TABLE [Requirement].[AdhocSelectionModelRequirements]
   ADD CONSTRAINT [DF_AdhocSelectionModelRequirement_FromDate] 
   DEFAULT (GETDATE())
   FOR FromDate


