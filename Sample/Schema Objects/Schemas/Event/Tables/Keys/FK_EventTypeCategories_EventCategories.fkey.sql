ALTER TABLE [Event].[EventTypeCategories]
	ADD CONSTRAINT [FK_EventTypeCategories_EventCategories] 
	FOREIGN KEY (EventCategoryID)
	REFERENCES Event.EventCategories (EventCategoryID)	

