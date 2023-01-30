ALTER TABLE [Party].[TitleVariations]
    ADD CONSTRAINT [FK_TitleVariations_Titles] 
    FOREIGN KEY ([TitleID]) 
    REFERENCES [Party].[Titles] ([TitleID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

