CREATE NONCLUSTERED INDEX [IX_Vehicles_BuildYear] 
	ON [Vehicle].[Vehicles] ([BuildYear]) 
	INCLUDE ([VehicleID], [ModelID], [VIN])
