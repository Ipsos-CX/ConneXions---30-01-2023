ALTER TABLE [Requirement].[QuestionnaireVariantRequirements]
   ADD CONSTRAINT [DF_QuestionnaireVariantRequirements_FromDate] 
   DEFAULT GETDATE()
   FOR FromDate


