CREATE NONCLUSTERED INDEX [IX_Meta_VehicleEvents_EventID_VehicleID] 
	ON [Meta].[VehicleEvents]
	([EventID] ASC,	[VehicleID] ASC)

