CREATE NONCLUSTERED INDEX [IX_Events_EventTypeID] 
	ON [Event].[Events] ([EventTypeID]) 
	INCLUDE ([EventID], [EventDate])
