ALTER TABLE [Event].[AutomotiveEventBasedInterviews]
	ADD CONSTRAINT [FK_AutomotiveEventBasedInterviews_VehicleRoleTypes] 
	FOREIGN KEY (VehicleRoleTypeID)
	REFERENCES Vehicle.VehicleRoleTypes (VehicleRoleTypeID)	

