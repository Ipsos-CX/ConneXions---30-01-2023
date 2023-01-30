ALTER TABLE [Event].[AutomotiveEventBasedInterviews]
	ADD CONSTRAINT [FK_AutomotiveEventBasedInterviews_Vehicles] 
	FOREIGN KEY (VehicleID)
	REFERENCES Vehicle.Vehicles (VehicleID)	

