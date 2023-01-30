ALTER TABLE [Requirement].[QuestionnairePartyTypeRelationships]
    ADD CONSTRAINT [PK_QuestionnairePartyTypeRelationships] PRIMARY KEY CLUSTERED ([RequirementID] ASC, [PartyTypeID] ASC, [FromDate] ASC) 
    WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

