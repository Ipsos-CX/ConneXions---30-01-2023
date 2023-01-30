CREATE NONCLUSTERED INDEX [IX_Vehicles_FOBCode] 
	ON [Vehicle].[Vehicles] ([FOBCode]) 
	INCLUDE ([VehicleID], [VIN])
