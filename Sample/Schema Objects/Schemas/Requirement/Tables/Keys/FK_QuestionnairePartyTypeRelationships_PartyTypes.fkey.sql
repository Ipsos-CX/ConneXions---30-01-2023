ALTER TABLE [Requirement].[QuestionnairePartyTypeRelationships]
    ADD CONSTRAINT [FK_QuestionnairePartyTypeRelationships_PartyTypes] FOREIGN KEY ([PartyTypeID]) 
    REFERENCES [Party].[PartyTypes] ([PartyTypeID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

