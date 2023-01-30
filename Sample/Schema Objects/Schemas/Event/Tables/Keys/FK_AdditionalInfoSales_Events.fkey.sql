ALTER TABLE [Event].[AdditionalInfoSales]
    ADD CONSTRAINT [FK_AdditionalInfoSales_Events] FOREIGN KEY ([EventID]) 
    REFERENCES [Event].[Events] ([EventID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

