CREATE TABLE [ParallelRun].[MismatchRegistrations](
	[ComparisonLoadDate] [datetime] NULL,
	[Filename] [nvarchar](255) NULL,
	[PhysicalFileRow] [nvarchar](255) NULL,
	[Mismatch_RegistrationID] [nvarchar](255) NULL,
	[GfK RegistrationID] [nvarchar](255) NULL,
	[IPSOS RegistrationID] [nvarchar](255) NULL,
	[Mismatch_RegistrationNumber] [nvarchar](255) NULL,
	[GfK RegistrationNumber] [nvarchar](255) NULL,
	[IPSOS RegistrationNumber] [nvarchar](255) NULL,
	[Mismatch_RegistrationDate] [nvarchar](255) NULL,
	[GfK RegistrationDate] [nvarchar](255) NULL,
	[IPSOS RegistrationDate] [nvarchar](255) NULL,
	[Mismatch_Reg_ThroughDate] [nvarchar](255) NULL,
	[GfK ThroughDate] [nvarchar](255) NULL,
	[IPSOS ThroughDate] [nvarchar](255) NULL
) ON [PRIMARY]