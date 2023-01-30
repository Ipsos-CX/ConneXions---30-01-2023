﻿ALTER TABLE [Meta].[VehicleEvents]
    ADD CONSTRAINT [PK_META_VehicleEvents] PRIMARY KEY CLUSTERED ([PartyID] ASC, [VehicleID] ASC, [DealerPartyID] ASC, [EventID] ASC, [EventTypeID] ASC) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF);

