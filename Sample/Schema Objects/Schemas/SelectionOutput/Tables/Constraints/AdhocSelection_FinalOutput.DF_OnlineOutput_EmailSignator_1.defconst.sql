ALTER TABLE [SelectionOutput].[AdhocSelection_FinalOutput]
   ADD CONSTRAINT [DF_AdhocSelection_FinalOutput_EmailSignator] 
   DEFAULT ('') 
   FOR [EmailSignator]


