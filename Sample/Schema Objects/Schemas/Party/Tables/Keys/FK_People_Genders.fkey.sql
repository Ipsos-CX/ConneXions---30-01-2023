ALTER TABLE [Party].[People]
    ADD CONSTRAINT [FK_People_Genders] FOREIGN KEY ([GenderID]) 
    REFERENCES [Party].[Genders] ([GenderID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

