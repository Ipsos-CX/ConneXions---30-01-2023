ALTER TABLE [Event].[Events]
    ADD CONSTRAINT [FK_Events_EventTypes] FOREIGN KEY ([EventTypeID]) REFERENCES [Event].[EventTypes] ([EventTypeID]) ON DELETE NO ACTION ON UPDATE NO ACTION;

