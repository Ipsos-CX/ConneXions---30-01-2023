CREATE TABLE [Lookup].[META_VehiclesAndPeople] (
    [VehicleID]       [dbo].[VehicleID] NOT NULL,
    [MatchedPersonID] [dbo].[PartyID]   NOT NULL,
    [VIN]             [dbo].[VIN]       NOT NULL,
    [VehicleChecksum] INT               NULL,
    [NameChecksum]    INT               NULL,
    LastName		 dbo.NameDetail		NULL
    
);