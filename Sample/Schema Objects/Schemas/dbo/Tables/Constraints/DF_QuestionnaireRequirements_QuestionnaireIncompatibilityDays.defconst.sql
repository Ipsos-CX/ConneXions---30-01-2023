ALTER TABLE [Requirement].[QuestionnaireRequirements]
    ADD CONSTRAINT [DF_QuestionnaireRequirements_QuestionnaireIncompatibilityDays] DEFAULT ((-183)) FOR [QuestionnaireIncompatibilityDays];

