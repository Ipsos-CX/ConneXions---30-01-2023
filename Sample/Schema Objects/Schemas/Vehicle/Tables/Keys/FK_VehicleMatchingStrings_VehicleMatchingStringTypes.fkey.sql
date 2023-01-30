ALTER TABLE [Vehicle].[VehicleMatchingStrings]
	ADD CONSTRAINT [FK_VehicleMatchingStrings_VehicleMatchingStringTypes] 
	FOREIGN KEY (VehicleMatchingStringTypeID)
	REFERENCES [Vehicle].[VehicleMatchingStringTypes] (VehicleMatchingStringTypeID)	

