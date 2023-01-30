﻿CREATE TABLE [ParallelRun].[MismatchEmailAddresses](
	[ComparisonLoadDate] [datetime] NULL,
	[Filename] [nvarchar](255) NULL,
	[PhysicalFileRow] [float] NULL,
	[GfK MatchedODSEmailAddressID] [float] NULL,
	[IPSOS MatchedODSEmailAddressID] [float] NULL,
	[MatchedODSEmailAddressIDNew] [float] NULL,
	[Mismatch_EmailAddress] [float] NULL,
	[GfK EmailAddress] [nvarchar](255) NULL,
	[IPSOS EmailAddress] [nvarchar](255) NULL,
	[Mismatch_EmailAddressChecksum] [float] NULL,
	[GfK EmailAddressChecksum] [float] NULL,
	[IPSOS EmailAddressChecksum] [nvarchar](255) NULL,
	[GfK MatchedODSPrivEmailAddressID] [nvarchar](255) NULL,
	[IPSOS MatchedODSPrivEmailAddressID] [nvarchar](255) NULL,
	[MatchedODSPrivEmailAddressIDNew] [float] NULL,
	[Mismatch_PrivEmailAddress] [float] NULL,
	[GfK PrivEmailAddress] [nvarchar](255) NULL,
	[IPSOS PrivEmailAddress] [nvarchar](255) NULL,
	[Mismatch_PrivEmailAddressChecksum] [float] NULL,
	[GfK PrivEmailAddressChecksum] [float] NULL,
	[IPSOS PrivEmailAddressChecksum] [nvarchar](255) NULL
) ON [PRIMARY]