CREATE NONCLUSTERED INDEX [IX_Vehicles_ModelID] 
	ON [Vehicle].[Vehicles] ([ModelID]) 
	INCLUDE ([VehicleID], [ModelVariantID])
