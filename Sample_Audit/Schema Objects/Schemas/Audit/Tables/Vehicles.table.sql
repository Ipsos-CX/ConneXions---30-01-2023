CREATE TABLE [Audit].[Vehicles] (
    [AuditItemID]             [dbo].[AuditItemID]        NOT NULL,
    [VehicleID]               [dbo].[VehicleID]          NOT NULL,
    [ModelID]                 [dbo].[ModelID]            NULL,
    [VIN]                     [dbo].[VIN]                NULL,
    [VehicleIdentificationNumberUsable]	[BIT]			 NULL,
    [ModelDescription]        [dbo].[VehicleDescription] NULL,
    [BodyStyleDescription]    [dbo].[VehicleDescription] NULL,
    [EngineDescription]       [dbo].[VehicleDescription] NULL,
    [TransmissionDescription] [dbo].[VehicleDescription] NULL,
    [BuildDateOrig]           VARCHAR (20)               NULL,
    [BuildDate]               DATETIME2 (7)              NULL,
    [BuildYear]               SMALLINT                   NULL,
    [ThroughDate]             DATETIME2 (7)              NULL,
    [SVOTypeID]				  INT						 NULL,
    [ModelVariantID]          SMALLINT                   NULL,	
	[OldModelID]              [dbo].[ModelID]			 NULL,
    [OldModelVariantID]       SMALLINT                   NULL 
);



