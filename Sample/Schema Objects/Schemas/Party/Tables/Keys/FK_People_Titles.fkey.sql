ALTER TABLE [Party].[People]
    ADD CONSTRAINT [FK_People_Titles] FOREIGN KEY ([TitleID]) 
    REFERENCES [Party].[Titles] ([TitleID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

