ALTER TABLE [ContactMechanism].[PostalAddresses]
    ADD CONSTRAINT [FK_PostalAddresses_Countries] FOREIGN KEY ([CountryID]) 
    REFERENCES [ContactMechanism].[Countries] ([CountryID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

