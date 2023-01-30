CREATE TABLE [Stage].[LandRover_UK_Service]
(
    [ID]                        INT IDENTITY (1, 1) NOT NULL,
    [AuditID]                   dbo.AuditID,
    [PhysicalRow]				INT NULL,
    [CompanyName]               dbo.LoadText,
    [Title]                     dbo.LoadText,
    [Firstname]                 dbo.LoadText,
    [Surname]                   dbo.LoadText,
    [Address1]                  dbo.LoadText,
    [Address2]                  dbo.LoadText,
    [Address3]                  dbo.LoadText,
    [Address4]                  dbo.LoadText,
    [Address5]                  dbo.LoadText,
    [PostCode]                  dbo.LoadText,
    [Telephone]                 dbo.LoadText,
    [VIN]                       dbo.LoadText,
    [RegistrationNumber]        dbo.LoadText,
    [ServiceDealerCode]         dbo.LoadText,
    [ServiceEventDate]          dbo.LoadText,
    [EmailAddress]              dbo.LoadText,
    [PartyNonSolicitation]      dbo.YNFlag,
    [ConvertedServiceEventDate] DATETIME2 NULL
)
