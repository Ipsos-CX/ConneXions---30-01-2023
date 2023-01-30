ALTER TABLE [Event].[AutomotiveEventBasedInterviews]
	ADD CONSTRAINT [FK_AutomotiveEventBasedInterviews_Events] 
	FOREIGN KEY (EventID)
	REFERENCES Event.Events (EventID)	

