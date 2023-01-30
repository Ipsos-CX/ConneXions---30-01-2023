ALTER TABLE [Vehicle].[ModelMatching]
	ADD CONSTRAINT [FK_ModelMatching_VehicleMatchingStrings] 
	FOREIGN KEY (VehicleMatchingStringID)
	REFERENCES Vehicle.VehicleMatchingStrings (VehicleMatchingStringID)	

