CREATE TABLE [Vehicle].[ModelYear] (
    [ManufacturerPartyID] [dbo].[PartyID] NOT NULL,
    [ModelYear]           INT             NOT NULL,
    [ModelID]			  INT			  NULL,
    [VINPosition]         TINYINT         NOT NULL,
    [VINCharacter]        CHAR(1)	      NOT NULL,
	[VIN12thCharacter]    CHAR(1)         NULL
);

