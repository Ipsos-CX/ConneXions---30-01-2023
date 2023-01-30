CREATE TABLE [ParallelRun].[MismatchOrganisations](
	[ComparisonLoadDate] [datetime] NULL,
	[Filename] [nvarchar](255) NULL,
	[PhysicalFileRow] [float] NULL,
	[GfK MatchedODSOrganisationID] [float] NULL,
	[IPSOS MatchedODSOrganisationID] [float] NULL,
	[Mismatch_OrganisationName] [float] NULL,
	[GfK OrganisationName] [nvarchar](255) NULL,
	[IPSOS OrganisationName] [nvarchar](255) NULL,
	[Mismatch_OrganisationNameChecksum] [float] NULL,
	[GfK OrganisationNameChecksum] [float] NULL,
	[IPSOS OrganisationNameChecksum] [float] NULL
) ON [PRIMARY]