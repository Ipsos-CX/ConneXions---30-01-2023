﻿ALTER TABLE [Event].[NonSolicitations]
    ADD CONSTRAINT [FK_Event_NonSolicitations_Events] FOREIGN KEY ([EventID]) 
    REFERENCES [Event].[Events] ([EventID]) 
    ON DELETE NO ACTION ON UPDATE NO ACTION;

