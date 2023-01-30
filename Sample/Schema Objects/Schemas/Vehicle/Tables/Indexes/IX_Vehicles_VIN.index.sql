﻿CREATE NONCLUSTERED INDEX [IX_Vehicles_VIN] ON [Vehicle].[Vehicles] 
(
	[VIN] ASC
)
INCLUDE ( [VehicleID],
[ModelID],
[VehicleIdentificationNumberUsable],
[VINPrefix],
[ChassisNumber],
[BuildDate],
[BuildYear],
[ThroughDate],
[ModelVariantID],
[SVOTypeID],
[FOBCode]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

