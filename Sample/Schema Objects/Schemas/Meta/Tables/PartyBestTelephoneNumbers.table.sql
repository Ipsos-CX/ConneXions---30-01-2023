CREATE TABLE [Meta].[PartyBestTelephoneNumbers] (
    [PartyID]        [dbo].[PartyID]            NOT NULL,
    [PhoneID]        [dbo].[ContactMechanismID] NULL,
    [LandlineID]     [dbo].[ContactMechanismID] NULL,
    [HomeLandlineID] [dbo].[ContactMechanismID] NULL,
    [WorkLandlineID] [dbo].[ContactMechanismID] NULL,
    [MobileID]       [dbo].[ContactMechanismID] NULL
);

