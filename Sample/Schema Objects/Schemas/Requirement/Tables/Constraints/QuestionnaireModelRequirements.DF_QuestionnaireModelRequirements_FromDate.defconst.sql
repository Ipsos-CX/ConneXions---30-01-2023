ALTER TABLE [Requirement].[QuestionnaireModelRequirements]
   ADD CONSTRAINT [DF_QuestionnaireModelRequirements_FromDate] 
   DEFAULT GETDATE()
   FOR FromDate


