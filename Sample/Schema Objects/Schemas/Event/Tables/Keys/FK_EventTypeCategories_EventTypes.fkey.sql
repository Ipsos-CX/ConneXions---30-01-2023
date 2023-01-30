ALTER TABLE [Event].[EventTypeCategories]
	ADD CONSTRAINT [FK_EventTypeCategories_EventTypes] 
	FOREIGN KEY (EventTypeID)
	REFERENCES Event.EventTypes (EventTypeID)	

