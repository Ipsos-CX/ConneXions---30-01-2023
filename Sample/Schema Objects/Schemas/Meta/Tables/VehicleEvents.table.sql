CREATE TABLE [Meta].[VehicleEvents] (
    [EventID]             [dbo].[EventID]            NOT NULL,
    [VehicleID]           [dbo].[VehicleID]          NOT NULL,
    [ModelID]             [dbo].[ModelID]            NULL,
    [PartyID]             [dbo].[PartyID]            NOT NULL,
    [VehicleRoleTypeID]   [dbo].[VehicleRoleTypeID]  NULL,
    [VIN]                 [dbo].[VIN]                NULL,
    [RegistrationNumber]  [dbo].[RegistrationNumber] NULL,
    [RegistrationDate]    DATETIME2 (7)              NULL,
    [EventDate]           DATETIME2 (7)              NULL,
    [EventType]           NVARCHAR (200)             NULL,
    [EventTypeID]         [dbo].[EventTypeID]        NOT NULL,
    [EventCategory]       VARCHAR (50)               NULL,
    [EventCategoryID]     [dbo].[EventCategoryID]    NULL,
    [OwnershipCycle]      [dbo].[OwnershipCycle]     NULL,
    [DealerPartyID]       [dbo].[PartyID]            NOT NULL,
    [DealerCode]          [dbo].[DealerCode]         NULL,
    [ManufacturerPartyID] [dbo].[PartyID]            NULL
);

