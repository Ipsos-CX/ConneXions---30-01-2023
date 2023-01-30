ALTER TABLE [Vehicle].[VehiclePartyRoleEvents]
	--WITH NOCHECK -- CGR: Switched this off as table not used and slowing down deletes on VehiclePartyRoles
    ADD CONSTRAINT  [FK_VehiclePartyRoleEvents_VehiclePartyRoles]
    FOREIGN KEY ([PartyID], [VehicleRoleTypeID], [VehicleID])
    REFERENCES [Vehicle].[VehiclePartyRoles] ([PartyID], [VehicleRoleTypeID], [VehicleID])
    ON DELETE NO ACTION ON UPDATE NO ACTION;

GO

ALTER TABLE [Vehicle].[VehiclePartyRoleEvents] 
	NOCHECK CONSTRAINT [FK_VehiclePartyRoleEvents_VehiclePartyRoles];



