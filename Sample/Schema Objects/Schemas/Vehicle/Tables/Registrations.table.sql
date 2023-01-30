CREATE TABLE [Vehicle].[Registrations] (
    [RegistrationID]         INT           IDENTITY (1, 1) NOT NULL, -- TODO: this should be data type dbo.RegistrationID but uspRegistrationNumber_Insert fails when it is - look into why!
    [RegistrationNumber]              dbo.RegistrationNumber NOT NULL,
    [RegistrationDate]       DATETIME2       NULL,
    [ThroughDate]            DATETIME2       NULL
);

