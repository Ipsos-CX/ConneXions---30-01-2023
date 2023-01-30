ALTER TABLE [NWB].[RequestAlertEmailRecipients]
	ADD CONSTRAINT [FK_RequestAlertEmailRecipients_AlertTypeID]
	FOREIGN KEY (AlertTypeID) 
	REFERENCES NWB.RequestAlertTypes (AlertTypeID)
	ON DELETE NO ACTION ON UPDATE NO ACTION;

