﻿ALTER TABLE [Vehicle].[VehiclePartyRoles]
    ADD CONSTRAINT [PK_VehiclePartyRoles] PRIMARY KEY CLUSTERED ([PartyID] ASC, [VehicleRoleTypeID] ASC, [VehicleID] ASC) WITH (FILLFACTOR = 90, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

