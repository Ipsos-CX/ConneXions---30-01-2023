ALTER TABLE [Requirement].[QuestionnaireAssociations]
    ADD CONSTRAINT [PK_QuestionnaireAssociations] 
    PRIMARY KEY CLUSTERED ([RequirementIDFrom] ASC, [RequirementIDTo] ASC, [FromDate] ASC) 
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

