ALTER TABLE [Requirement].[QuestionnairePartyTypeExclusions]
    ADD CONSTRAINT [FK_QuestionnairePartyTypeExclusions_QuestionnairePartyTypeRelationships] FOREIGN KEY ([RequirementID], [PartyTypeID], [FromDate]) 
    REFERENCES [Requirement].[QuestionnairePartyTypeRelationships] ([RequirementID], [PartyTypeID], [FromDate]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

