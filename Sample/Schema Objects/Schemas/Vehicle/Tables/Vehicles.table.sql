CREATE TABLE [Vehicle].[Vehicles] (
    [VehicleID]                         [dbo].[VehicleID]     NOT NULL,
    [ModelID]                           [dbo].[ModelID]       NULL,
    [VIN]                               [dbo].[VIN]           NOT NULL,
    [VehicleIdentificationNumberUsable] BIT                   NOT NULL,
    [VINPrefix]                         [dbo].[VINPrefix]     NULL,
    [ChassisNumber]                     [dbo].[ChassisNumber] NULL,
    [BuildDate]                         DATETIME2 (7)         NULL,
    [BuildYear]                         SMALLINT              NULL,
    [ThroughDate]                       DATETIME2 (7)         NULL,
    [ModelVariantID]                    SMALLINT              NULL,
    [SVOTypeID]							INT					  NULL,
    [FOBCode]							INT					  NULL,
    [OldModelID]                        [dbo].[ModelID]       NULL,
    [OldModelVariantID]                 SMALLINT              NULL, 
    [EngineTypeID]						INT					  NULL 
);



