CREATE TABLE [Stage].[LandRover_Austria_Sales] (
    [ID]                      INT            IDENTITY (1, 1) NOT NULL,
    [AuditID]                 dbo.AuditID         NULL,
    [PhysicalRowID]           INT            NULL,
    [SaleDate]				  dbo.LoadText NULL,
    [SalesDealerCode]		  dbo.LoadText NULL,
    [ModelDescription]		  dbo.LoadText NULL,
    [VIN]					  dbo.LoadText NULL,
    [Title]					  dbo.LoadText NULL,
    [FirstName]			      dbo.LoadText NULL,
    [Surname]			      dbo.LoadText NULL,
    [CompanyName]			  dbo.LoadText NULL,
    [Street]			      dbo.LoadText NULL,
    [PostCode]			      dbo.LoadText NULL,
    [Town]			          dbo.LoadText NULL,
    [SaleType]			      dbo.LoadText NULL,
    [EmailAddress]            dbo.LoadText NULL,
    [ConvertedSalesEventDate] DATETIME2       NULL
);

