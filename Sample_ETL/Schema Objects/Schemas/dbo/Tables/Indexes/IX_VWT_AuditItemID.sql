CREATE NONCLUSTERED INDEX [IX_VWT_AuditItemID]
	ON [dbo].[VWT] ([AuditItemID])
	INCLUDE ([MatchedODSVehicleID],[ODSRegistrationID],[VehicleRegistrationNumber],[RegistrationDateOrig],[RegistrationDate],[MatchedODSEventID])