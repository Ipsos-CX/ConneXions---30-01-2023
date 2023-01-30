CREATE TABLE [GDPR].[Events] (
	ID INT,
    [Event Type] NVARCHAR(400),
    [Event Date] NVARCHAR(400),
    [VIN] NVARCHAR(400),
    --[Chassis Number] NVARCHAR(400),
    [Model Description] NVARCHAR(400),
    [Registration Number] NVARCHAR(400),
    [Registration Date] NVARCHAR(400),
    [Invoice Number] NVARCHAR(400),
    [Invoice Value] NVARCHAR(400),
    [Dealer Name] NVARCHAR(400),
    [Dealer Code] NVARCHAR(400),
    [Customer Contact?] NVARCHAR(400),
    [Customer Contact Description] NVARCHAR(400),
    [Customer Contact Status] NVARCHAR(400),
    [Customer Contact Creation Date] NVARCHAR(400)
	) ON [PRIMARY]
